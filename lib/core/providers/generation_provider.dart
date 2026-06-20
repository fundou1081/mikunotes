import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/background/foreground_service_manager.dart';
// import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/storage/database.dart' show Comment, DanmakuData;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:mikunotes/core/models/chat_message.dart' as chat_model;

class GenerationState {
  final bool isRunning;
  final String content;
  final String? error;
  final bool isCompleted;
  final String? summaryId;
  final GenerationSource? source; // 当前生成的内容来源

  const GenerationState({
    this.isRunning = false, this.content = '', this.error,
    this.isCompleted = false, this.summaryId,
    this.source,
  });
}

/// 生成来源 — 控制 prompt 构建和 Summary 保存逻辑
enum GenerationSource {
  /// 视频字幕生成总结
  summary,

  /// 评论 AI 分析
  comment,

  /// 弹幕 AI 分析
  danmaku,

  /// 对话生成 (多轮, 保存到 ChatMessage)
  chat,
}

/// 通用生成请求 — 所有 source 复用同一个流式通道
class GenerationRequest {
  final String bvid;
  final int page;
  final GenerationSource source;

  // ─── source-specific data (which one is set depends on source) ───
  final VideoSubtitle? subtitle;    // summary
  final List<Comment>? comments;     // comment
  final List<DanmakuData>? danmaku;  // danmaku

  // ─── chat-specific ───
  /// 会话 ID (chat 保存到 ChatMessage 用)
  final String? chatSessionId;

  /// 预渲染的 system prompt (chat 自己渲染, 因为包含变量上下文)
  final String? chatSystemPrompt;

  /// 对话历史 (多轮消息)
  final List<Map<String, String>>? chatHistory;

  /// ─── template selection ───
  final String? customPrompt;  // 完全自定义的 prompt
  final String? templateId;     // 选中的模板 ID

  // ─── optional ───
  final String? continueFrom;   // 从已有内容继续 (continueSummary 用)
  final String? videoTitle;     // 视频标题 (可选, 默认用 'BV $bvid')

  const GenerationRequest({
    required this.bvid,
    required this.source,
    this.page = 0,
    this.subtitle,
    this.comments,
    this.danmaku,
    this.chatSessionId,
    this.chatSystemPrompt,
    this.chatHistory,
    this.customPrompt,
    this.templateId,
    this.continueFrom,
    this.videoTitle,
  });
}

class GenerationNotifier extends StateNotifier<Map<String, GenerationState>> {
  final Ref _ref;
  final Map<String, bool> _cancelFlags = {};
  final Map<String, StreamSubscription<String>?> _cancelSubs = {};
  final Map<String, Completer<void>> _completers = {};
  final Map<String, CancelToken> _cancelTokens = {}; // 取消 dio HTTP 请求

  GenerationNotifier(this._ref) : super({});

  GenerationState? getState(String bvid) => state[bvid];

  void cancel(String bvid) {
    _cancelFlags[bvid] = true;
    // 取消 dio HTTP 请求 (关键: 才能真正中断 HTTP socket)
    _cancelTokens.remove(bvid)?.cancel('user_cancelled');
    // 取消订阅 + 立即 complete completer
    _cancelSubs[bvid]?.cancel();
    final c = _completers.remove(bvid);
    c?.complete();
    // ⭐ 立即更新 UI 状态: isRunning=false (保留 buffer 中的部分内容)
    final prev = state[bvid];
    if (prev != null && prev.isRunning) {
      state = {...state, bvid: GenerationState(
        isRunning: false,
        content: prev.content,
        error: '已停止',
      )};
    }
  }

  /// 同步取消流 + 完成 completer
  void _forceCancel(String bvid, Completer<void> completer) {
    _cancelFlags[bvid] = true;
    _cancelSubs[bvid]?.cancel();
    if (!completer.isCompleted) completer.complete();
  }

  /// 清理某个 bvid 的状态
  void clear(String bvid) => state = {...state}..remove(bvid);

  // 通用流式生成 — summary / comment / danmaku 复用同一套流式通道
  // ─────────────────────────────────────────────────────────────────

  /// source → 模板类型
  TemplateType _sourceToTemplateType(GenerationSource source) {
    return switch (source) {
      GenerationSource.summary => TemplateType.summary,
      GenerationSource.comment => TemplateType.comment,
      GenerationSource.danmaku => TemplateType.danmaku,
      GenerationSource.chat => TemplateType.chat,
    };
  }

  /// source → 默认模板内容 (从 templatesProvider 取活跃模板)
  String _resolveTemplate(GenerationSource source, String? templateId, AIConfig config) {
    final tplType = _sourceToTemplateType(source);
    if (templateId != null) {
      final selected = _ref.read(templatesProvider.notifier).getById(tplType, templateId);
      if (selected != null) return selected.content;
    }
    // fallback: 用活跃模板
    final tplSet = _ref.read(templatesProvider);
    return switch (source) {
      GenerationSource.summary => tplSet.activeSummary?.content ?? config.summaryTemplate,
      GenerationSource.comment => tplSet.activeComment?.content ?? '',
      GenerationSource.danmaku => tplSet.activeDanmaku?.content ?? '',
      GenerationSource.chat => tplSet.activeChat?.content ?? config.chatTemplate,
    };
  }

  /// source → 模板变量 (title, text, total 等)
  Map<String, String> _buildTemplateVars(GenerationRequest req, AIConfig config) {
    final title = req.videoTitle ?? 'BV ${req.bvid}';
    return switch (req.source) {
      GenerationSource.chat => <String, String>{}, // chat 不使用模板变量 (使用预渲染 systemPrompt)
      GenerationSource.summary => () {
        final subtitle = req.subtitle!;
        final transcript = subtitle.fullText;
        final truncated = transcript.length > config.maxContextChars
            ? transcript.substring(0, config.maxContextChars) : transcript;
        return {
          'video_title': title,
          'bvid': req.bvid,
          'subtitle': transcript,
          'subtitle_truncated': truncated,
          'language': subtitle.language,
          'uploader': '', 'duration': '', 'page_count': '',
        };
      }(),
      GenerationSource.comment => () {
        final comments = req.comments!;
        final text = comments.map((c) => '【${c.likes}赞】${c.uname}: ${c.content}').join('\n');
        final truncated = text.length > 8000 ? '${text.substring(0, 8000)}...(已截断)' : text;
        return {
          'video_title': title,
          'total': '${comments.length}',
          'taken': '${comments.length}',
          'text': truncated,
        };
      }(),
      GenerationSource.danmaku => () {
        final dmks = req.danmaku!;
        // 按时间排序
        dmks.sort((a, b) => a.progress.compareTo(b.progress));
        final text = dmks.map((d) => '[${_fmtTimeMs(d.progress)}] ${d.content}').join('\n');
        final truncated = text.length > 6000 ? '${text.substring(0, 6000)}...' : text;
        return {
          'video_title': title,
          'total': '${dmks.length}',
          'taken': '${dmks.length}',
          'text': truncated,
        };
      }(),
    };
  }

  /// 格式化时间 (用于弹幕模板)
  String _fmtTimeMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// 通用流式生成入口 — 所有 source 走这里
  Future<void> startGeneration(GenerationRequest req) async {
    _cancelFlags[req.bvid] = false;

    // 检查数据完整性
    switch (req.source) {
      case GenerationSource.summary:
        if (req.subtitle == null) {
          state = {...state, req.bvid: const GenerationState(error: '缺少字幕')};
          return;
        }
      case GenerationSource.comment:
        if (req.comments == null || req.comments!.isEmpty) {
          state = {...state, req.bvid: const GenerationState(error: '暂无评论')};
          return;
        }
      case GenerationSource.danmaku:
        if (req.danmaku == null || req.danmaku!.isEmpty) {
          state = {...state, req.bvid: const GenerationState(error: '暂无弹幕')};
          return;
        }
      case GenerationSource.chat:
        if (req.chatSessionId == null || req.chatSystemPrompt == null || req.chatHistory == null) {
          state = {...state, req.bvid: const GenerationState(error: '对话参数不完整')};
          return;
        }
    }

    final pageLabel = req.page == 0 ? '整体' : 'P${req.page}';
    final sourceLabel = switch (req.source) {
      GenerationSource.summary => '总结',
      GenerationSource.comment => '评论分析',
      GenerationSource.danmaku => '弹幕分析',
      GenerationSource.chat => '回复',
    };

    state = {...state, req.bvid: GenerationState(
      isRunning: true,
      source: req.source,
      content: req.continueFrom ?? '',
    )};

    try {
      await ForegroundServiceManager.start(
        title: '正在生成 $pageLabel $sourceLabel...',
        text: 'BV ${req.bvid}',
      );

      final config = _ref.read(aiConfigProvider);
      if (config.apiKey.isEmpty) {
        throw '请先在设置配置 API Key';
      }
      final client = _ref.read(llmClientProvider);
      final disableReasoning = config.provider == LLMProvider.minimax;

      // ⭐ 渲染 system prompt + messages (chat 跳过模板渲染, 用预渲染值)
      final String systemPrompt;
      final List<Map<String, String>> messages;
      if (req.source == GenerationSource.chat) {
        systemPrompt = req.chatSystemPrompt!;
        messages = req.chatHistory!;
      } else {
        // 解析模板
        String tpl;
        if ((req.customPrompt ?? '').isNotEmpty) {
          tpl = req.customPrompt!;
        } else {
          tpl = _resolveTemplate(req.source, req.templateId, config);
          // 源特定 fallback
          if (tpl.isEmpty) {
            tpl = switch (req.source) {
              GenerationSource.summary => config.summaryTemplate,
              GenerationSource.comment => llm_tpl.communityCommentTemplate,
              GenerationSource.danmaku => llm_tpl.danmakuHighFreqTemplate,
              GenerationSource.chat => '', // chat 不使用默认模板
            };
          }
        }

        // 渲染 prompt
        final vars = _buildTemplateVars(req, config);
        systemPrompt = llm_tpl.PromptTemplate.render(tpl, vars);

        // user message (continue vs normal)
        String userMessage;
        if (req.continueFrom != null && req.continueFrom!.isNotEmpty) {
          userMessage = '''你刚才的输出被中断了。下面是已有的内容：

${req.continueFrom}

[继续]

请从上一个被截断的句子中间继续接着写，**不要重复**已写过的部分，也不要添加 "好的" "下面继续" 等客套话。直接接着最后一个字写下去，直到结束。''';
        } else {
          userMessage = switch (req.source) {
            GenerationSource.summary => '请开始总结',
            _ => systemPrompt.contains('{{text}}')
                ? '请按模板要求输出分析'
                : '请开始分析',
          };
        }
        messages = [{'role': 'user', 'content': userMessage}];
      }

      // ⭐ 流式调用 (核心逻辑)
      final buffer = StringBuffer(req.continueFrom ?? '');
      int charCount = buffer.length;
      final completer = Completer<void>();
      _completers[req.bvid] = completer;
      final cancelToken = CancelToken();
      _cancelTokens[req.bvid] = cancelToken;
      Timer? watchdog;
      StreamSubscription<String>? sub;

      sub = client.chatStreamWithFallback(
        systemPrompt: systemPrompt, // 使用已渲染的 (含 {{text}} 评论/弹幕内容), chat 也复用
        messages: messages,
        disableReasoning: disableReasoning,
        cancelToken: cancelToken,
      ).listen(
        (chunk) {
          watchdog?.cancel();
          watchdog = Timer(const Duration(seconds: 30), () {
            if (_cancelFlags[req.bvid] == true) {
              sub?.cancel();
              final c = _completers.remove(req.bvid);
              c?.complete();
            }
          });

          if (_cancelFlags[req.bvid] == true) {
            _cancelFlags[req.bvid] = false;
            sub?.cancel();
            watchdog?.cancel();
            final c = _completers.remove(req.bvid);
            c?.complete();
            state = {...state, req.bvid: GenerationState(
              isRunning: false, content: buffer.toString(), source: req.source,
            )};
            return;
          }
          buffer.write(chunk);
          charCount += chunk.length;
          state = {...state, req.bvid: GenerationState(
            isRunning: true, content: buffer.toString(), source: req.source,
          )};

          if (charCount % 500 < chunk.length) {
            ForegroundServiceManager.updateNotification(
              title: '正在生成 $pageLabel $sourceLabel...',
              text: 'BV ${req.bvid} · ${buffer.length} 字',
            );
          }
        },
        onDone: () {
          _cancelSubs.remove(req.bvid);
          _completers.remove(req.bvid);
          watchdog?.cancel();
          if (!completer.isCompleted) completer.complete();
        },
        onError: (e) {
          _cancelSubs.remove(req.bvid);
          _completers.remove(req.bvid);
          watchdog?.cancel();
          if (!completer.isCompleted) completer.completeError(e);
        },
        cancelOnError: true,
      );
      _cancelSubs[req.bvid] = sub;

      try {
        await completer.future;
      } finally {
        _completers.remove(req.bvid);
        _cancelSubs.remove(req.bvid);
        _cancelTokens.remove(req.bvid);
        watchdog?.cancel();
      }

      if (_cancelFlags[req.bvid] == true) {
        await ForegroundServiceManager.stop();
        return;
      }

      // ⭐ 保存结果 — 区分 source
      final repo = _ref.read(videoRepositoryProvider);

      if (req.source == GenerationSource.chat) {
        // chat: 保存到 ChatMessage 表
        await repo.addChatMessage(
          sessionId: req.chatSessionId!,
          role: chat_model.ChatRole.assistant,
          content: buffer.toString(),
        );
        state = {...state, req.bvid: GenerationState(
          isCompleted: true, content: buffer.toString(), source: req.source,
        )};
        Future.delayed(const Duration(seconds: 2), () {
          final s = state[req.bvid];
          if (s != null && s.isCompleted && s.source == GenerationSource.chat) {
            state = {...state}..remove(req.bvid);
          }
        });
      } else {
        // summary/comment/danmaku: 保存到 Summary 表
        // promptUsed 格式: 'comment' 或 'comment_<templateName>' (带模板名)
        String promptUsed;
        if (req.templateId != null && req.templateId!.isNotEmpty) {
          final tplName = _ref.read(templatesProvider.notifier)
              .getById(_sourceToTemplateType(req.source), req.templateId!)?.name ?? '';
          promptUsed = switch (req.source) {
            GenerationSource.summary => systemPrompt,
            GenerationSource.comment => tplName.isNotEmpty ? 'comment_$tplName' : 'comment',
            GenerationSource.danmaku => tplName.isNotEmpty ? 'danmaku_$tplName' : 'danmaku',
            GenerationSource.chat => '', // never reached
          };
        } else {
          promptUsed = switch (req.source) {
            GenerationSource.summary => systemPrompt,
            GenerationSource.comment => 'comment',
            GenerationSource.danmaku => 'danmaku',
            GenerationSource.chat => '', // never reached
          };
        }
        final summary = await repo.createSummary(
          bvid: req.bvid,
          content: buffer.toString(),
          type: summary_model.SummaryType.structured,
          modelUsed: config.effectiveModel,
          promptUsed: promptUsed,
          page: req.page,
        );

        if (req.source == GenerationSource.summary) {
          repo.extractAndSaveAiTags(bvid: req.bvid, title: 'BV ${req.bvid}', content: buffer.toString());
        }

        state = {...state, req.bvid: GenerationState(
          isCompleted: true, content: buffer.toString(),
          summaryId: summary.id, source: req.source,
        )};
        Future.delayed(const Duration(seconds: 2), () {
          if (state[req.bvid]?.summaryId == summary.id) {
            state = {...state}..remove(req.bvid);
          }
        });
      }
    } catch (e) {
      final partial = state[req.bvid]?.content ?? req.continueFrom ?? '';
      if (partial.trim().isNotEmpty) {
        try {
          final config = _ref.read(aiConfigProvider);
          if (req.source == GenerationSource.chat) {
            // chat: 保存部分为 ChatMessage (让用户能看到生成了一半的内容)
            await _ref.read(videoRepositoryProvider).addChatMessage(
              sessionId: req.chatSessionId!,
              role: chat_model.ChatRole.assistant,
              content: '⚠️ 生成中断/出错，已保存部分内容\n\n$partial',
            );
          } else {
            await _ref.read(videoRepositoryProvider).createSummary(
              bvid: req.bvid,
              content: '⚠️ 生成中断/出错，已保存部分内容\n\n$partial',
              type: summary_model.SummaryType.structured,
              modelUsed: config.effectiveModel,
              promptUsed: 'partial',
              page: req.page,
            );
          }
          state = {...state, req.bvid: GenerationState(
            isRunning: false, error: '$e (部分内容已保存)',
            content: partial, source: req.source,
          )};
          return;
        } catch (_) {}
      }
      state = {...state, req.bvid: GenerationState(
        isRunning: false, error: '$e', content: partial, source: req.source,
      )};
    } finally {
      await ForegroundServiceManager.stop();
    }
  }

  // ─── 适配层 (向后兼容, 内部委托给 startGeneration) ────────────

  /// 摘要生成 (保持原 API 兼容)
  Future<void> startSummaryGeneration({
    required String bvid,
    required VideoSubtitle subtitle,
    String? customPrompt,
    String? templateId,
    int page = 0,
    String? videoTitle,
  }) =>
      startGeneration(GenerationRequest(
        bvid: bvid,
        source: GenerationSource.summary,
        page: page,
        subtitle: subtitle,
        customPrompt: customPrompt,
        templateId: templateId,
        videoTitle: videoTitle,
      ));

  /// 评论生成 (新)
  Future<void> startCommentGeneration({
    required String bvid,
    required List<Comment> comments,
    String? customPrompt,
    String? templateId,
    int page = 0,
    String? videoTitle,
  }) =>
      startGeneration(GenerationRequest(
        bvid: bvid,
        source: GenerationSource.comment,
        page: page,
        comments: comments,
        customPrompt: customPrompt,
        templateId: templateId,
        videoTitle: videoTitle,
      ));

  /// 弹幕生成 (新)
  Future<void> startDanmakuGeneration({
    required String bvid,
    required List<DanmakuData> danmaku,
    String? customPrompt,
    String? templateId,
    int page = 0,
    String? videoTitle,
  }) =>
      startGeneration(GenerationRequest(
        bvid: bvid,
        source: GenerationSource.danmaku,
        page: page,
        danmaku: danmaku,
        customPrompt: customPrompt,
        templateId: templateId,
        videoTitle: videoTitle,
      ));

  /// 对话生成 (新) — 多轮 chat, 使用预渲染 systemPrompt + chatHistory
  Future<void> startChatGeneration({
    required String bvid,
    required String sessionId,
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) =>
      startGeneration(GenerationRequest(
        bvid: bvid,
        source: GenerationSource.chat,
        chatSessionId: sessionId,
        chatSystemPrompt: systemPrompt,
        chatHistory: history,
      ));

  /// 继续生成 (从已有内容继续)
  Future<void> continueSummary({
    required String bvid,
    required VideoSubtitle subtitle,
    required String existingContent,
    String? templateId,
    int page = 0,
    String? videoTitle,
  }) =>
      startGeneration(GenerationRequest(
        bvid: bvid,
        source: GenerationSource.summary,
        page: page,
        subtitle: subtitle,
        templateId: templateId,
        continueFrom: existingContent,
        videoTitle: videoTitle,
      ));

  /// 继续生成评论总结 (从已有评论总结继续)
  Future<void> continueCommentGeneration({
    required String bvid,
    required List<Comment> comments,
    required String existingContent,
    String? templateId,
    int page = 0,
    String? videoTitle,
  }) =>
      startGeneration(GenerationRequest(
        bvid: bvid,
        source: GenerationSource.comment,
        page: page,
        comments: comments,
        templateId: templateId,
        continueFrom: existingContent,
        videoTitle: videoTitle,
      ));

  /// 继续生成弹幕总结 (从已有弹幕总结继续)
  Future<void> continueDanmakuGeneration({
    required String bvid,
    required List<DanmakuData> danmaku,
    required String existingContent,
    String? templateId,
    int page = 0,
    String? videoTitle,
  }) =>
      startGeneration(GenerationRequest(
        bvid: bvid,
        source: GenerationSource.danmaku,
        page: page,
        danmaku: danmaku,
        templateId: templateId,
        continueFrom: existingContent,
        videoTitle: videoTitle,
      ));
}

final generationProvider = StateNotifierProvider<GenerationNotifier, Map<String, GenerationState>>(
  (ref) => GenerationNotifier(ref),
);
