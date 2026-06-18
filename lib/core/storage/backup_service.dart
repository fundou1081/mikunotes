import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:mikunotes/core/storage/database.dart' hide Video;
import 'package:path_provider/path_provider.dart';

/// 备份/恢复服务 — 数据导出到用户可访问目录，重装不丢失
class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  static Future<String> get backupDir async {
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final dir = Directory('${ext.path}/MikuNotes_backups');
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir.path;
      }
    } catch (_) {}
    // Fallback to app-internal
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// 系统下载目录备份路径 (公共 Download 目录, 非 app 私有)
  static Future<String?> get downloadsBackupDir async {
    try {
      // getDownloadsDirectory 返回 app-private 路径 → 不用
      // 从 getExternalStorageDirectory 反推到公共 Download
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        // ext = /storage/emulated/0/Android/data/com.app/files
        // 反推: /storage/emulated/0/Download/MikuNotes_backups/
        final extRoot = ext.path.split('Android')[0];
        final dir = Directory('${extRoot}Download/MikuNotes_backups');
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir.path;
      }
    } catch (_) {}
    return null;
  }

  /// 检查是否有备份文件
  static Future<List<String>> listBackups() async {
    final dir = Directory(await backupDir);
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.path)
        .toList();
    files.sort((a, b) => b.compareTo(a)); // 最新在前
    return files;
  }

  /// 检查下载目录备份
  static Future<List<String>> listBackupsInDownloads() async {
    final dir = await downloadsBackupDir;
    if (dir == null) return [];
    final d = Directory(dir);
    if (!await d.exists()) return [];
    final files = await d
        .list()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.path)
        .toList();
    files.sort((a, b) => b.compareTo(a));
    return files;
  }

  /// 导出全部数据到默认备份目录
  Future<String> exportAll() async {
    return exportTo(await backupDir);
  }

  /// 导出到系统下载目录
  Future<String?> exportToDownloads() async {
    final dir = await downloadsBackupDir;
    if (dir == null) return null;
    return exportTo(dir);
  }

  /// 导出到指定目录
  Future<String> exportTo(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .substring(0, 19);

    // 1. 读取所有数据
    final videoRows = await _db.getAllVideos();
    final allSubtitles = <Map<String, dynamic>>[];
    final allSummaries = <Map<String, dynamic>>[];
    final allSessions = <Map<String, dynamic>>[];
    final allMessages = <Map<String, dynamic>>[];

    // JOIN video_groups 拿 title/cover/uploader/pageCount/pageNames
    final videos = <Map<String, dynamic>>[];
    for (final v in videoRows) {
      final g = await _db.getVideoGroup(v.bvid);
      videos.add({
        'bvid': v.bvid,
        'page': v.page,
        'aid': v.aid,
        'duration': v.duration,
        'addedAt': v.addedAt.toIso8601String(),
        'title': g?.title ?? v.bvid,
        'cover': g?.cover ?? '',
        'uploader': g?.uploader ?? '',
        'pageCount': g?.pageCount ?? 1,
        'pageNamesJson': g?.pageNamesJson ?? '[]',
      });
    }

    for (final v in videos) {
      final bvid = v['bvid'] as String;
      final subs = await _db.getSubtitlesForVideo(bvid);
      for (final s in subs) {
        allSubtitles.add({
          'bvid': s.bvid,
          'pageNum': s.page,
          'language': s.language,
          'rawJson': s.rawJson,
          'plainText': s.plainText,
          'charCount': s.charCount,
          'entryCount': s.entryCount,
          'downloadedAt': s.downloadedAt.toIso8601String(),
        });
      }

      final summaries = await _db.getSummariesForVideo(bvid);
      for (final s in summaries) {
        allSummaries.add({
          'id': s.id,
          'bvid': s.bvid,
          'title': s.title,
          'type': s.type,
          'content': s.content,
          'modelUsed': s.modelUsed,
          'promptUsed': s.promptUsed,
          'targetTopic': s.targetTopic,
          'createdAt': s.createdAt.toIso8601String(),
        });
      }

      final sessions = await _db.getChatSessionsForVideo(bvid);
      for (final sess in sessions) {
        allSessions.add({
          'id': sess.id,
          'bvid': sess.bvid,
          'title': sess.title,
          'createdAt': sess.createdAt.toIso8601String(),
          'lastActiveAt': sess.lastActiveAt.toIso8601String(),
        });
        final msgs = await _db.getChatMessages(sess.id);
        for (final m in msgs) {
          allMessages.add({
            'id': m.id,
            'sessionId': m.sessionId,
            'role': m.role,
            'content': m.content,
            'timestamp': m.timestamp.toIso8601String(),
            'isCompressed': m.isCompressed,
          });
        }
      }
    }

    final backup = {
      'version': 2,
      'app': 'mikunotes',
      'exported_at': DateTime.now().toIso8601String(),
      'video_count': videos.length,
      'subtitle_count': allSubtitles.length,
      'summary_count': allSummaries.length,
      'session_count': allSessions.length,
      'message_count': allMessages.length,
      'videos': videos
          .map((v) => {
                'bvid': v['bvid'],
                'page': v['page'],
                'aid': v['aid'],
                'duration': v['duration'],
                'addedAt': v['addedAt'],
                'title': v['title'],
                'cover': v['cover'],
                'uploader': v['uploader'],
                'pageCount': v['pageCount'],
                'pageNamesJson': v['pageNamesJson'],
              })
          .toList(),
      'subtitles': allSubtitles,
      'summaries': allSummaries,
      'chat_sessions': allSessions,
      'chat_messages': allMessages,
    };

    final path = '${dir.path}/mikunotes_backup_$timestamp.json';
    final file = File(path);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backup));
    return path;
  }

  /// 从备份文件恢复数据
  Future<BackupRestoreResult> restoreFrom(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return BackupRestoreResult(
        success: false,
        error: '文件不存在: $filePath',
      );
    }

    try {
      final raw = await file.readAsString();
      final backup = jsonDecode(raw) as Map<String, dynamic>;

      final version = backup['version'] as int? ?? 1;

      int videoCount = 0;
      int subtitleCount = 0;
      int summaryCount = 0;
      int sessionCount = 0;
      int messageCount = 0;

      // 恢复视频 (video_groups + videos)
      final videos = backup['videos'] as List? ?? [];
      for (final v in videos.cast<Map<String, dynamic>>()) {
        try {
          final bvid = v['bvid'] as String;
          final addedAt = DateTime.parse(v['addedAt'] as String);
          final aid = (v['aid'] as num?)?.toInt() ?? 0;
          final duration = (v['duration'] as num?)?.toInt() ?? 0;
          final page = (v['page'] as num?)?.toInt() ?? 1;
          // v2 格式带 title/cover/uploader/pageCount/pageNamesJson
          final title = (v['title'] as String?) ?? bvid;
          final cover = (v['cover'] as String?) ?? (v['coverUrl'] as String?) ?? '';
          final uploader = (v['uploader'] as String?) ?? '';
          final pageCount = (v['pageCount'] as num?)?.toInt() ?? 1;
          final pageNamesJson = (v['pageNamesJson'] as String?) ?? '[]';

          // Insert video_group
          await _db.insertVideoGroup(VideoGroupsCompanion.insert(
            bvid: bvid,
            title: title,
            cover: Value(cover),
            uploader: Value(uploader),
            totalDuration: Value(duration),
            pageCount: Value(pageCount),
            pageNamesJson: Value(pageNamesJson),
            addedAt: addedAt,
          ));
          // Insert video (page=1 for old backups)
          await _db.upsertVideo(VideosCompanion.insert(
            bvid: bvid,
            page: page,
            aid: aid,
            cid: Value(0),
            duration: Value(duration),
            addedAt: addedAt,
          ));
          videoCount++;
        } catch (_) {}
      }

      // 恢复字幕
      final subtitles = backup['subtitles'] as List? ?? [];
      for (final s in subtitles.cast<Map<String, dynamic>>()) {
        try {
          await _db.upsertSubtitle(SubtitlesCompanion(
            id: const Value.absent(),
            bvid: Value(s['bvid'] as String),
            page: Value((s['pageNum'] as num?)?.toInt() ?? 1),
            language: Value(s['language'] as String),
            rawJson: Value(s['rawJson'] as String),
            plainText: Value(s['plainText'] as String),
            charCount: Value((s['charCount'] as num?)?.toInt() ?? 0),
            entryCount: Value((s['entryCount'] as num?)?.toInt() ?? 0),
            downloadedAt: Value(DateTime.parse(s['downloadedAt'] as String)),
          ));
          subtitleCount++;
        } catch (_) {}
      }

      // 恢复总结
      final summaries = backup['summaries'] as List? ?? [];
      for (final s in summaries.cast<Map<String, dynamic>>()) {
        try {
          await _db.saveSummary(SummariesCompanion(
            id: Value(s['id'] as String),
            bvid: Value(s['bvid'] as String),
            title: Value((s['title'] as String?) ?? ''),
            type: Value(s['type'] as String),
            content: Value(s['content'] as String),
            modelUsed: Value((s['modelUsed'] as String?) ?? ''),
            promptUsed: Value((s['promptUsed'] as String?) ?? ''),
            targetTopic: Value((s['targetTopic'] as String?) ?? ''),
            createdAt: Value(DateTime.parse(s['createdAt'] as String)),
          ));
          summaryCount++;
        } catch (_) {}
      }

      // 恢复对话会话
      final sessions = backup['chat_sessions'] as List? ?? [];
      for (final s in sessions.cast<Map<String, dynamic>>()) {
        try {
          await _db.saveChatSession(ChatSessionsCompanion(
            id: Value(s['id'] as String),
            bvid: Value(s['bvid'] as String),
            title: Value((s['title'] as String?) ?? '新对话'),
            createdAt: Value(DateTime.parse(s['createdAt'] as String)),
            lastActiveAt: Value(DateTime.parse(s['lastActiveAt'] as String)),
          ));
          sessionCount++;
        } catch (_) {}
      }

      // 恢复对话消息
      final messages = backup['chat_messages'] as List? ?? [];
      for (final m in messages.cast<Map<String, dynamic>>()) {
        try {
          await _db.saveChatMessage(ChatMessagesCompanion(
            id: Value(m['id'] as String),
            sessionId: Value(m['sessionId'] as String),
            role: Value(m['role'] as String),
            content: Value(m['content'] as String),
            timestamp: Value(DateTime.parse(m['timestamp'] as String)),
            isCompressed: Value((m['isCompressed'] as bool?) ?? false),
          ));
          messageCount++;
        } catch (_) {}
      }

      return BackupRestoreResult(
        success: true,
        stats: {
          '视频': videoCount,
          '字幕': subtitleCount,
          '总结': summaryCount,
          '对话': sessionCount,
          '消息': messageCount,
        },
      );
    } catch (e) {
      return BackupRestoreResult(success: false, error: '$e');
    }
  }
}

class BackupRestoreResult {
  final bool success;
  final String? error;
  final Map<String, int>? stats;

  const BackupRestoreResult({required this.success, this.error, this.stats});
}
