import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/events/video_events.dart';
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
  final d = AppDatabase();
  ref.onDispose(d.close);
  return d;
});

// ─── AI 配置 ────────────────────────────────────────────────────

class AIConfigNotifier extends StateNotifier<AIConfig> {
  Future<void>? _loading;

  AIConfigNotifier() : super(const AIConfig()) {
    _loading = _load();
  }

  /// ⭐ 确保配置已加载完成 (用于避免 race condition)
  Future<void> ensureLoaded() async {
    await _loading;
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
    ref.watch(videoEventBusProvider), // ⭐ 注入事件总线
  );
});

// ─── 备份服务 ─────────────────────────────────────────────────

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});

// ─── 容器系统 (3 平行容器) ─────────────────────────────────────

/// 把 drift 的 (Video + VideoGroup) 拼装成 model.Video
model.Video _videoFromGroup(dynamic v, dynamic g) {
  return model.Video(
    bvid: v.bvid as String,
    page: v.page as int,
    title: (v.partTitle as String).isNotEmpty ? v.partTitle : (g.title as String),
    coverUrl: (v.partCover as String).isNotEmpty ? v.partCover : (g.cover as String),
    uploader: g.uploader as String,
    duration: v.duration as int,
    pageCount: g.pageCount as int,
    addedAt: v.addedAt as DateTime,
    tags: (g.tags as String).isEmpty ? const [] : (g.tags as String).split(','),
    aiTags: (g.aiTags as String).isEmpty ? const [] : (g.aiTags as String).split(','),
  );
}

/// 异步把 db.Video 列表转 model.Video 列表 (需要 JOIN video_groups)
Future<List<model.Video>> _joinVideosWithGroups(
  List<dynamic> dbVideos,
  Future<dynamic> Function(String bvid) getGroup,
) async {
  final result = <model.Video>[];
  final groupCache = <String, dynamic>{};
  for (final v in dbVideos) {
    var g = groupCache[v.bvid];
    g ??= await getGroup(v.bvid);
    if (g == null) continue; // 没有 group 跳过 (理论上不会)
    groupCache[v.bvid] = g;
    result.add(_videoFromGroup(v, g));
  }
  return result;
}

enum ContainerType { manual, favorite, watchLater, upmaster }

extension ContainerTypeX on ContainerType {
  String get dbValue {
    switch (this) {
      case ContainerType.manual:
        return 'manual';
      case ContainerType.favorite:
        return 'favorite';
      case ContainerType.watchLater:
        return 'watch_later';
      case ContainerType.upmaster:
        return 'upmaster';
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
      case ContainerType.upmaster:
        return 'UP 主';
    }
  }
  static ContainerType fromDb(String v) {
    switch (v) {
      case 'favorite':
        return ContainerType.favorite;
      case 'watch_later':
        return ContainerType.watchLater;
      case 'upmaster':
        return ContainerType.upmaster;
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

/// 单个视频的 VideoGroup (含 pageCount / pageNamesJson)
final videoGroupProvider = StateNotifierProvider.family<
    VideoGroupNotifier, AsyncValue<VideoGroup?>, String>(
  (ref, bvid) => VideoGroupNotifier(ref, bvid),
);

class VideoGroupNotifier extends StateNotifier<AsyncValue<VideoGroup?>> {
  VideoGroupNotifier(this._ref, this._bvid) : super(const AsyncValue.loading()) {
    load();
  }
  final Ref _ref;
  final String _bvid;

  Future<void> load() async {
    try {
      final db = _ref.read(databaseProvider);
      state = AsyncValue.data(await db.getVideoGroup(_bvid));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 视频的字幕信息 (按页分)
class SubtitleInfo {
  final String language;
  final int page;
  final int entryCount;
  SubtitleInfo({required this.language, required this.page, required this.entryCount});
}

final allSubtitlesProvider = StateNotifierProvider.family<
    AllSubtitlesNotifier, AsyncValue<List<SubtitleInfo>>, String>(
  (ref, bvid) => AllSubtitlesNotifier(ref, bvid),
);

class AllSubtitlesNotifier extends StateNotifier<AsyncValue<List<SubtitleInfo>>> {
  AllSubtitlesNotifier(this._ref, this._bvid) : super(const AsyncValue.loading()) {
    load();
  }
  final Ref _ref;
  final String _bvid;

  Future<void> load() async {
    try {
      final db = _ref.read(databaseProvider);
      final rows = await db.getSubtitlesForVideo(_bvid);
      state = AsyncValue.data(rows
          .map((r) => SubtitleInfo(
                language: r.language,
                page: r.page,
                entryCount: r.entryCount,
              ))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

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
      // 转为 model.Video (含 JOIN video_groups)
      final videos = await _joinVideosWithGroups(
        dbVideos, (bvid) => db.getVideoGroup(bvid),
      );
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
      final result = await _joinVideosWithGroups(
        allVideos, (bvid) => db.getVideoGroup(bvid),
      );
      result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// UP主信息 (UI 友好包装)
class UpMasterInfo {
  final int id;
  final int uid;
  final String name;
  final String face;
  final int? lastVideoAid;
  final DateTime? lastSyncedAt;
  final int containerId;
  final DateTime addedAt;
  final int importedCount;

  UpMasterInfo({
    required this.id,
    required this.uid,
    required this.name,
    required this.face,
    required this.lastVideoAid,
    required this.lastSyncedAt,
    required this.containerId,
    required this.addedAt,
    required this.importedCount,
  });
}

/// 所有 UP 主列表
final upMasterListProvider =
    StateNotifierProvider<UpMasterListNotifier, AsyncValue<List<UpMasterInfo>>>(
  (ref) => UpMasterListNotifier(ref),
);

class UpMasterListNotifier extends StateNotifier<AsyncValue<List<UpMasterInfo>>> {
  UpMasterListNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }
  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      final ums = await db.getAllUpMasters();
      final result = <UpMasterInfo>[];
      for (final um in ums) {
        final imported = await db.countVideosInContainer(um.containerId);
        result.add(UpMasterInfo(
          id: um.id,
          uid: um.uid,
          name: um.name,
          face: um.face,
          lastVideoAid: um.lastVideoAid,
          lastSyncedAt: um.lastSyncedAt,
          containerId: um.containerId,
          addedAt: um.addedAt,
          importedCount: imported,
        ));
      }
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 跨所有 UP主容器的视频 (按 addedAt desc, 去重)
final allUpMasterVideosProvider = StateNotifierProvider<AllUpMasterVideosNotifier,
    AsyncValue<List<model.Video>>>(
  (ref) => AllUpMasterVideosNotifier(ref),
);

class AllUpMasterVideosNotifier
    extends StateNotifier<AsyncValue<List<model.Video>>> {
  AllUpMasterVideosNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }
  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      final containers = await db.getContainersByType('upmaster');
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
      final result = await _joinVideosWithGroups(
        allVideos, (bvid) => db.getVideoGroup(bvid),
      );
      result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// UP 主同步结果 (新发布的视频列表)
class UpMasterSyncResult {
  final int uid;
  final int newCount;     // 本次发现的新发布数
  final List<String> newBvids; // 新发布的 bvid 列表
  final int totalFromBili; // B站该UP主总视频数
  final DateTime syncedAt;
  final String? error;

  UpMasterSyncResult({
    required this.uid,
    required this.newCount,
    required this.newBvids,
    required this.totalFromBili,
    required this.syncedAt,
    this.error,
  });
}

/// UP 主同步 provider (按 uid family)
final upMasterSyncProvider = StateNotifierProvider.family<
    UpMasterSyncNotifier, AsyncValue<UpMasterSyncResult>, int>(
  (ref, uid) => UpMasterSyncNotifier(ref, uid),
);

class UpMasterSyncNotifier extends StateNotifier<AsyncValue<UpMasterSyncResult>> {
  UpMasterSyncNotifier(this._ref, this.uid)
      : super(AsyncValue.data(UpMasterSyncResult(
          uid: uid, newCount: 0, newBvids: [], totalFromBili: 0, syncedAt: DateTime.now(),
        )));
  final Ref _ref;
  final int uid;

  /// 拉 B 站 UP 主最新视频, 比对 lastVideoAid, 返回新发布列表
  Future<UpMasterSyncResult> sync() async {
    state = const AsyncValue.loading();
    try {
      final bili = _ref.read(bilibiliClientProvider);
      final db = _ref.read(databaseProvider);
      final um = await db.getUpMasterByUid(uid);
      if (um == null) throw Exception('UP 主不存在');

      // 拉最新 1 页 (20 个)
      final result = await bili.getUpMasterLatestVideos(uid, pn: 1, ps: 20);
      final videos = (result['videos'] as List).cast<Map>();
      final totalFromBili = (result['total'] as num?)?.toInt() ?? 0;

      // 找新发布的 (用 aid 倒序, 第一个 aid > lastVideoAid 就是新的)
      int? maxAid = um.lastVideoAid;
      final newBvids = <String>[];
      for (final v in videos) {
        final aid = (v['aid'] as num?)?.toInt() ?? 0;
        final bvid = v['bvid'] as String? ?? '';
        if (aid == 0 || bvid.isEmpty) continue;
        if (maxAid == null) {
          // 首次同步: 全算新发布
          newBvids.add(bvid);
        } else if (aid > maxAid) {
          newBvids.add(bvid);
        }
      }

      // 更新 lastVideoAid = 本次最大 aid
      if (videos.isNotEmpty) {
        final newLastAid = (videos.first['aid'] as num).toInt();
        if (maxAid == null || newLastAid > maxAid) {
          await db.updateUpMasterSync(uid, newLastAid);
        }
      }

      final syncResult = UpMasterSyncResult(
        uid: uid,
        newCount: newBvids.length,
        newBvids: newBvids,
        totalFromBili: totalFromBili,
        syncedAt: DateTime.now(),
      );
      state = AsyncValue.data(syncResult);
      // 同步后刷新 UP 主列表和视频列表
      _ref.read(upMasterListProvider.notifier).load();
      _ref.read(allUpMasterVideosProvider.notifier).load();
      return syncResult;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return UpMasterSyncResult(
        uid: uid, newCount: 0, newBvids: [],
        totalFromBili: 0, syncedAt: DateTime.now(), error: e.toString(),
      );
    }
  }
}
