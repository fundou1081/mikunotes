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
  TextColumn get tags => text().withDefault(const Constant(''))(); // comma-separated

  @override
  Set<Column> get primaryKey => {bvid};
}

/// 字幕表 (一对多: 一个视频有多个分P/语言)
class Subtitles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bvid => text()();
  IntColumn get pageNum => integer().withDefault(const Constant(1))();
  TextColumn get language => text()();
  TextColumn get rawJson => text()(); // B站原始 JSON
  TextColumn get plainText => text()(); // 提取后的纯文本
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
  TextColumn get type => text()(); // structured / topicExpansion / compare
  TextColumn get content => text()();
  TextColumn get modelUsed => text().withDefault(const Constant(''))();
  TextColumn get promptUsed => text().withDefault(const Constant(''))();
  TextColumn get targetTopic => text().withDefault(const Constant(''))(); // for topicExpansion
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 对话历史
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get bvid => text()();
  TextColumn get role => text()(); // user / assistant / system
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime()();
}

/// 收藏/标签关联
class VideoTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bvid => text()();
  TextColumn get tag => text()();

  @override
  List<Set<Column>> get uniqueKeys => [{bvid, tag}];
}

@DriftDatabase(tables: [Videos, Subtitles, Summaries, ChatMessages, VideoTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );

  // ─── 视频操作 ──────────────────────────────────────────────

  Future<List<Video>> getAllVideos() => (select(videos)..orderBy([(v) => OrderingTerm.desc(v.addedAt)])).get();

  Future<Video?> getVideo(String bvid) =>
      (select(videos)..where((v) => v.bvid.equals(bvid))).getSingleOrNull();

  Future<void> upsertVideo(VideosCompanion v) => into(videos).insertOnConflictUpdate(v);

  Future<void> deleteVideo(String bvid) async {
    await (delete(subtitles)..where((s) => s.bvid.equals(bvid))).go();
    await (delete(summaries)..where((s) => s.bvid.equals(bvid))).go();
    await (delete(chatMessages)..where((m) => m.bvid.equals(bvid))).go();
    await (delete(videoTags)..where((t) => t.bvid.equals(bvid))).go();
    await (delete(videos)..where((v) => v.bvid.equals(bvid))).go();
  }

  // ─── 字幕操作 ──────────────────────────────────────────────

  Future<List<Subtitle>> getSubtitlesForVideo(String bvid) =>
      (select(subtitles)..where((s) => s.bvid.equals(bvid))).get();

  Future<void> upsertSubtitle(SubtitlesCompanion s) => into(subtitles).insertOnConflictUpdate(s);

  // ─── 总结操作 ──────────────────────────────────────────────

  Future<List<Summary>> getSummariesForVideo(String bvid) =>
      (select(summaries)..where((s) => s.bvid.equals(bvid))).get();

  Future<void> saveSummary(SummariesCompanion s) => into(summaries).insertOnConflictUpdate(s);

  // ─── 对话操作 ──────────────────────────────────────────────

  Future<List<ChatMessageData>> getChatHistory(String bvid) =>
      (select(chatMessages)
            ..where((m) => m.bvid.equals(bvid))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .get();

  Future<void> saveChatMessage(ChatMessagesCompanion m) => into(chatMessages).insert(m);

  // ─── 标签 ──────────────────────────────────────────────

  Future<List<String>> getAllTags() async {
    final all = await select(videoTags).get();
    return all.map((t) => t.tag).toSet().toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mikunotes.db'));
    return NativeDatabase.createInBackground(file);
  });
}
