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

  GenerationNotifier(this._ref) : super({});

  GenerationState? getState(String bvid) => state[bvid];

  void cancel(String bvid) => _cancelFlags[bvid] = true;

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

      final buffer = StringBuffer();
      int charCount = 0;
      await for (final chunk in client.chatStreamWithFallback(
        systemPrompt: systemPrompt,
        messages: const [{'role': 'user', 'content': '请开始总结'}],
        disableReasoning: disableReasoning,
      )) {
        if (_cancelFlags[bvid] == true) {
          _cancelFlags[bvid] = false;
          state = {...state, bvid: GenerationState(content: buffer.toString())};
          await ForegroundServiceManager.stop();
          return;
        }
        buffer.write(chunk);
        charCount += chunk.length;
        state = {...state, bvid: GenerationState(isRunning: true, content: buffer.toString())};

        // 每 500 字更新通知
        if (charCount % 500 < chunk.length) {
          await ForegroundServiceManager.updateNotification(
            title: '正在生成 $pageLabel 总结...',
            text: 'BV $bvid · ${buffer.length} 字',
          );
        }
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
      state = {...state, bvid: GenerationState(isRunning: false, error: '$e', content: state[bvid]?.content ?? '')};
    } finally {
      await ForegroundServiceManager.stop();
    }
  }

  void clear(String bvid) => state = {...state}..remove(bvid);
}

final generationProvider = StateNotifierProvider<GenerationNotifier, Map<String, GenerationState>>(
  (ref) => GenerationNotifier(ref),
);
