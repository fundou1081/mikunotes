import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart' show databaseProvider;
import 'package:mikunotes/core/storage/database.dart';

/// Wiki 文件信息
class WikiFileInfo {
    final String bvid;
    final String title;
    final String path;          // 相对路径 (相对于 wikiDir)
    final String fullPath;      // 绝对路径
    final DateTime modifiedAt;
    final int sizeBytes;

    const WikiFileInfo({
        required this.bvid,
        required this.title,
        required this.path,
        required this.fullPath,
        required this.modifiedAt,
        required this.sizeBytes,
    });
}

/// Wiki 文件存储
/// - 写 .md 到: <app-files>/Documents/MikuNotes_wiki/
/// - 读取/列出由 WikiGenerator 生成内容, WikiStorage 只做文件 IO
class WikiStorage {
    final AppDatabase _db;
    WikiStorage(this._db);

    /// Wiki 根目录
    /// 写到 /Android/data/.../files/Documents/MikuNotes_wiki/ (可读可写, FileManager可见)
    Future<String> get wikiDir async {
        final ext = await getExternalStorageDirectory();
        if (ext == null) {
            throw FileSystemException('无法获取外部存储目录');
        }
        // ext = /Android/data/com.app/files → Documents 下的 MikuNotes_wiki
        final dir = Directory('${ext.path}/Documents/MikuNotes_wiki');
        if (!await dir.exists()) await dir.create(recursive: true);
        final videosDir = Directory('${dir.path}/videos');
        if (!await videosDir.exists()) await videosDir.create(recursive: true);
        return dir.path;
    }

    /// 视频 .md 子目录
    Future<String> get _videosDir async {
        final root = await wikiDir;
        return '$root/videos';
    }

    /// 写任意相对路径文件
    Future<String> writeFile(String relativePath, String content) async {
        final root = await wikiDir;
        final full = '$root/$relativePath';
        final file = File(full);
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
        return full;
    }

    /// 写视频 .md (含标题 slug)
    Future<String> writeVideoMarkdown(String bvid, String title, String content) async {
        final slug = _slugify(title);
        final filename = '${bvid}_${slug.isEmpty ? "untitled" : slug}.md';
        final rel = 'videos/$filename';
        return writeFile(rel, content);
    }

    /// 读取文件
    Future<String> readFile(String relativePath) async {
        final root = await wikiDir;
        return File('$root/$relativePath').readAsString();
    }

    /// 列出所有视频 .md
    Future<List<WikiFileInfo>> listVideos() async {
        final dir = Directory(await _videosDir);
        if (!await dir.exists()) return [];
        final files = <WikiFileInfo>[];
        await for (final entity in dir.list()) {
            if (entity is! File) continue;
            if (!entity.path.endsWith('.md')) continue;
            final stat = await entity.stat();
            final name = entity.path.split('/').last;
            // 解析 BV 号和标题: BVxxxxxxxxx_标题.md
            final match = RegExp(r'^(BV[a-zA-Z0-9]+)_(.+)\.md$').firstMatch(name);
            final bvid = match?.group(1) ?? name;
            final title = match?.group(2) ?? name;
            files.add(WikiFileInfo(
                bvid: bvid,
                title: title,  // 不过 URL decode, slug 是中文不要转义
                path: 'videos/$name',
                fullPath: entity.path,
                modifiedAt: stat.modified,
                sizeBytes: stat.size,
            ));
        }
        files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
        return files;
    }

    /// 标题 → 文件名安全的 slug
    String _slugify(String title) {
        return title
            .replaceAll(RegExp(r'[\s/\\:*?"<>|]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_+|_+$'), '')
            .substring(0, title.length > 50 ? 50 : title.length);
    }
}

final wikiStorageProvider = Provider<WikiStorage>((ref) {
    return WikiStorage(ref.watch(databaseProvider));
});
