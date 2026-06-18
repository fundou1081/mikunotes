import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/wiki/wiki_storage.dart';
import 'package:mikunotes/core/wiki/wiki_generator.dart';
import 'package:mikunotes/core/storage/database.dart';
import 'package:mikunotes/core/providers/providers.dart' show databaseProvider;

/// 视频在 manifest 中的元数据
class WikiVideoMeta {
    final String bvid;
    final String title;
    final String uploader;
    final int duration;
    final List<String> manualTags;
    final List<String> aiTags;
    final int summaryCount;
    final int chatCount;
    final String path;       // 相对路径, 用于后续加载
    final int sizeBytes;

    const WikiVideoMeta({
        required this.bvid,
        required this.title,
        required this.uploader,
        required this.duration,
        required this.manualTags,
        required this.aiTags,
        required this.summaryCount,
        required this.chatCount,
        required this.path,
        required this.sizeBytes,
    });

    String get allTags => [...manualTags, ...aiTags].join(', ');

    String toManifestEntry() {
        String durStr;
        if (duration <= 0) {
            durStr = '?';
        } else {
            final h = duration ~/ 3600;
            final m = (duration % 3600) ~/ 60;
            durStr = h > 0 ? '${h}h${m}m' : '${m}m';
        }
        final tags = allTags.isEmpty ? '(无标签)' : allTags;
        final stats = '$summaryCount 总结 · $chatCount 对话';
        return '- $bvid · $title · $uploader · $durStr · 📌 $tags · $stats';
    }
}

/// Wiki 上下文加载器
/// 渐进性披露:
///   L1: manifest (小, 永远在 context)
///   L2: 单个视频完整内容 (按需加载)
class WikiContextLoader {
    final AppDatabase _db;
    WikiContextLoader(this._db);

    /// 获取所有视频的 manifest (L1)
    Future<List<WikiVideoMeta>> getManifest() async {
        final groups = await _db.getAllVideoGroups();
        final result = <WikiVideoMeta>[];
        for (final g in groups) {
            final summaries = await _db.getSummariesForVideo(g.bvid);
            final sessions = await _db.getChatSessionsForVideo(g.bvid);
            final tagList = _parseTags(g.tags);
            final aiTagList = _parseTags(g.aiTags);
            result.add(WikiVideoMeta(
                bvid: g.bvid,
                title: g.title,
                uploader: g.uploader,
                duration: g.totalDuration,
                manualTags: tagList,
                aiTags: aiTagList,
                summaryCount: summaries.length,
                chatCount: sessions.fold(0, (sum, s) => sum + 1),
                path: 'videos/${g.bvid}_${_slug(g.title)}.md',
                sizeBytes: 0,
            ));
        }
        return result;
    }

    /// 生成 manifest 文本 (注入 system prompt)
    Future<String> buildManifestPrompt() async {
        final metas = await getManifest();
        if (metas.isEmpty) {
            return '用户尚未导入任何视频, Wiki 暂无内容。';
        }
        final buf = StringBuffer();
        buf.writeln('## 📚 LLM Wiki Manifest (${metas.length} 个视频)');
        buf.writeln();
        buf.writeln('这是用户的视频库概览。如果用户的问题涉及某个视频, 你**必须**先在下方用 `<need_to_read>bvid1,bvid2</need_to_read>` 标记你要加载的视频, 然后基于加载的内容回答。');
        buf.writeln();
        for (final m in metas) {
            buf.writeln(m.toManifestEntry());
        }
        buf.writeln();
        buf.writeln('---');
        buf.writeln();
        buf.writeln('## 📖 调用格式');
        buf.writeln();
        buf.writeln('要加载某个视频的完整内容, 在你的回答中输出:');
        buf.writeln('```');
        buf.writeln('<need_to_read>BV1abc123,BV2def456</need_to_read>');
        buf.writeln('```');
        buf.writeln();
        buf.writeln('系统会立即把这些视频的完整 .md 加载进 context, 然后让你基于内容回答。');
        buf.writeln();
        buf.writeln('## ⚠️ 重要原则');
        buf.writeln();
        buf.writeln('1. **不要凭空编造视频内容** — 必须先 load 才能说细节');
        buf.writeln('2. **优先精确匹配**: 用户提到的视频名/UP主/tag 直接对应 manifest 项');
        buf.writeln('3. **多选**: 一次可加载多个相关视频');
        buf.writeln('4. **如果 manifest 已足够回答** (如 "我有几个 RISC-V 视频"), 直接回答不用 load');
        return buf.toString();
    }

    /// 加载指定视频的完整 .md 内容 (L2)
    Future<Map<String, String>> loadVideoContents(List<String> bvids) async {
        final storage = WikiStorage(_db);
        final result = <String, String>{};
        for (final bvid in bvids) {
            try {
                // 找到对应的 .md 路径
                final files = await storage.listVideos();
                final file = files.firstWhere(
                    (f) => f.bvid == bvid,
                    orElse: () => WikiFileInfo(
                        bvid: bvid, title: bvid, path: '', fullPath: '',
                        modifiedAt: DateTime.now(), sizeBytes: 0,
                    ),
                );
                if (file.path.isEmpty) continue;
                final content = await File(file.fullPath).readAsString();
                result[bvid] = content;
            } catch (_) {
                // 文件不存在/读取失败, 跳过
            }
        }
        return result;
    }

    List<String> _parseTags(String raw) {
        if (raw.isEmpty) return [];
        return raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    }

    String _slug(String title) {
        return title
            .replaceAll(RegExp(r'[\s/\\:*?"<>|]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_+|_+$'), '')
            .substring(0, title.length > 50 ? 50 : title.length);
    }

    String _formatDuration(int sec) {
        if (sec <= 0) return '?';
        final h = sec ~/ 3600;
        final m = (sec % 3600) ~/ 60;
        if (h > 0) return '${h}h${m}m';
        return '${m}m';
    }
}

final wikiContextLoaderProvider = Provider<WikiContextLoader>((ref) {
    return WikiContextLoader(ref.watch(databaseProvider));
});
