import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/llm/prompt_template.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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

/// 全局生成管理器 — 不绑定 widget 生命周期
class GenerationNotifier extends StateNotifier<Map<String, GenerationState>> {
  final Ref _ref;

  GenerationNotifier(this._ref) : super({});

  GenerationState? getState(String bvid) => state[bvid];

  /// 启动后台总结生成
  Future<void> startSummaryGeneration({
    required String bvid,
    required VideoSubtitle subtitle,
    String? customPrompt,
  }) async {
    // 取消同视频之前的生成
    final prev = state[bvid];
    if (prev != null && prev.isRunning) {
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

      // MiniMax 系模型默认开推理，需要主动关闭才不返回 reasoning_content
      final disableReasoning = config.provider == LLMProvider.minimax ||
          config.provider == LLMProvider.minimaxFree;

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

      final tpl = (customPrompt ?? config.customSystemPrompt).isNotEmpty
          ? (customPrompt ?? config.customSystemPrompt)
          : (config.summaryTemplate.isNotEmpty
              ? config.summaryTemplate
              : defaultSummaryTemplate);
      final systemPrompt = PromptTemplate.render(tpl, templateVars);

      final buffer = StringBuffer();
      await for (final chunk in client.chatStreamWithFallback(
        systemPrompt: systemPrompt,
        messages: [{'role': 'user', 'content': '请开始总结'}],
        disableReasoning: disableReasoning,
      )) {
        buffer.write(chunk);
        state = {
          ...state,
          bvid: GenerationState(isRunning: true, content: buffer.toString()),
        };
      }

      // 保存到数据库
      final repo = _ref.read(videoRepositoryProvider);
      final summary = await repo.createSummary(
        bvid: bvid,
        content: buffer.toString(),
        type: summary_model.SummaryType.structured,
        modelUsed: config.effectiveModel,
        promptUsed: systemPrompt,
      );

      state = {
        ...state,
        bvid: GenerationState(
          isCompleted: true,
          content: buffer.toString(),
          summaryId: summary.id,
        ),
      };
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

  /// 清除某个视频的生成状态
  void clear(String bvid) {
    state = {...state}..remove(bvid);
  }
}

final generationProvider =
    StateNotifierProvider<GenerationNotifier, Map<String, GenerationState>>(
  (ref) => GenerationNotifier(ref),
);
