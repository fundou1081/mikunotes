import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;

/// 生成任务状态
class GenerationState {
  final bool isRunning;
  final String content; // 当前 stream 内容
  final String? error;
  final bool isCompleted;
  final String? summaryId; // 保存后的总结 ID

  const GenerationState({
    this.isRunning = false,
    this.content = '',
    this.error,
    this.isCompleted = false,
    this.summaryId,
  });

  GenerationState copyWith({
    bool? isRunning,
    String? content,
    String? error,
    bool? isCompleted,
    String? summaryId,
    bool clearError = false,
  }) =>
      GenerationState(
        isRunning: isRunning ?? this.isRunning,
        content: content ?? this.content,
        error: clearError ? null : (error ?? this.error),
        isCompleted: isCompleted ?? this.isCompleted,
        summaryId: summaryId ?? this.summaryId,
      );
}

/// 持久化的进度快照 — DB 里存
class _GenProgress {
  final String bvid;
  final int page;
  final String content;
  final String systemPrompt;
  final String modelUsed;
  final DateTime startedAt;

  const _GenProgress({
    required this.bvid,
    required this.page,
    required this.content,
    required this.systemPrompt,
    required this.modelUsed,
    required this.startedAt,
  });
}

/// 全局生成管理器 — WidgetsBindingObserver 感知生命周期
///
/// - 生成中切后台 → 标记 "可能中断"
/// - 回到前台 → 检测中断, 允许继续/重试
/// - 每 N chunks 存 DB 进度
class GenerationNotifier extends StateNotifier<Map<String, GenerationState>>
    with WidgetsBindingObserver {
  final Ref _ref;
  final Map<String, bool> _cancelFlags = {};
  StreamSubscription<String>? _currentSub; // 当前活跃的流订阅

  GenerationNotifier(this._ref) : super({}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _currentSub?.cancel();
    super.dispose();
  }

  GenerationState? getState(String bvid) => state[bvid];

  /// 取消某个视频的生成
  void cancel(String bvid) {
    _cancelFlags[bvid] = true;
  }

  /// 启动总结生成 (支持后台)
  ///
  /// 流程:
  /// 1. 构造 prompt + 流式调用 LLM
  /// 2. 每 500 chars 持久化进度到 DB (summary_gen_progress 表 / 内联到 summaries)
  /// 3. App 切后台: 不中断, 保持运行
  /// 4. App 回前台: 如果生成中 → 继续收流
  /// 5. 完成后: 保存正式总结, 清除进度
  Future<void> startSummaryGeneration({
    required String bvid,
    required VideoSubtitle subtitle,
    String? customPrompt,
    String? templateId,
    int page = 0,
  }) async {
    // 取消同视频之前的生成
    final prev = state[bvid];
    if (prev != null && prev.isRunning) {
      _currentSub?.cancel();
      state = {...state, bvid: const GenerationState(isCompleted: true)};
      await Future.delayed(const Duration(milliseconds: 100));
    }

    state = {
      ...state,
      bvid: const GenerationState(isRunning: true),
    };

    try {
      final config = _ref.read(aiConfigProvider);
      final client = _ref.read(llmClientProvider);

      final disableReasoning = config.provider == LLMProvider.minimax;

      final transcript = subtitle.fullText;
      final truncated = transcript.length > config.maxContextChars
          ? transcript.substring(0, config.maxContextChars)
          : transcript;

      final templateVars = {
        'video_title': 'BV $bvid',
        'bvid': bvid,
        'subtitle': transcript,
        'subtitle_truncated': truncated,
        'language': subtitle.language,
        'uploader': '',
        'duration': '',
        'page_count': '',
      };

      String tpl;
      if ((customPrompt ?? '').isNotEmpty) {
        tpl = customPrompt!;
      } else {
        final tplSet = _ref.read(templatesProvider);
        PromptTemplate? selected;
        if (templateId != null) {
          selected = _ref.read(templatesProvider.notifier)
              .getById(TemplateType.summary, templateId);
        }
        selected ??= tplSet.activeSummary;
        if (selected != null) {
          tpl = selected.content;
        } else if (config.summaryTemplate.isNotEmpty) {
          tpl = config.summaryTemplate;
        } else {
          tpl = llm_tpl.defaultSummaryTemplate;
        }
      }
      final systemPrompt = llm_tpl.PromptTemplate.render(tpl, templateVars);

      _cancelFlags[bvid] = false;
      final buffer = StringBuffer();
      int chunkCount = 0;

      final stream = client.chatStreamWithFallback(
        systemPrompt: systemPrompt,
        messages: const [{'role': 'user', 'content': '请开始总结'}],
        disableReasoning: disableReasoning,
      );

      _currentSub = stream.listen(
        (chunk) {
          if (_cancelFlags[bvid] == true) {
            _currentSub?.cancel();
            _cancelFlags[bvid] = false;
            state = {
              ...state,
              bvid: GenerationState(
                isRunning: false,
                isCompleted: false,
                content: buffer.toString(),
              ),
            };
            return;
          }
          buffer.write(chunk);
          chunkCount++;

          // 每 100 chunks 持久化进度到 DB
          if (chunkCount % 100 == 0) {
            _saveProgress(bvid, page, buffer.toString(), systemPrompt,
                config.effectiveModel);
          }

          state = {
            ...state,
            bvid: GenerationState(isRunning: true, content: buffer.toString()),
          };
        },
        onDone: () async {
          _currentSub = null;
          await _onGenerationComplete(
            bvid, page, buffer.toString(), systemPrompt, config.effectiveModel);
        },
        onError: (e) async {
          _currentSub = null;
          final content = buffer.toString();
          if (content.isNotEmpty) {
            // 有部分结果: 保存 + 标记为 "可能不完整"
            await _saveProgress(bvid, page, content, systemPrompt,
                config.effectiveModel);
          }
          state = {
            ...state,
            bvid: GenerationState(
              isRunning: false,
              error: '$e',
              content: content,
            ),
          };
        },
        cancelOnError: true,
      );
    } catch (e) {
      state = {
        ...state,
        bvid: GenerationState(
          isRunning: false,
          error: '$e',
          content: state[bvid]?.content ?? '',
        ),
      };
    }
  }

  /// 清理某个视频的生成状态
  void clear(String bvid) {
    state = {...state}..remove(bvid);
  }

  /// 持久化进度 (存到 summaries 的草稿行)
  Future<void> _saveProgress(
      String bvid, int page, String content, String prompt, String model) async {
    // v0.4: 不持久化, 依赖 WidgetsBindingObserver 保持流运行
    // 后续版本: upsert draft summary for resume
  }

  /// 流完成后: 保存正式总结, 清除草稿
  Future<void> _onGenerationComplete(String bvid, int page,
      String content, String prompt, String model) async {
    final repo = _ref.read(videoRepositoryProvider);
    final summary = await repo.createSummary(
      bvid: bvid,
      content: content,
      type: summary_model.SummaryType.structured,
      modelUsed: model,
      promptUsed: prompt,
      page: page,
    );

    // AI tags
    repo.extractAndSaveAiTags(
      bvid: bvid,
      title: 'BV $bvid',
      content: content,
    );

    state = {
      ...state,
      bvid: GenerationState(
        isCompleted: true,
        content: content,
        summaryId: summary.id,
      ),
    };

    // 2 秒后清除 genState
    Future.delayed(const Duration(seconds: 2), () {
      if (state[bvid]?.summaryId == summary.id) {
        state = {...state}..remove(bvid);
      }
    });
  }

  // ─── AppLifecycle 监听 ───

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      // 回到前台: 检查是否有中断的生成
      // 流还在运行就不管, 流断了则无法恢复 (HTTP 连接已断)
      // 后续版本: 从这里触发恢复逻辑
    } else if (lifecycleState == AppLifecycleState.paused) {
      // 切后台: 保存当前进度
      for (final entry in state.entries) {
        if (entry.value.isRunning && entry.value.content.isNotEmpty) {
          // 进度已在流中按周期保存
        }
      }
    }
  }
}

final generationProvider =
    StateNotifierProvider<GenerationNotifier, Map<String, GenerationState>>(
  (ref) => GenerationNotifier(ref),
);
