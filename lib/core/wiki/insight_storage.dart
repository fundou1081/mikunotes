import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/wiki/wiki_storage.dart';
import 'package:mikunotes/core/storage/database.dart';
import 'package:mikunotes/core/providers/providers.dart' show databaseProvider;

/// 跨视频洞察的元数据
class InsightFileInfo {
    final String id;          // 文件名 (不含 .md)
    final String title;       // 标题 (从 frontmatter)
    final String path;        // 相对路径
    final String fullPath;    // 绝对路径
    final DateTime createdAt;
    final int sizeBytes;
    final List<String> videoBvids;  // 涉及的 BVID 列表 (从 frontmatter)

    const InsightFileInfo({
        required this.id,
        required this.title,
        required this.path,
        required this.fullPath,
        required this.createdAt,
        required this.sizeBytes,
        required this.videoBvids,
    });
}

/// 跨视频洞察存储 — 写到 wiki/insights/
class InsightStorage {
    final AppDatabase _db;
    InsightStorage(this._db);

    /// insights 子目录
    Future<String> get _insightsDir async {
        final root = await WikiStorage(_db).wikiDir;
        final dir = Directory('$root/insights');
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir.path;
    }

    /// 保存跨视频洞察
    /// - id: 文件名 (date_title)
    /// - content: 完整 .md (含 frontmatter)
    Future<String> save(String id, String content) async {
        final dir = await _insightsDir;
        final file = File('$dir/$id.md');
        await file.writeAsString(content, encoding: const SystemEncoding());
        return file.path;
    }

    /// 列出所有洞察
    Future<List<InsightFileInfo>> list() async {
        final dir = Directory(await _insightsDir);
        if (!await dir.exists()) return [];
        final files = <InsightFileInfo>[];
        await for (final entity in dir.list()) {
            if (entity is! File || !entity.path.endsWith('.md')) continue;
            final stat = await entity.stat();
            final name = entity.path.split('/').last;
            // 解析 frontmatter
            String title = name;
            List<String> bvids = [];
            try {
                final text = await entity.readAsString();
                final m = RegExp(r'^---\n(.*?)\n---', multiLine: true, dotAll: true).firstMatch(text);
                if (m != null) {
                    final fm = m.group(1)!;
                    final titleM = RegExp(r'^title:\s*"?(.+?)"?\s*$', multiLine: true).firstMatch(fm);
                    if (titleM != null) title = titleM.group(1)!;
                    // bvids 字段是 JSON list
                    final bvidsM = RegExp(r'^bvids:\s*\[(.*?)\]', multiLine: true).firstMatch(fm);
                    if (bvidsM != null) {
                        bvids = bvidsM.group(1)!
                            .split(',')
                            .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
                            .where((s) => s.startsWith('BV'))
                            .toList();
                    }
                }
            } catch (_) {}
            files.add(InsightFileInfo(
                id: name.replaceAll('.md', ''),
                title: title,
                path: 'insights/$name',
                fullPath: entity.path,
                createdAt: stat.modified,
                sizeBytes: stat.size,
                videoBvids: bvids,
            ));
        }
        files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return files;
    }

    /// 读取洞察
    Future<String> read(String id) async {
        final dir = await _insightsDir;
        return File('$dir/$id.md').readAsString();
    }

    /// 删除洞察
    Future<void> delete(String id) async {
        final dir = await _insightsDir;
        final file = File('$dir/$id.md');
        if (await file.exists()) await file.delete();
    }
}

final insightStorageProvider = Provider<InsightStorage>((ref) {
    return InsightStorage(ref.watch(databaseProvider));
});
