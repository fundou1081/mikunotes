import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/video.dart' as model;
import 'package:mikunotes/core/storage/backup_service.dart';
import 'package:mikunotes/core/storage/database.dart' hide Video;
import 'package:drift/drift.dart' show Value;
import 'package:mikunotes/core/providers/video_repository.dart';

const _secureStorage = FlutterSecureStorage();

const _kSessdata = 'bili_sessdata';
const _kUserInfo = 'bili_user_info';
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
    final modelName = await _secureStorage.read(key: _kAiModel);

    state = AIConfig(
      provider: LLMProvider.values.firstWhere(
        (p) => p.name == providerName,
        orElse: () => LLMProvider.deepseek,
      ),
      baseUrl: baseUrl ?? '',
      apiKey: apiKey ?? '',
      model: modelName ?? '',
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
    String? summaryTemplate,
    String? chatTemplate,
  }) async {
    state = state.copyWith(
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
      customSystemPrompt: customSystemPrompt,
      summaryTemplate: summaryTemplate,
      chatTemplate: chatTemplate,
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
    final userJson = await _secureStorage.read(key: _kUserInfo);
    BiliUser? cachedUser;
    if (userJson != null) {
      try {
        cachedUser = BiliUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    if (sessdata != null && sessdata.isNotEmpty) {
      state = BilibiliClient(sessdata: sessdata, user: cachedUser);
      // 后台验证 SESSDATA 是否还有效
      _validateSession();
    }
  }

  Future<void> _validateSession() async {
    try {
      final user = await state.fetchUserInfo();
      await _saveUser(user);
    } catch (_) {
      // SESSDATA 失效，但保留本地缓存的状态显示
    }
  }

  Future<void> _saveUser(BiliUser user) async {
    final sessdata = (await _secureStorage.read(key: _kSessdata)) ?? '';
    state = BilibiliClient(sessdata: sessdata, user: user);
    await _secureStorage.write(
      key: _kUserInfo,
      value: jsonEncode({
        'mid': user.mid,
        'uname': user.uname,
        'face': user.face,
        'level': user.level,
        'vipType': user.vipType,
        'sign': user.sign,
      }),
    );
  }

  /// 扫码登录完成后调用 - 一次性传入 SESSDATA + 用户信息
  Future<void> completeLogin({required String sessdata, BiliUser? user}) async {
    state = BilibiliClient(sessdata: sessdata, user: user);
    await _secureStorage.write(key: _kSessdata, value: sessdata);
    if (user != null) {
      await _secureStorage.write(
        key: _kUserInfo,
        value: jsonEncode({
          'mid': user.mid,
          'uname': user.uname,
          'face': user.face,
          'level': user.level,
          'vipType': user.vipType,
          'sign': user.sign,
        }),
      );
    }
  }

  /// 退出登录
  Future<void> logout() async {
    state = BilibiliClient();
    await _secureStorage.delete(key: _kSessdata);
    await _secureStorage.delete(key: _kUserInfo);
  }
}

final bilibiliClientProvider =
    StateNotifierProvider<BilibiliClientNotifier, BilibiliClient>(
  (ref) => BilibiliClientNotifier(),
);

// ─── 视频列表 ───────────────────────────────────────────────────

final videoListProvider =
    StateNotifierProvider<VideoListNotifier, AsyncValue<List<model.Video>>>(
  (ref) => VideoListNotifier(ref),
);

class VideoListNotifier extends StateNotifier<AsyncValue<List<model.Video>>> {
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

// ─── 视频仓库 provider ─────────────────────────────────────────

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository(
    ref.watch(bilibiliClientProvider),
    ref.watch(databaseProvider),
    ref,
  );
});

// ─── 备份服务 ─────────────────────────────────────────────────

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});

// ─── 容器系统 (3 平行容器) ─────────────────────────────────────

enum ContainerType { manual, favorite, watchLater }

extension ContainerTypeX on ContainerType {
  String get dbValue {
    switch (this) {
      case ContainerType.manual:
        return 'manual';
      case ContainerType.favorite:
        return 'favorite';
      case ContainerType.watchLater:
        return 'watch_later';
    }
  }
  String get displayName {
    switch (this) {
      case ContainerType.manual:
        return '手动导入';
      case ContainerType.favorite:
        return '收藏夹';
      case ContainerType.watchLater:
        return '稍后观看';
    }
  }
  static ContainerType fromDb(String v) {
    switch (v) {
      case 'favorite':
        return ContainerType.favorite;
      case 'watch_later':
        return ContainerType.watchLater;
      default:
        return ContainerType.manual;
    }
  }
}

/// 容器信息 (UI 友好包装)
class ContainerInfo {
  final int id;
  final ContainerType type;
  final String? externalId;
  final String name;
  final int totalCount;
  final int importedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContainerInfo({
    required this.id,
    required this.type,
    required this.externalId,
    required this.name,
    required this.totalCount,
    required this.importedCount,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progress => totalCount == 0 ? 0 : importedCount / totalCount;
}

/// 容器列表
final containerListProvider =
    StateNotifierProvider<ContainerListNotifier, AsyncValue<List<ContainerInfo>>>(
  (ref) => ContainerListNotifier(ref),
);

class ContainerListNotifier extends StateNotifier<AsyncValue<List<ContainerInfo>>> {
  ContainerListNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }
  final Ref _ref;

  Future<void> load() async {
    try {
      final db = _ref.read(databaseProvider);
      final containers = await db.getAllContainers();
      final result = <ContainerInfo>[];
      for (final c in containers) {
        final imported = await db.countVideosInContainer(c.id);
        result.add(ContainerInfo(
          id: c.id,
          type: ContainerTypeX.fromDb(c.type),
          externalId: c.externalId,
          name: c.name,
          totalCount: c.totalCount,
          importedCount: imported,
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
        ));
      }
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 同步 B 站收藏夹列表 (从 API 拉 → 写入 DB)
  Future<void> syncFavFolders() async {
    final bili = _ref.read(bilibiliClientProvider);
    if (!bili.isLoggedIn) {
      throw Exception('未登录 B 站');
    }
    final biliFolders = await bili.getFavFolders();
    final db = _ref.read(databaseProvider);
    for (final f in biliFolders) {
      final fid = f['id']?.toString();
      if (fid == null) continue;
      final existing = await db.getContainerByExternalId(fid);
      final name = f['title'] as String? ?? '未命名';
      final total = (f['media_count'] as num?)?.toInt() ?? 0;
      if (existing == null) {
        await db.insertContainer(ContainersCompanion.insert(
          type: 'favorite',
          externalId: Value(fid),
          name: name,
          totalCount: Value(total),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      } else {
        // 更新名称和总数
        await db.updateContainer(existing.id, ContainersCompanion(
          name: Value(name),
          totalCount: Value(total),
          updatedAt: Value(DateTime.now()),
        ));
      }
    }
    await load();
  }

  /// 创建/同步稍后观看容器
  Future<void> syncWatchLater() async {
    final bili = _ref.read(bilibiliClientProvider);
    if (!bili.isLoggedIn) {
      throw Exception('未登录 B 站');
    }
    final db = _ref.read(databaseProvider);
    final bvids = await bili.getWatchLaterBvids();
    // 确保 watch_later 容器存在
    final existing = await (db.select(db.containers)
          ..where((c) => c.type.equals('watch_later')))
        .getSingleOrNull();
    int containerId;
    if (existing == null) {
      containerId = await db.insertContainer(ContainersCompanion.insert(
        type: 'watch_later',
        name: '稍后观看',
        totalCount: Value(bvids.length),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    } else {
      containerId = existing.id;
      await db.updateContainer(containerId, ContainersCompanion(
        totalCount: Value(bvids.length),
        updatedAt: Value(DateTime.now()),
      ));
    }
    await load();
  }

  Future<void> deleteContainer(int id) async {
    final db = _ref.read(databaseProvider);
    await db.deleteContainer(id);
    await load();
  }
}

/// 指定容器内的视频列表
final videosInContainerProvider = StateNotifierProvider.family<
    VideosInContainerNotifier, AsyncValue<List<model.Video>>, int>(
  (ref, containerId) => VideosInContainerNotifier(ref, containerId),
);

class VideosInContainerNotifier
    extends StateNotifier<AsyncValue<List<model.Video>>> {
  VideosInContainerNotifier(this._ref, this.containerId)
      : super(const AsyncValue.loading()) {
    load();
  }
  final Ref _ref;
  final int containerId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      final dbVideos = await db.getVideosInContainer(containerId);
      // 转为 model.Video
      final videos = dbVideos
          .map((v) => model.Video(
                id: v.bvid,
                bvid: v.bvid,
                title: v.title,
                coverUrl: v.coverUrl,
                uploader: v.uploader,
                duration: v.duration,
                pageCount: v.pageCount,
                addedAt: v.addedAt,
                tags: v.tags.isEmpty ? [] : v.tags.split(','),
              ))
          .toList();
      videos.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      state = AsyncValue.data(videos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 跨所有收藏夹容器的视频 (去重 + 按 addedAt 排序)
final allFavoriteVideosProvider = StateNotifierProvider<AllFavoriteVideosNotifier,
    AsyncValue<List<model.Video>>>(
  (ref) => AllFavoriteVideosNotifier(ref),
);

class AllFavoriteVideosNotifier
    extends StateNotifier<AsyncValue<List<model.Video>>> {
  AllFavoriteVideosNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }
  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      final containers = await db.getContainersByType('favorite');
      final allBvids = <String>{};
      for (final c in containers) {
        final bvids = await db.getBvidsInContainer(c.id);
        allBvids.addAll(bvids);
      }
      if (allBvids.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      final allVideos =
          await (db.select(db.videos)..where((v) => v.bvid.isIn(allBvids.toList())))
              .get();
      final result = allVideos
          .map((v) => model.Video(
                id: v.bvid,
                bvid: v.bvid,
                title: v.title,
                coverUrl: v.coverUrl,
                uploader: v.uploader,
                duration: v.duration,
                pageCount: v.pageCount,
                addedAt: v.addedAt,
                tags: v.tags.isEmpty ? [] : v.tags.split(','),
              ))
          .toList();
      result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
