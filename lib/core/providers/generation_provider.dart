import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/background/foreground_service_manager.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
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

  GenerationNotifier(this._ref) : super({});

  GenerationState? getState(String bvid) => state[bvid];

  void cancel(String bvid) {
    _cancelFlags[bvid] = true;
    // 强制取消订阅 + 立即 complete completer (中断卡住的 await)
    _cancelSubs[bvid]?.cancel();
    final c = _completers.remove(bvid);
    c?.complete();
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
      Timer? watchdog;
      StreamSubscription<String>? sub;

      sub = client.chatStreamWithFallback(
        systemPrompt: systemPrompt,
        messages: const [{'role': 'user', 'content': '请开始总结'}],
        disableReasoning: disableReasoning,
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
}

final generationProvider = StateNotifierProvider<GenerationNotifier, Map<String, GenerationState>>(
  (ref) => GenerationNotifier(ref),
);
