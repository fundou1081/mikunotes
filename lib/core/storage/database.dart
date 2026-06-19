import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// 视频组表 (B站一个视频 = 一个视频组)
/// 所有"视频元信息" (标题/封面/UP主/标签) 都在这里
class VideoGroups extends Table {
  TextColumn get bvid => text()();
  TextColumn get title => text()();
  TextColumn get cover => text().withDefault(const Constant(''))();
  TextColumn get uploader => text().withDefault(const Constant(''))();
  IntColumn get upMid => integer().withDefault(const Constant(0))();
  TextColumn get upFace => text().withDefault(const Constant(''))();
  IntColumn get totalDuration => integer().withDefault(const Constant(0))(); // 所有 P 累计时长
  IntColumn get pageCount => integer().withDefault(const Constant(1))();
  TextColumn get pageNamesJson => text().withDefault(const Constant('[]'))(); // JSON 列表
  DateTimeColumn get addedAt => dateTime()();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get aiTags => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {bvid};
}

/// 分P表 (一个视频组至少有 1 个 P, 多 P 时有多行)
class Videos extends Table {
  TextColumn get bvid => text()();
  IntColumn get page => integer()();
  IntColumn get aid => integer()();
  IntColumn get cid => integer().withDefault(const Constant(0))(); // 字幕 cid (P 唯一)
  TextColumn get partName => text().withDefault(const Constant(''))(); // B站返回的 part 名称
  TextColumn get partTitle => text().withDefault(const Constant(''))(); // 该 P 单独标题
  TextColumn get partCover => text().withDefault(const Constant(''))(); // 该 P 单独封面
  IntColumn get duration => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {bvid, page};
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

/// 字幕表 (一个视频某个 P 可有多语言)
class Subtitles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bvid => text()();
  IntColumn get page => integer().withDefault(const Constant(1))();
  TextColumn get language => text()();
  TextColumn get rawJson => text()();
  TextColumn get plainText => text()();
  IntColumn get charCount => integer().withDefault(const Constant(0))();
  IntColumn get entryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {bvid, page, language}
      ];
}

/// 总结表 (按 (bvid, page) 关联, page=0 表示整体总结)
class Summaries extends Table {
  TextColumn get id => text()();
  TextColumn get bvid => text()();
  IntColumn get page => integer().withDefault(const Constant(0))(); // 0=整体, 1+第N部分
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

/// 评论表 (按 (bvid, page) 分P存, 跟 Videos 一致)
class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bvid => text()();
  IntColumn get page => integer().withDefault(const Constant(1))();
  IntColumn get aid => integer()();
  IntColumn get rpid => integer()();  // B 站评论 ID
  TextColumn get uname => text()();
  TextColumn get content => text()();
  IntColumn get likes => integer().withDefault(const Constant(0))();
  IntColumn get rcount => integer().withDefault(const Constant(0))();  // 回复数
  IntColumn get parent => integer().nullable()();  // 父评论 (子评论)
  DateTimeColumn get ctime => dateTime()();  // 评论时间
  TextColumn get fetchedMode => text().withDefault(const Constant('latest'))();  // latest / random / firstN
}

/// 弹幕表 (按 (bvid, page) 分P存)
class Danmaku extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bvid => text()();
  IntColumn get page => integer().withDefault(const Constant(1))();
  IntColumn get cid => integer()();  // 弹幕的 cid (一般跟字幕 cid 一样)
  IntColumn get progress => integer()();  // 出现时间 (ms) — 关键字段
  IntColumn get time => integer()();  // 发送时间 (unix)
  TextColumn get content => text()();
  IntColumn get color => integer().withDefault(const Constant(0xffffff))();
  TextColumn get fetchedMode => text().withDefault(const Constant('firstN'))();
}

@DriftDatabase(
  tables: [VideoGroups, Videos, UpMasters, Subtitles, Summaries, ChatSessions, ChatMessages, Containers, ContainerVideos, Comments, Danmaku],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

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
            // v3: 加 aiTags 字段到 Videos (列已移除, 用 raw SQL)
            await customStatement(
                'ALTER TABLE videos ADD COLUMN ai_tags TEXT NOT NULL DEFAULT ""');
          }
          if (from < 4) {
            // v4: 加 containers + container_videos 表, 迁移老视频到 manual 容器
            await m.createTable(containers);
            await m.createTable(containerVideos);
            await _migrateOldVideosToManual();
          }
          if (from < 5) {
            // v5: 加 upmasters 表 + videos.upMid 列
            // upMid 列已从 Videos 表移除, 用 raw SQL
            await customStatement(
                'ALTER TABLE videos ADD COLUMN up_mid INTEGER NOT NULL DEFAULT 0');
            await m.createTable(upMasters);
          }
          if (from < 6) {
            // v6: 视频组分P 改造
            // 1. 创建 video_groups 表
            await m.createTable(videoGroups);
            // 2. 老 videos 表重命名 (保留数据)
            await customStatement('ALTER TABLE videos RENAME TO _videos_v5');
            // 3. 创建新 videos 表 (复合主键 bvid+page)
            await customStatement('''
              CREATE TABLE videos (
                bvid TEXT NOT NULL,
                page INTEGER NOT NULL,
                aid INTEGER NOT NULL,
                cid INTEGER NOT NULL DEFAULT 0,
                part_name TEXT NOT NULL DEFAULT '',
                part_title TEXT NOT NULL DEFAULT '',
                part_cover TEXT NOT NULL DEFAULT '',
                duration INTEGER NOT NULL DEFAULT 0,
                added_at INTEGER NOT NULL,
                PRIMARY KEY (bvid, page)
              )
            ''');
            // 4. 从老数据迁移到 video_groups + 新 videos
            await customStatement('''
              INSERT INTO video_groups (bvid, title, cover, uploader, up_mid, up_face,
                                        total_duration, page_count, page_names_json,
                                        added_at, tags, ai_tags)
              SELECT bvid, title, cover_url, uploader, up_mid, '',
                     duration, page_count, '[]', added_at, tags, ai_tags
              FROM _videos_v5
            ''');
            await customStatement('''
              INSERT INTO videos (bvid, page, aid, cid, part_name, part_title,
                                  part_cover, duration, added_at)
              SELECT bvid, 1, aid, 0, '', title, cover_url, duration, added_at
              FROM _videos_v5
            ''');
            // 5. subtitles: pageNum -> page 重命名
            await customStatement('ALTER TABLE subtitles RENAME COLUMN page_num TO page');
            // 6. summaries: 加 page 列
            await customStatement('ALTER TABLE summaries ADD COLUMN page INTEGER NOT NULL DEFAULT 0');
            // 7. 删除老表
            await customStatement('DROP TABLE _videos_v5');
          }
          if (from < 7) {
            // v7: 加 Comments + Danmaku 表 (底层数据扩展)
            await m.createTable(comments);
            await m.createTable(danmaku);
          }
        },
      );

  /// 获取视频组
  Future<VideoGroup?> getVideoGroup(String bvid) =>
      (select(videoGroups)..where((g) => g.bvid.equals(bvid))).getSingleOrNull();

  /// 获取所有视频组
  Future<List<VideoGroup>> getAllVideoGroups() =>
      (select(videoGroups)..orderBy([(g) => OrderingTerm.desc(g.addedAt)])).get();

  /// v4 migration: 将老视频全部归到 manual 容器
  Future<void> _migrateOldVideosToManual() async {
    final manualId = await _ensureManualContainer();
    // Use raw SQL since the old videos table may have different columns
    // than the current schema (v6). The addColumn for upMid/aiTags in
    // previous migrations already ran.
    final result = await customSelect(
      'SELECT bvid, added_at FROM videos',
      readsFrom: {videos},
    ).get();
    for (final row in result) {
      final bvid = row.data['bvid'] as String;
      final addedAt = row.data['added_at'] as int? ?? 0;
      await into(containerVideos).insert(
        ContainerVideosCompanion.insert(
          containerId: manualId,
          bvid: bvid,
          addedAt: DateTime.fromMillisecondsSinceEpoch(addedAt),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// 获取视频组


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

  /// 插入/更新视频组 (insert or replace)
  Future<void> insertVideoGroup(VideoGroupsCompanion group) =>
      into(videoGroups).insert(group, mode: InsertMode.insertOrReplace);

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
    // 删除容器关联 (避免孤儿引用导致计数不一致)
    await (delete(containerVideos)..where((cv) => cv.bvid.equals(bvid))).go();
    await (delete(videos)..where((v) => v.bvid.equals(bvid))).go();
  }

  // ─── 评论 ──────────────────────────────────────────────

  Future<List<Comment>> getCommentsForVideo(String bvid, {int? page}) {
    final q = select(comments)..where((c) => c.bvid.equals(bvid));
    if (page != null) {
      q.where((c) => c.page.equals(page));
    }
    return (q..orderBy([(c) => OrderingTerm.desc(c.likes)])).get();
  }

  Future<int> getCommentCount(String bvid) async {
    final count = countAll(filter: comments.bvid.equals(bvid));
    final row = await (selectOnly(comments)..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> insertComments(List<CommentsCompanion> items) async {
    await batch((b) {
      b.insertAll(comments, items);
    });
  }

  Future<void> clearComments(String bvid, {int? page}) async {
    final q = delete(comments)..where((c) => c.bvid.equals(bvid));
    if (page != null) q.where((c) => c.page.equals(page));
    await q.go();
  }

  // ─── 弹幕 ──────────────────────────────────────────────

  Future<List<DanmakuData>> getDanmakuForVideo(String bvid, {int? page}) {
    final q = select(danmaku)..where((d) => d.bvid.equals(bvid));
    if (page != null) {
      q.where((d) => d.page.equals(page));
    }
    return (q..orderBy([(d) => OrderingTerm.asc(d.progress)])).get();
  }

  Future<int> getDanmakuCount(String bvid) async {
    final count = countAll(filter: danmaku.bvid.equals(bvid));
    final row = await (selectOnly(danmaku)..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> insertDanmaku(List<DanmakuCompanion> items) async {
    await batch((b) {
      b.insertAll(danmaku, items);
    });
  }

  Future<void> clearDanmaku(String bvid, {int? page}) async {
    final q = delete(danmaku)..where((d) => d.bvid.equals(bvid));
    if (page != null) q.where((d) => d.page.equals(page));
    await q.go();
  }

  // ─── 字幕 ──────────────────────────────────────────────

  Future<List<Subtitle>> getSubtitlesForVideo(String bvid) =>
      (select(subtitles)..where((s) => s.bvid.equals(bvid))).get();

  Future<Subtitle?> getSubtitle(String bvid, int pageNum, String lang) =>
      (select(subtitles)
            ..where((s) =>
                s.bvid.equals(bvid) &
                s.page.equals(pageNum) &
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
