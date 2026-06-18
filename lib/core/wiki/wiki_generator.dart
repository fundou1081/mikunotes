import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart' show databaseProvider;
import 'package:mikunotes/core/storage/database.dart';

/// Wiki Generator: 把 DB 数据 → Markdown 字符串
/// 纯函数 (除 IO 外), 不做文件写入 (由 WikiStorage 处理)
class WikiGenerator {
    final AppDatabase _db;
    WikiGenerator(this._db);

    /// 生成单个视频的 .md 内容
    Future<String?> generateVideoMarkdown(String bvid) async {
        final group = await _db.getVideoGroup(bvid);
        if (group == null) return null;
        final video = await (_db.select(_db.videos)
                ..where((v) => v.bvid.equals(bvid))
                ..limit(1))
            .getSingleOrNull();
        if (video == null) return null;

        final summaries = await _db.getSummariesForVideo(bvid);
        final sessions = await _db.getChatSessionsForVideo(bvid);
        final subtitles = await _db.getSubtitlesForVideo(bvid);

        // 加载所有 session 的 messages
        final messages = <String, List<ChatMessage>>{};
        for (final sess in sessions) {
            messages[sess.id] = await _db.getChatMessages(sess.id);
        }

        final buf = StringBuffer();

        // 1. Frontmatter
        buf.writeln('---');
        buf.writeln('type: video');
        buf.writeln('bvid: ${group.bvid}');
        buf.writeln('title: ${_yamlEscape(group.title)}');
        buf.writeln('uploader: ${_yamlEscape(group.uploader)}');
        if (group.cover.isNotEmpty) buf.writeln('cover: ${group.cover}');
        buf.writeln('duration: ${group.totalDuration}');
        buf.writeln('page_count: ${group.pageCount}');
        if (group.pageNamesJson.isNotEmpty && group.pageNamesJson != '[]') {
            buf.writeln('page_names: ${_yamlEscape(group.pageNamesJson)}');
        }
        buf.writeln('added_at: ${group.addedAt.toIso8601String()}');
        buf.writeln('exported_at: ${DateTime.now().toIso8601String()}');
        buf.writeln('---');
        buf.writeln();

        // 2. 标题
        buf.writeln('# ${group.title}');
        buf.writeln();
        if (group.uploader.isNotEmpty) {
            buf.writeln('> UP: **${group.uploader}** · ${_formatDuration(group.totalDuration)}');
            buf.writeln();
        }

        // 3. 标签 (重点! 用户优先看)
        buf.writeln('# 🏷️ 标签');
        buf.writeln();
        final manualTags = _parseTags(group.tags);
        final aiTags = _parseTags(group.aiTags);
        if (manualTags.isEmpty && aiTags.isEmpty) {
            buf.writeln('_(无标签)_');
        } else {
            if (manualTags.isNotEmpty) {
                buf.writeln('**手动**: ${manualTags.map((t) => '`#$t`').join(' ')}');
            }
            if (aiTags.isNotEmpty) {
                buf.writeln('**AI 提取**: ${aiTags.map((t) => '`#$t`').join(' ')}');
            }
        }
        buf.writeln();
        buf.writeln('---');
        buf.writeln();

        // 4. AI 总结
        buf.writeln('# 📝 AI 总结 (${summaries.length} 次)');
        buf.writeln();
        if (summaries.isEmpty) {
            buf.writeln('_(暂无总结)_');
        } else {
            for (final s in summaries) {
                final typeStr = s.type == 'structured' ? '结构化' : '自定义';
                buf.writeln('## ${s.createdAt.toIso8601String().substring(0, 19).replaceFirst("T", " ")} · ${typeStr}');
                buf.writeln();
                if (s.targetTopic != null && s.targetTopic!.isNotEmpty) {
                    buf.writeln('**话题**: ${s.targetTopic}');
                    buf.writeln();
                }
                buf.writeln(s.content);
                buf.writeln();
                buf.writeln('---');
                buf.writeln();
            }
        }

        // 5. 对话记录
        final totalMessages = messages.values.fold<int>(0, (sum, list) => sum + list.length);
        buf.writeln('# 💬 对话记录 (${totalMessages} 条, ${sessions.length} 个 session)');
        buf.writeln();
        if (sessions.isEmpty) {
            buf.writeln('_(暂无对话)_');
        } else {
            for (final sess in sessions) {
                buf.writeln('## Session #${sess.id} · ${sess.title} · ${sess.createdAt.toIso8601String().substring(0, 16).replaceFirst("T", " ")}');
                buf.writeln();
                final msgs = messages[sess.id] ?? [];
                for (final m in msgs) {
                    final role = m.role == 'user' ? '👤 用户' : '🤖 AI';
                    buf.writeln('**$role** · ${m.timestamp.toIso8601String().substring(11, 16)}');
                    buf.writeln();
                    buf.writeln(m.content);
                    buf.writeln();
                }
                buf.writeln('---');
                buf.writeln();
            }
        }

        // 6. 字幕 (仅前 30 行摘要)
        buf.writeln('# 📄 字幕摘要 (前 30 行)');
        buf.writeln();
        if (subtitles.isEmpty) {
            buf.writeln('_(无字幕)_');
        } else {
            buf.writeln('> 完整字幕请查看 B 站原视频');
            buf.writeln();
            final sub = subtitles.first;
            buf.writeln('**页码**: ${sub.page} · **语言**: ${sub.language} · **总字符**: ${sub.charCount}');
            buf.writeln();
            buf.writeln('```');
            final lines = sub.plainText.split('\n').take(30);
            for (final line in lines) {
                buf.writeln(line);
            }
            buf.writeln('```');
            buf.writeln();
        }

        return buf.toString();
    }

    /// 生成 index.md
    Future<String> generateIndexMarkdown() async {
        final groups = await _db.getAllVideoGroups();
        final buf = StringBuffer();

        buf.writeln('# MikuNotes Wiki 索引');
        buf.writeln();
        buf.writeln('> 共 ${groups.length} 个视频 · 最后更新 ${DateTime.now().toIso8601String().substring(0, 19).replaceFirst("T", " ")}');
        buf.writeln();
        buf.writeln('---');
        buf.writeln();

        // 按日期分组
        final byDate = <String, List<VideoGroup>>{};
        for (final g in groups) {
            final date = g.addedAt.toIso8601String().substring(0, 10);
            byDate.putIfAbsent(date, () => []).add(g);
        }
        final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

        for (final date in dates) {
            buf.writeln('## 📅 $date (${byDate[date]!.length} 个)');
            buf.writeln();
            for (final g in byDate[date]!) {
                final dur = _formatDuration(g.totalDuration);
                final up = g.uploader.isEmpty ? '未知 UP' : g.uploader;
                buf.writeln('- **${g.bvid}** · ${g.title} — ${up} · ${dur}');
            }
            buf.writeln();
        }

        // 标签统计
        final tagCount = <String, int>{};
        for (final g in groups) {
            for (final t in [..._parseTags(g.tags), ..._parseTags(g.aiTags)]) {
                tagCount[t] = (tagCount[t] ?? 0) + 1;
            }
        }
        if (tagCount.isNotEmpty) {
            buf.writeln('## 🏷️ 标签统计');
            buf.writeln();
            final sorted = tagCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
            for (final e in sorted.take(30)) {
                buf.writeln('- `#${e.key}` — ${e.value} 个视频');
            }
            buf.writeln();
        }

        return buf.toString();
    }

    /// 解析逗号分隔的 tags 字符串
    List<String> _parseTags(String raw) {
        if (raw.isEmpty) return [];
        return raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    }

    /// YAML 转义
    String _yamlEscape(String s) {
        if (s.contains(':') || s.contains('#') || s.contains('"') || s.contains("'")) {
            return '"${s.replaceAll('"', '\\"')}"';
        }
        return s;
    }

    /// 时长格式化
    String _formatDuration(int sec) {
        if (sec <= 0) return '未知时长';
        final h = sec ~/ 3600;
        final m = (sec % 3600) ~/ 60;
        final s = sec % 60;
        if (h > 0) return '${h}:${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}';
        return '${m}:${s.toString().padLeft(2, "0")}';
    }
}

final wikiGeneratorProvider = Provider<WikiGenerator>((ref) {
    return WikiGenerator(ref.watch(databaseProvider));
});
