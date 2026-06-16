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
  IntColumn get aid => integer()();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  IntColumn get pageCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get addedAt => dateTime()();
  TextColumn get tags => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {bvid};
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

@DriftDatabase(
  tables: [Videos, Subtitles, Summaries, ChatSessions, ChatMessages],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: 新增 title 字段到 Summaries, 加 ChatSessions 表
            await m.addColumn(summaries, summaries.title);
            await m.createTable(chatSessions);
            // ChatMessages: 加 sessionId, isCompressed
            await m.addColumn(chatMessages, chatMessages.sessionId);
            await m.addColumn(chatMessages, chatMessages.isCompressed);
          }
        },
      );

  // ─── 视频 ──────────────────────────────────────────────

  Future<List<Video>> getAllVideos() =>
      (select(videos)..orderBy([(v) => OrderingTerm.desc(v.addedAt)])).get();

  Future<Video?> getVideo(String bvid) =>
      (select(videos)..where((v) => v.bvid.equals(bvid))).getSingleOrNull();

  Future<void> upsertVideo(VideosCompanion v) =>
      into(videos).insertOnConflictUpdate(v);

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mikunotes.db'));
    return NativeDatabase.createInBackground(file);
  });
}
