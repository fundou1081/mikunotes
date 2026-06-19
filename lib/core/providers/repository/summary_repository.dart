import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 总结子仓库 — 从 VideoRepository 拆分
class SummaryRepository {
  final AppDatabase _db;

  SummaryRepository(this._db);

  /// 获取一个视频的所有总结
  Future<List<summary_model.Summary>> getAllSummaries(String bvid) async {
    final rows = await _db.getSummariesForVideo(bvid);
    return rows
        .map((r) => summary_model.Summary(
              id: r.id,
              videoId: r.bvid,
              title: r.title,
              type: summary_model.SummaryType.values.firstWhere(
                (t) => t.name == r.type,
                orElse: () => summary_model.SummaryType.structured,
              ),
              content: r.content,
              modelUsed: r.modelUsed,
              promptUsed: r.promptUsed,
              createdAt: r.createdAt,
              page: r.page,
            ))
        .toList();
  }

  /// 按 ID 获取总结
  Future<summary_model.Summary?> getSummary(String id) async {
    final row = await _db.getSummary(id);
    if (row == null) return null;
    return summary_model.Summary(
      id: row.id,
      videoId: row.bvid,
      title: row.title,
      type: summary_model.SummaryType.values.firstWhere(
        (t) => t.name == row.type,
        orElse: () => summary_model.SummaryType.structured,
      ),
      content: row.content,
      modelUsed: row.modelUsed,
      promptUsed: row.promptUsed,
      createdAt: row.createdAt,
      page: row.page,
    );
  }

  /// 创建总结
  Future<summary_model.Summary> createSummary({
    required String bvid,
    required String content,
    required summary_model.SummaryType type,
    required String modelUsed,
    required String promptUsed,
    String? title,
    int page = 0,
    String? targetTopic,
  }) async {
    final id = _uuid.v4();
    final autoTitle = title ?? _autoTitle(content, type);
    await _db.saveSummary(SummariesCompanion.insert(
      id: id,
      bvid: bvid,
      page: Value(page),
      title: Value(autoTitle),
      type: type.name,
      content: content,
      modelUsed: Value(modelUsed),
      promptUsed: Value(promptUsed),
      targetTopic: Value(targetTopic ?? ''),
      createdAt: DateTime.now(),
    ));
    return summary_model.Summary(
      id: id,
      videoId: bvid,
      title: autoTitle,
      type: type,
      content: content,
      modelUsed: modelUsed,
      promptUsed: promptUsed,
      createdAt: DateTime.now(),
      page: page,
    );
  }

  /// 删除总结
  Future<void> deleteSummary(String id) => _db.deleteSummary(id);

  /// 自动生成标题 (前 N 字)
  String _autoTitle(String content, summary_model.SummaryType type) {
    final firstLine = content.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => '',
        );
    final stripped = firstLine
        .replaceAll(RegExp(r'^#+\s*'), '')
        .replaceAll(RegExp(r'\*+'), '')
        .trim();
    final prefix = switch (type) {
      summary_model.SummaryType.structured => '总结',
      summary_model.SummaryType.topicExpansion => '专题',
      summary_model.SummaryType.compare => '对比',
    };
    if (stripped.isEmpty) return prefix;
    return stripped.length > 30 ? '$prefix: ${stripped.substring(0, 30)}…' : '$prefix: $stripped';
  }
}

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return SummaryRepository(ref.watch(databaseProvider));
});