import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';

// ─── AI 配置 ──────────────────────────────────────────────────────

final aiConfigProvider = StateNotifierProvider<AIConfigNotifier, AIConfig>(
  (ref) => AIConfigNotifier(),
);

class AIConfigNotifier extends StateNotifier<AIConfig> {
  AIConfigNotifier() : super(const AIConfig());

  void setProvider(LLMProvider provider) {
    state = state.copyWith(provider: provider);
  }

  void updateConfig({
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    String? customSystemPrompt,
  }) {
    state = state.copyWith(
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
      customSystemPrompt: customSystemPrompt,
    );
  }
}

// ─── LLM 客户端 ───────────────────────────────────────────────────

final llmClientProvider = Provider<LLMClient>((ref) {
  final config = ref.watch(aiConfigProvider);
  return LLMClient(config: config);
});

// ─── B站 客户端 ───────────────────────────────────────────────────

final bilibiliClientProvider = Provider<BilibiliClient>((ref) {
  return BilibiliClient();
});

// ─── 登录状态 ─────────────────────────────────────────────────────

final loginStateProvider = StateProvider<bool>((ref) => false);

// ─── 视频列表 ─────────────────────────────────────────────────────

final videoListProvider = StateNotifierProvider<VideoListNotifier, List<String>>(
  (ref) => VideoListNotifier(),
);

class VideoListNotifier extends StateNotifier<List<String>> {
  VideoListNotifier() : super([]);

  void addVideo(String bvid) {
    if (!state.contains(bvid)) {
      state = [...state, bvid];
    }
  }

  void removeVideo(String bvid) {
    state = state.where((v) => v != bvid).toList();
  }
}
