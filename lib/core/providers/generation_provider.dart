import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/background/foreground_service_manager.dart';
// import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;

class GenerationState {
  final bool isRunning;
  final String content;
  final String? error;
  final bool isCompleted;
  final String? summaryId;

  const GenerationState({
    this.isRunning = false, this.content = '', this.error,
    this.isCompleted = false, this.summaryId,
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

  Future<void> startSummaryGeneration({
    required String bvid,
    required VideoSubtitle subtitle,
    String? customPrompt,
    String? templateId,
    int page = 0,
  }) async {
    _cancelFlags[bvid] = false;
    final pageLabel = page == 0 ? '整体' : 'P$page';
    state = {...state, bvid: const GenerationState(isRunning: true)};

    try {
      // 启动前台服务 (切后台保活)
      await ForegroundServiceManager.start(
        title: '正在生成 $pageLabel 总结...',
        text: 'BV $bvid',
      );

      final config = _ref.read(aiConfigProvider);
      final client = _ref.read(llmClientProvider);
      final disableReasoning = config.provider == LLMProvider.minimax;
      final transcript = subtitle.fullText;
      final truncated = transcript.length > config.maxContextChars
          ? transcript.substring(0, config.maxContextChars) : transcript;

      String tpl;
      if ((customPrompt ?? '').isNotEmpty) {
        tpl = customPrompt!;
      } else if (templateId != null) {
        // 用选中的模板
        final selected = _ref.read(templatesProvider.notifier)
            .getById(TemplateType.summary, templateId);
        tpl = selected?.content ?? '';
        if (tpl.isEmpty) tpl = llm_tpl.defaultSummaryTemplate;
      } else {
        // 默认用活跃模板
        final tplSet = _ref.read(templatesProvider);
        tpl = tplSet.activeSummary?.content ?? config.summaryTemplate;
        if (tpl.isEmpty) tpl = llm_tpl.defaultSummaryTemplate;
      }
      final systemPrompt = llm_tpl.PromptTemplate.render(tpl, {
        'video_title': 'BV $bvid', 'bvid': bvid,
        'subtitle': transcript, 'subtitle_truncated': truncated,
        'language': subtitle.language, 'uploader': '', 'duration': '', 'page_count': '',
      });

      final buffer = StringBuffer();
      int charCount = 0;

      // 用 listen 替代 await for, 这样 cancel 可以中断卡住的 stream
      final completer = Completer<void>();
      _completers[bvid] = completer;
      final cancelToken = CancelToken();
      _cancelTokens[bvid] = cancelToken;
      Timer? watchdog;
      StreamSubscription<String>? sub;

      sub = client.chatStreamWithFallback(
        systemPrompt: systemPrompt,
        messages: const [{'role': 'user', 'content': '请开始总结'}],
        disableReasoning: disableReasoning,
        cancelToken: cancelToken,
      ).listen(
        (chunk) {
          // 重置 watchdog: 每次收到 chunk 再等 30s
          watchdog?.cancel();
          watchdog = Timer(const Duration(seconds: 30), () {
            if (_cancelFlags[bvid] == true) {
              sub?.cancel();
              final c = _completers.remove(bvid);
              c?.complete();
            }
          });

          if (_cancelFlags[bvid] == true) {
            _cancelFlags[bvid] = false;
            sub?.cancel();
            watchdog?.cancel();
            final c = _completers.remove(bvid);
            c?.complete();
            state = {...state, bvid: GenerationState(content: buffer.toString())};
            return;
          }
          buffer.write(chunk);
          charCount += chunk.length;
          state = {...state, bvid: GenerationState(isRunning: true, content: buffer.toString())};

          // 每 500 字更新通知
          if (charCount % 500 < chunk.length) {
            ForegroundServiceManager.updateNotification(
              title: '正在生成 $pageLabel 总结...',
              text: 'BV $bvid · ${buffer.length} 字',
            );
          }
        },
        onDone: () {
          _cancelSubs.remove(bvid);
          _completers.remove(bvid);
          watchdog?.cancel();
          if (!completer.isCompleted) completer.complete();
        },
        onError: (e) {
          _cancelSubs.remove(bvid);
          _completers.remove(bvid);
          watchdog?.cancel();
          if (!completer.isCompleted) completer.completeError(e);
        },
        cancelOnError: true,
      );
      // 立即注册 sub 供取消
      _cancelSubs[bvid] = sub;

      try {
        await completer.future;
      } catch (e) {
        rethrow;
      } finally {
        _completers.remove(bvid);
        _cancelSubs.remove(bvid);
        _cancelTokens.remove(bvid);
        watchdog?.cancel();
      }
      if (_cancelFlags[bvid] == true) {
        await ForegroundServiceManager.stop();
        return;
      }

      final repo = _ref.read(videoRepositoryProvider);
      final summary = await repo.createSummary(
        bvid: bvid, content: buffer.toString(),
        type: summary_model.SummaryType.structured,
        modelUsed: config.effectiveModel, promptUsed: systemPrompt, page: page,
      );

      repo.extractAndSaveAiTags(bvid: bvid, title: 'BV $bvid', content: buffer.toString());

      state = {...state, bvid: GenerationState(isCompleted: true, content: buffer.toString(), summaryId: summary.id)};
      Future.delayed(const Duration(seconds: 2), () {
        if (state[bvid]?.summaryId == summary.id) state = {...state}..remove(bvid);
      });
    } catch (e) {
      // 如果有部分内容 (卡住后取消 / 网络错误), 保存为草稿
      final partial = state[bvid]?.content ?? '';
      if (partial.trim().isNotEmpty) {
        try {
          final config = _ref.read(aiConfigProvider);
          await _ref.read(videoRepositoryProvider).createSummary(
            bvid: bvid, content: '⚠️ 生成中断/出错，已保存部分内容\n\n$partial',
            type: summary_model.SummaryType.structured,
            modelUsed: config.effectiveModel, promptUsed: 'partial', page: page,
          );
          state = {...state, bvid: GenerationState(
            isRunning: false, error: '$e (部分内容已保存)',
            content: partial)};
          return;
        } catch (_) {}
      }
      state = {...state, bvid: GenerationState(
        isRunning: false, error: '$e', content: partial)};
    } finally {
      await ForegroundServiceManager.stop();
    }
  }

  void clear(String bvid) => state = {...state}..remove(bvid);

  /// 继续生成 — 从上次中断的内容继续写 (用于被 max_tokens 截断后)
  Future<void> continueSummary({
    required String bvid,
    required VideoSubtitle subtitle,
    required String existingContent,
    String? templateId,
    int page = 0,
  }) async {
    _cancelFlags[bvid] = false;
    final pageLabel = page == 0 ? '整体' : 'P$page';
    // 保持 buffer 中的已有内容, 在已有内容基础上继续
    state = {...state, bvid: GenerationState(
      isRunning: true,
      content: existingContent,
    )};

    try {
      await ForegroundServiceManager.start(
        title: '正在继续生成 $pageLabel 总结...',
        text: 'BV $bvid',
      );

      final config = _ref.read(aiConfigProvider);
      final client = _ref.read(llmClientProvider);
      final disableReasoning = config.provider == LLMProvider.minimax;
      final transcript = subtitle.fullText;
      final truncated = transcript.length > config.maxContextChars
          ? transcript.substring(0, config.maxContextChars) : transcript;

      String tpl;
      if (templateId != null) {
        final selected = _ref.read(templatesProvider.notifier)
            .getById(TemplateType.summary, templateId);
        tpl = selected?.content ?? llm_tpl.defaultSummaryTemplate;
      } else {
        final tplSet = _ref.read(templatesProvider);
        tpl = tplSet.activeSummary?.content ?? config.summaryTemplate;
        if (tpl.isEmpty) tpl = llm_tpl.defaultSummaryTemplate;
      }
      final systemPrompt = llm_tpl.PromptTemplate.render(tpl, {
        'video_title': 'BV $bvid', 'bvid': bvid,
        'subtitle': transcript, 'subtitle_truncated': truncated,
        'language': subtitle.language, 'uploader': '', 'duration': '', 'page_count': '',
      });

      final buffer = StringBuffer(existingContent);
      int charCount = existingContent.length;

      final completer = Completer<void>();
      _completers[bvid] = completer;
      final cancelToken = CancelToken();
      _cancelTokens[bvid] = cancelToken;
      Timer? watchdog;
      StreamSubscription<String>? sub;

      // 提示 LLM 继续写
      final continuePrompt = '''你刚才的输出被中断了。下面是已有的总结内容：

$existingContent

[继续]

请从上一个被截断的句子中间继续接着写，**不要重复**已写过的部分，也不要添加 "好的" "下面继续" 等客套话。直接接着最后一个字写下去，直到结束。''';

      sub = client.chatStreamWithFallback(
        systemPrompt: systemPrompt,
        messages: [{'role': 'user', 'content': continuePrompt}], // ⭐ 用 continuePrompt, 不是 '请开始总结'
        disableReasoning: disableReasoning,
        cancelToken: cancelToken,
      ).listen(
        (chunk) {
          watchdog?.cancel();
          watchdog = Timer(const Duration(seconds: 30), () {
            if (_cancelFlags[bvid] == true) {
              sub?.cancel();
              final c = _completers.remove(bvid);
              c?.complete();
            }
          });

          if (_cancelFlags[bvid] == true) {
            _cancelFlags[bvid] = false;
            sub?.cancel();
            watchdog?.cancel();
            final c = _completers.remove(bvid);
            c?.complete();
            state = {...state, bvid: GenerationState(content: buffer.toString())};
            return;
          }
          buffer.write(chunk);
          charCount += chunk.length;
          state = {...state, bvid: GenerationState(isRunning: true, content: buffer.toString())};

          if (charCount % 500 < chunk.length) {
            ForegroundServiceManager.updateNotification(
              title: '正在继续生成 $pageLabel 总结...',
              text: 'BV $bvid · ${buffer.length} 字',
            );
          }
        },
        onDone: () {
          _cancelSubs.remove(bvid);
          _completers.remove(bvid);
          watchdog?.cancel();
          if (!completer.isCompleted) completer.complete();
        },
        onError: (e) {
          _cancelSubs.remove(bvid);
          _completers.remove(bvid);
          watchdog?.cancel();
          if (!completer.isCompleted) completer.completeError(e);
        },
        cancelOnError: true,
      );
      _cancelSubs[bvid] = sub;

      try {
        await completer.future;
      } catch (e) {
        rethrow;
      } finally {
        _completers.remove(bvid);
        _cancelSubs.remove(bvid);
        _cancelTokens.remove(bvid);
        watchdog?.cancel();
      }
      if (_cancelFlags[bvid] == true) {
        await ForegroundServiceManager.stop();
        return;
      }

      final repo = _ref.read(videoRepositoryProvider);
      final summary = await repo.createSummary(
        bvid: bvid, content: buffer.toString(),
        type: summary_model.SummaryType.structured,
        modelUsed: config.effectiveModel, promptUsed: systemPrompt, page: page,
      );

      state = {...state, bvid: GenerationState(
        isCompleted: true, content: buffer.toString(), summaryId: summary.id)};
      Future.delayed(const Duration(seconds: 2), () {
        if (state[bvid]?.summaryId == summary.id) state = {...state}..remove(bvid);
      });
    } catch (e) {
      final partial = state[bvid]?.content ?? existingContent;
      if (partial.trim().isNotEmpty) {
        try {
          final config = _ref.read(aiConfigProvider);
          await _ref.read(videoRepositoryProvider).createSummary(
            bvid: bvid, content: '⚠️ 继续生成中断/出错\n\n$partial',
            type: summary_model.SummaryType.structured,
            modelUsed: config.effectiveModel, promptUsed: 'partial', page: page,
          );
          state = {...state, bvid: GenerationState(
            isRunning: false, error: '$e (部分内容已保存)',
            content: partial)};
          return;
        } catch (_) {}
      }
      state = {...state, bvid: GenerationState(
        isRunning: false, error: '$e', content: partial)};
    } finally {
      await ForegroundServiceManager.stop();
    }
  }
}

final generationProvider = StateNotifierProvider<GenerationNotifier, Map<String, GenerationState>>(
  (ref) => GenerationNotifier(ref),
);
