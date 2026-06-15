import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/storage/database.dart';

const _secureStorage = FlutterSecureStorage();

// ─── 加密存储 key ───────────────────────────────────────────────
const _kSessdata = 'bili_sessdata';
const _kApiKey = 'ai_api_key';
const _kAiBaseUrl = 'ai_base_url';
const _kAiModel = 'ai_model';
const _kAiProvider = 'ai_provider';

// ─── 数据库 ─────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ─── AI 配置 ────────────────────────────────────────────────────

class AIConfigNotifier extends StateNotifier<AIConfig> {
  AIConfigNotifier() : super(const AIConfig()) {
    _load();
  }

  Future<void> _load() async {
    final providerName = await _secureStorage.read(key: _kAiProvider);
    final baseUrl = await _secureStorage.read(key: _kAiBaseUrl);
    final apiKey = await _secureStorage.read(key: _kApiKey);
    final model = await _secureStorage.read(key: _kAiModel);

    state = AIConfig(
      provider: LLMProvider.values.firstWhere(
        (p) => p.name == providerName,
        orElse: () => LLMProvider.deepseek,
      ),
      baseUrl: baseUrl ?? '',
      apiKey: apiKey ?? '',
      model: model ?? '',
    );
  }

  Future<void> setProvider(LLMProvider provider) async {
    state = state.copyWith(provider: provider);
    await _secureStorage.write(key: _kAiProvider, value: provider.name);
  }

  Future<void> updateConfig({
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    String? customSystemPrompt,
  }) async {
    state = state.copyWith(
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
      customSystemPrompt: customSystemPrompt,
    );
    if (baseUrl != null) await _secureStorage.write(key: _kAiBaseUrl, value: baseUrl);
    if (apiKey != null) await _secureStorage.write(key: _kApiKey, value: apiKey);
    if (model != null) await _secureStorage.write(key: _kAiModel, value: model);
  }
}

final aiConfigProvider = StateNotifierProvider<AIConfigNotifier, AIConfig>(
  (ref) => AIConfigNotifier(),
);

// ─── LLM 客户端 ─────────────────────────────────────────────────

import 'package:mikunotes/core/llm/llm_client.dart';

final llmClientProvider = Provider<LLMClient>((ref) {
  final config = ref.watch(aiConfigProvider);
  return LLMClient(config: config);
});

// ─── B站 客户端 ─────────────────────────────────────────────────

class BilibiliClientNotifier extends StateNotifier<BilibiliClient> {
  BilibiliClientNotifier() : super(BilibiliClient()) {
    _load();
  }

  Future<void> _load() async {
    final sessdata = await _secureStorage.read(key: _kSessdata);
    if (sessdata != null && sessdata.isNotEmpty) {
      state = BilibiliClient(sessdata: sessdata);
    }
  }

  Future<void> setSessdata(String sessdata) async {
    state = BilibiliClient(sessdata: sessdata);
    await _secureStorage.write(key: _kSessdata, value: sessdata);
  }

  Future<void> logout() async {
    state = BilibiliClient();
    await _secureStorage.delete(key: _kSessdata);
  }
}

final bilibiliClientProvider =
    StateNotifierProvider<BilibiliClientNotifier, BilibiliClient>(
  (ref) => BilibiliClientNotifier(),
);

// ─── 视频列表 ───────────────────────────────────────────────────

import 'package:mikunotes/core/models/video.dart';

final videoListProvider = StateNotifierProvider<VideoListNotifier, AsyncValue<List<Video>>>(
  (ref) => VideoListNotifier(ref),
);

class VideoListNotifier extends StateNotifier<AsyncValue<List<Video>>> {
  VideoListNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(videoRepositoryProvider);
      final videos = await repo.getAllVideos();
      state = AsyncValue.data(videos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addVideo(String url) async {
    final repo = _ref.read(videoRepositoryProvider);
    await repo.addVideo(url);
    await load();
  }

  Future<void> deleteVideo(String bvid) async {
    final repo = _ref.read(videoRepositoryProvider);
    await repo.deleteVideo(bvid);
    await load();
  }
}

// Re-export
export 'video_repository.dart' show videoRepositoryProvider;
