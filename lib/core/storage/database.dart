import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// 视频表
class Videos extends Table {
  TextColumn get bvid => text()();
  TextColumn get title => text()();
  TextColumn get coverUrl => text().withDefault(const Constant(''))();
  TextColumn get uploader => text().withDefault(const Constant(''))();
  IntColumn get upMid => integer().withDefault(const Constant(0))(); // B站 UP主 mid
  IntColumn get aid => integer()();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  IntColumn get pageCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get addedAt => dateTime()();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get aiTags => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {bvid};
}

/// UP主表 (跟踪关注的 UP 主 + 关联到容器)
class UpMasters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get uid => integer().unique()(); // B站 mid
  TextColumn get name => text()();
  TextColumn get face => text().withDefault(const Constant(''))();
  IntColumn get lastVideoAid => integer().nullable()(); // 上次同步到的最新视频 aid
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  IntColumn get containerId => integer()(); // 关联 containers.id
  DateTimeColumn get addedAt => dateTime()();
}

/// 字幕表 (一个视频可有多语言)
class Subtitles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bvid => text()();
  IntColumn get pageNum => integer().withDefault(const Constant(1))();
  TextColumn get language => text()();
  TextColumn get rawJson => text()();
  TextColumn get plainText => text()();
  IntColumn get charCount => integer().withDefault(const Constant(0))();
  IntColumn get entryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {bvid, pageNum, language}
      ];
}

/// 总结表
class Summaries extends Table {
  TextColumn get id => text()();
  TextColumn get bvid => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get type => text()();
  TextColumn get content => text()();
  TextColumn get modelUsed => text().withDefault(const Constant(''))();
  TextColumn get promptUsed => text().withDefault(const Constant(''))();
  TextColumn get targetTopic => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 对话会话表
class ChatSessions extends Table {
  TextColumn get id => text()();
  TextColumn get bvid => text()();
  TextColumn get title => text().withDefault(const Constant('新对话'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastActiveAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 对话消息表
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isCompressed => boolean().withDefault(const Constant(false))();
}

/// 容器表 (手动 / 收藏夹 / 稍后观看)
class Containers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'manual' | 'favorite' | 'watch_later'
  TextColumn get externalId => text().nullable()(); // B站收藏夹 ID (favorite 才有)
  TextColumn get name => text()();
  IntColumn get totalCount => integer().withDefault(const Constant(0))(); // B站原数
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// 容器-视频 多对多关联表
class ContainerVideos extends Table {
  IntColumn get containerId => integer()();
  TextColumn get bvid => text()();
  DateTimeColumn get addedAt => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))(); // 预留备注

  @override
  Set<Column> get primaryKey => {containerId, bvid};
}

@DriftDatabase(
  tables: [Videos, Subtitles, Summaries, ChatSessions, ChatMessages, Containers, ContainerVideos, UpMasters],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // 创建默认的 "手动" 容器
          await _ensureManualContainer();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: 新增 title 字段到 Summaries, 加 ChatSessions 表
            await m.addColumn(summaries, summaries.title);
            await m.createTable(chatSessions);
            await m.addColumn(chatMessages, chatMessages.sessionId);
            await m.addColumn(chatMessages, chatMessages.isCompressed);
          }
          if (from < 3) {
            // v3: 加 aiTags 字段到 Videos
            await m.addColumn(videos, videos.aiTags);
          }
          if (from < 4) {
            // v4: 加 containers + container_videos 表, 迁移老视频到 manual 容器
            await m.createTable(containers);
            await m.createTable(containerVideos);
            await _migrateOldVideosToManual();
          }
          if (from < 5) {
            // v5: 加 upmasters 表 + videos.upMid 列
            await m.addColumn(videos, videos.upMid);
            await m.createTable(upMasters);
          }
        },
      );

  /// v4 migration: 将老视频全部归到 manual 容器
  Future<void> _migrateOldVideosToManual() async {
    final manualId = await _ensureManualContainer();
    final allVideos = await select(videos).get();
    final now = DateTime.now();
    for (final v in allVideos) {
      await into(containerVideos).insert(
        ContainerVideosCompanion.insert(
          containerId: manualId,
          bvid: v.bvid,
          addedAt: v.addedAt,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
    // avoid unused variable
    now.toString();
  }

  /// 确保 "手动" 容器存在, 返回其 ID
  Future<int> _ensureManualContainer() async {
    final existing = await (select(containers)
          ..where((c) => c.type.equals('manual')))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    final id = await into(containers).insert(
      ContainersCompanion.insert(
        type: 'manual',
        name: '手动导入',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return id;
  }

  // ─── 视频 ──────────────────────────────────────────────

  Future<List<Video>> getAllVideos() =>
      (select(videos)..orderBy([(v) => OrderingTerm.desc(v.addedAt)])).get();

  Future<Video?> getVideo(String bvid) =>
      (select(videos)..where((v) => v.bvid.equals(bvid))).getSingleOrNull();

  Future<void> upsertVideo(VideosCompanion v) =>
      into(videos).insertOnConflictUpdate(v);

  /// 更新视频的 AI tags
  Future<void> updateVideoTags(String bvid, {String? aiTags}) async {
    if (aiTags == null) return;
    await customStatement(
      'UPDATE videos SET ai_tags = ? WHERE bvid = ?',
      [aiTags, bvid],
    );
  }

  Future<void> deleteVideo(String bvid) async {
    await (delete(subtitles)..where((s) => s.bvid.equals(bvid))).go();
    await (delete(summaries)..where((s) => s.bvid.equals(bvid))).go();
    // 先查出该视频的所有会话
    final sessions = await (select(chatSessions)
          ..where((s) => s.bvid.equals(bvid)))
        .get();
    // 删除每个会话的消息
    for (final s in sessions) {
      await (delete(chatMessages)
            ..where((m) => m.sessionId.equals(s.id)))
          .go();
    }
    // 最后删除会话
    await (delete(chatSessions)..where((s) => s.bvid.equals(bvid))).go();
    await (delete(videos)..where((v) => v.bvid.equals(bvid))).go();
  }

  // ─── 字幕 ──────────────────────────────────────────────

  Future<List<Subtitle>> getSubtitlesForVideo(String bvid) =>
      (select(subtitles)..where((s) => s.bvid.equals(bvid))).get();

  Future<Subtitle?> getSubtitle(String bvid, int pageNum, String lang) =>
      (select(subtitles)
            ..where((s) =>
                s.bvid.equals(bvid) &
                s.pageNum.equals(pageNum) &
                s.language.equals(lang)))
          .getSingleOrNull();

  Future<void> upsertSubtitle(SubtitlesCompanion s) =>
      into(subtitles).insertOnConflictUpdate(s);

  // ─── 总结 ──────────────────────────────────────────────

  Future<List<Summary>> getSummariesForVideo(String bvid) =>
      (select(summaries)
            ..where((s) => s.bvid.equals(bvid))
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
          .get();

  Future<Summary?> getSummary(String id) =>
      (select(summaries)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<void> saveSummary(SummariesCompanion s) =>
      into(summaries).insertOnConflictUpdate(s);

  Future<void> deleteSummary(String id) =>
      (delete(summaries)..where((s) => s.id.equals(id))).go();

  // ─── 对话会话 ──────────────────────────────────────────────

  Future<List<ChatSession>> getChatSessionsForVideo(String bvid) =>
      (select(chatSessions)
            ..where((s) => s.bvid.equals(bvid))
            ..orderBy([(s) => OrderingTerm.desc(s.lastActiveAt)]))
          .get();

  Future<ChatSession?> getChatSession(String id) =>
      (select(chatSessions)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<void> saveChatSession(ChatSessionsCompanion s) =>
      into(chatSessions).insertOnConflictUpdate(s);

  Future<void> updateChatSessionLastActive(String id) => (update(chatSessions)
        ..where((s) => s.id.equals(id)))
      .write(ChatSessionsCompanion(lastActiveAt: Value(DateTime.now())));

  Future<void> deleteChatSession(String id) async {
    await (delete(chatMessages)..where((m) => m.sessionId.equals(id))).go();
    await (delete(chatSessions)..where((s) => s.id.equals(id))).go();
  }

  // ─── 对话消息 ──────────────────────────────────────────────

  Future<List<ChatMessage>> getChatMessages(String sessionId) =>
      (select(chatMessages)
            ..where((m) => m.sessionId.equals(sessionId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .get();

  Future<void> saveChatMessage(ChatMessagesCompanion m) =>
      into(chatMessages).insert(m);

  /// 删除会话中最早的 N 条消息 (用于上下文压缩)
  Future<int> deleteOldestMessages(String sessionId, int count) async {
    // 先查出最早的 N 条
    final oldest = await (select(chatMessages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.asc(m.timestamp)])
          ..limit(count))
        .get();
    if (oldest.isEmpty) return 0;
    // 按 ID 删除
    return (delete(chatMessages)
          ..where((m) => m.id.isIn(oldest.map((m) => m.id))))
        .go();
  }

  /// 更新消息的压缩标记
  Future<void> markMessageCompressed(String messageId) => (update(chatMessages)
        ..where((m) => m.id.equals(messageId)))
      .write(const ChatMessagesCompanion(isCompressed: Value(true)));

  /// 清空会话所有消息
  Future<void> clearChatMessages(String sessionId) =>
      (delete(chatMessages)..where((m) => m.sessionId.equals(sessionId))).go();

  // ─── 容器 ──────────────────────────────────────────────

  /// 获取所有容器
  Future<List<Container>> getAllContainers() =>
      (select(containers)..orderBy([(c) => OrderingTerm.asc(c.id)])).get();

  /// 获取指定类型的容器
  Future<List<Container>> getContainersByType(String type) =>
      (select(containers)..where((c) => c.type.equals(type))).get();

  /// 根据 externalId (B站收藏夹 ID) 获取容器
  Future<Container?> getContainerByExternalId(String externalId) =>
      (select(containers)..where((c) => c.externalId.equals(externalId)))
          .getSingleOrNull();

  /// 获取指定 ID 的容器
  Future<Container?> getContainer(int id) =>
      (select(containers)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// 插入容器
  Future<int> insertContainer(ContainersCompanion c) =>
      into(containers).insert(c, mode: InsertMode.insertOrIgnore);

  /// 更新容器 (名称 / totalCount)
  Future<void> updateContainer(int id, ContainersCompanion c) =>
      (update(containers)..where((c) => c.id.equals(id))).write(c);

  /// 删除容器
  Future<void> deleteContainer(int id) async {
    await (delete(containerVideos)..where((cv) => cv.containerId.equals(id))).go();
    await (delete(containers)..where((c) => c.id.equals(id))).go();
  }

  /// 将视频加入容器 (不重复)
  Future<void> addVideoToContainer(int containerId, String bvid,
      {DateTime? addedAt}) async {
    await into(containerVideos).insert(
      ContainerVideosCompanion.insert(
        containerId: containerId,
        bvid: bvid,
        addedAt: addedAt ?? DateTime.now(),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// 从容器中移除视频
  Future<void> removeVideoFromContainer(int containerId, String bvid) =>
      (delete(containerVideos)
            ..where((cv) => cv.containerId.equals(containerId) & cv.bvid.equals(bvid)))
          .go();

  /// 批量加入容器 (用于增量导入)
  Future<void> bulkAddVideosToContainer(
      int containerId, List<String> bvids) async {
    final now = DateTime.now();
    await batch((b) {
      for (final bvid in bvids) {
        b.insert(
          containerVideos,
          ContainerVideosCompanion.insert(
            containerId: containerId,
            bvid: bvid,
            addedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// 获取某个容器的所有视频 (返回 bvid 列表)
  Future<List<String>> getBvidsInContainer(int containerId) =>
      (select(containerVideos)
            ..where((cv) => cv.containerId.equals(containerId))
            ..orderBy([(cv) => OrderingTerm.desc(cv.addedAt)]))
          .map((cv) => cv.bvid)
          .get();

  /// 获取指定 bvid 集合 (用于按容器查视频)
  Future<List<Video>> getVideosInContainer(int containerId) async {
    final bvids = await getBvidsInContainer(containerId);
    if (bvids.isEmpty) return [];
    return (select(videos)..where((v) => v.bvid.isIn(bvids))).get();
  }

  /// 获取容器的实际视频数 (用于统计已/总)
  Future<int> countVideosInContainer(int containerId) async {
    final result = await (selectOnly(containerVideos)
          ..addColumns([containerVideos.bvid.count()])
          ..where(containerVideos.containerId.equals(containerId)))
        .getSingle();
    return result.read(containerVideos.bvid.count()) ?? 0;
  }

  /// 获取视频所在的所有容器
  Future<List<Container>> getContainersForBvid(String bvid) async {
    final ids = await (select(containerVideos)..where((cv) => cv.bvid.equals(bvid)))
        .map((cv) => cv.containerId)
        .get();
    if (ids.isEmpty) return [];
    return (select(containers)..where((c) => c.id.isIn(ids))).get();
  }

  /// 确保 "手动" 容器存在
  Future<Container> ensureManualContainer() async {
    final existing = await (select(containers)
          ..where((c) => c.type.equals('manual')))
        .getSingleOrNull();
    if (existing != null) return existing;
    final id = await into(containers).insert(
      ContainersCompanion.insert(
        type: 'manual',
        name: '手动导入',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return Container(
      id: id,
      type: 'manual',
      externalId: null,
      name: '手动导入',
      totalCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ─── UP 主 ──────────────────────────────────────────────

  /// 根据 uid 获取 UP 主 (含其容器 ID)
  Future<UpMaster?> getUpMasterByUid(int uid) =>
      (select(upMasters)..where((u) => u.uid.equals(uid))).getSingleOrNull();

  /// 获取所有 UP 主
  Future<List<UpMaster>> getAllUpMasters() =>
      (select(upMasters)..orderBy([(u) => OrderingTerm.asc(u.name)])).get();

  /// 根据 id 获取 UP 主
  Future<UpMaster?> getUpMasterById(int id) =>
      (select(upMasters)..where((u) => u.id.equals(id))).getSingleOrNull();

  /// 根据 uid 获取 UP 主容器
  Future<Container?> getUpMasterContainer(int uid) async {
    final um = await getUpMasterByUid(uid);
    if (um == null) return null;
    return getContainer(um.containerId);
  }

  /// 添加或获取 UP 主 (如果 UP 主不存在则创建)
  /// 返回 UpMaster 记录
  Future<UpMaster> addOrGetUpMaster({
    required int uid,
    required String name,
    String face = '',
  }) async {
    final existing = await getUpMasterByUid(uid);
    if (existing != null) return existing;

    // 先创建 upmaster 容器
    final containerId = await into(containers).insert(
      ContainersCompanion.insert(
        type: 'upmaster',
        externalId: Value(uid.toString()),
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrIgnore,
    );

    // 拿容器 ID (如果已存在, get container)
    int actualContainerId = containerId;
    if (containerId == 0) {
      final existingContainer = await getUpMasterContainer(uid);
      if (existingContainer != null) {
        actualContainerId = existingContainer.id;
      }
    }

    // 创建 UpMaster 记录
    final id = await into(upMasters).insert(
      UpMastersCompanion.insert(
        uid: uid,
        name: name,
        face: Value(face),
        containerId: actualContainerId,
        addedAt: DateTime.now(),
      ),
    );
    return UpMaster(
      id: id,
      uid: uid,
      name: name,
      face: face,
      lastVideoAid: null,
      lastSyncedAt: null,
      containerId: actualContainerId,
      addedAt: DateTime.now(),
    );
  }

  /// 更新 UP 主同步状态
  Future<void> updateUpMasterSync(int uid, int lastVideoAid) async {
    await (update(upMasters)..where((u) => u.uid.equals(uid))).write(
      UpMastersCompanion(
        lastVideoAid: Value(lastVideoAid),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 添加视频时也关联到 UP 主容器
  Future<void> addVideoToUpMasterContainer({
    required int upMasterId,
    required String bvid,
    DateTime? addedAt,
  }) async {
    final um = await getUpMasterById(upMasterId);
    if (um == null) return;
    await addVideoToContainer(um.containerId, bvid, addedAt: addedAt);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mikunotes.db'));
    return NativeDatabase.createInBackground(file);
  });
}
