import 'dart:convert';
import 'package:drift/drift.dart' as drift show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/events/video_events.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/chat_message.dart' as chat_model;
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:mikunotes/core/models/video.dart' as video_model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart' hide Video;
import 'package:mikunotes/core/subtitle/subtitle_parser.dart';
import 'package:uuid/uuid.dart';
import 'package:mikunotes/core/providers/repository/subtitle_repository.dart';
import 'package:mikunotes/core/providers/repository/summary_repository.dart';
import 'package:mikunotes/core/providers/repository/chat_repository.dart';

const _uuid = Uuid();

/// 视频仓库 — 整合 B站 API、字幕下载、数据库存储
class VideoRepository {
  final BilibiliClient _bili;
  final AppDatabase _db;
  final Ref _ref;
  final VideoEventBus _events; // ⭐ 事件总线, 解耦 wiki 同步

  VideoRepository(this._bili, this._db, this._ref, this._events);

  /// 从 URL 或 BV号 解析 BV号 (兼容分享整段文本)
  Future<String?> parseBvid(String input) async {
    String text = input.trim();
    final urlMatch = RegExp(r'https?://[^\s\u4e00-\u9fff]+').firstMatch(text);
    String url = urlMatch?.group(0) ?? text;

    if (RegExp(r'https?://(b23\.tv|bili2233\.cn|bili22\.cn)/[A-Za-z0-9]+')
        .hasMatch(url)) {
      try {
        url = await _bili.resolveShortUrl(url);
      } catch (_) {}
    }
    final match = RegExp(r'BV[A-Za-z0-9]{10}').firstMatch(url);
    return match?.group(0);
  }

  /// 导入视频
  Future<video_model.Video?> addVideo(String urlOrBvid) async {
    final bvid = await parseBvid(urlOrBvid);
    if (bvid == null) throw const FormatException('无法从输入中提取 BVID');

    if (!_bili.isLoggedIn) throw const FormatException('请先登录 B站');

    final info = await _bili.getVideoInfo(bvid);
    final aid = info['aid'] as int;
    final title = info['title'] as String;
    final cover = info['pic'] as String? ?? '';
    final uploader = (info['owner'] as Map?)?['name'] as String? ?? '';
    final upMid = (info['owner'] as Map?)?['mid'] as int? ?? 0;
    final upFace = (info['owner'] as Map?)?['face'] as String? ?? '';
    final duration = (info['duration'] as num?)?.toInt() ?? 0;
    final pages = (info['pages'] as List?)?.cast<Map>() ?? [];
    final pageCount = pages.length == 0 ? 1 : pages.length;
    // 保存分P 名称 (从 B 站 'part' 字段提取)
    final pageNames = pages.map((p) {
      final p1 = p['part'] as String? ?? '';
      return p1;
    }).toList();

    // 1. 插入/更新 video_group
    final now = DateTime.now();
    await _db.insertVideoGroup(VideoGroupsCompanion.insert(
      bvid: bvid,
      title: title,
      cover: drift.Value(cover),
      uploader: drift.Value(uploader),
      upMid: drift.Value(upMid),
      upFace: drift.Value(upFace),
      totalDuration: drift.Value(duration),
      pageCount: drift.Value(pageCount),
      pageNamesJson: drift.Value(jsonEncode(pageNames)),
      addedAt: now,
    ));
    // 2. 插入/更新 video (page=1)
    await _db.upsertVideo(VideosCompanion.insert(
      bvid: bvid,
      page: 1,
      aid: aid,
      cid: drift.Value(0),
      partName: drift.Value(''),
      partTitle: drift.Value(''),
      partCover: drift.Value(''),
      duration: drift.Value(duration),
      addedAt: now,
    ));

    // 创建/查找 UP 主容器, 关联到视频
    if (upMid > 0) {
      try {
        final um = await _db.addOrGetUpMaster(
          uid: upMid, name: uploader, face: upFace,
        );
        await _db.addVideoToUpMasterContainer(
          upMasterId: um.id, bvid: bvid, addedAt: now,
        );
      } catch (_) {
        // UP 主容器创建失败不影响主流程
      }
    }

    // 尝试下载第一P的所有语言字幕 (非阻塞)
    if (pages.isNotEmpty) {
      try {
        await downloadAllSubtitles(bvid);
      } catch (e) {
        // 字幕下载失败不影响视频入库
      }
    }

    final video = video_model.Video(
      bvid: bvid,
      page: 1,
      title: title,
      coverUrl: cover,
      uploader: uploader,
      duration: duration,
      pageCount: pageCount,
      addedAt: now,
    );
    _events.emit(VideoAdded(bvid)); // ⭐ wiki 同步
    return video;
  }

  Future<List<video_model.Video>> getAllVideos() async {
    final rows = await _db.getAllVideos();
    final result = <video_model.Video>[];
    for (final v in rows) {
      final g = await _db.getVideoGroup(v.bvid);
      if (g == null) continue;
      result.add(video_model.Video(
        bvid: v.bvid,
        page: v.page,
        title: v.partTitle.isNotEmpty ? v.partTitle : g.title,
        coverUrl: v.partCover.isNotEmpty ? v.partCover : g.cover,
        uploader: g.uploader,
        duration: v.duration,
        pageCount: g.pageCount,
        addedAt: v.addedAt,
        tags: g.tags.isEmpty ? const [] : g.tags.split(',').map((t) => t.trim()).toList(),
        aiTags: g.aiTags.isEmpty ? const [] : g.aiTags.split(',').map((t) => t.trim()).toList(),
      ));
    }
    result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return result;
  }

  Future<void> deleteVideo(String bvid) => _db.deleteVideo(bvid);

  /// 异步提取 AI tags 并保存 (不阻塞主流程)
  Future<void> extractAndSaveAiTags({
    required String bvid,
    required String title,
    required String content,
  }) async {
    try {
      final llmClient = _ref.read(llmClientProvider);
      final prompt = '''从以下视频内容中提取 3-5 个精准标签用于分类。
标签用中文1-4字，覆盖技术/人物/主题/行业等维度。
不要泛词。输出 JSON 数组如: ["AI", "深度学习"]

视频: $title
内容: ${content.length > 2000 ? content.substring(0, 2000) : content}

只输出 JSON 数组:''';
      final response = await llmClient.chat(
        systemPrompt: '你是视频内容分析专家。',
        userMessage: prompt,
        maxTokens: 200,
      );
      // 解析 JSON 数组
      final tags = _parseAiTags(response);
      if (tags.isNotEmpty) {
        await _db.updateVideoTags(bvid, aiTags: tags.join(','));
        _events.emit(TagsUpdated(bvid)); // ⭐ wiki 同步
      }
    } catch (_) {
      // 静默失败,不阻塞主流程
    }
  }

  List<String> _parseAiTags(String text) {
    try {
      String json = text.trim();
      if (json.contains('```')) {
        final m = RegExp(r"```(?:json)?\s*(\[.*?\])\s*```", dotAll: true).firstMatch(json);
        if (m != null) json = m.group(1)!;
      }
      final list = jsonDecode(json) as List;
      return list.map((t) => t.toString().trim()).where((t) => t.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── 总结 CRUD ──────────────────────────────────────────────

  /// 批量添加视频到指定容器 (不下字幕, 用于收藏夹/稍后观看批量导入)
  /// 返回 {success: [bvid], failed: [{bvid, error}]}
  Future<Map<String, List<dynamic>>> batchAddToContainer(
    List<String> bvids,
    int containerId, {
    void Function(int done, int total)? onProgress,
  }) async {
    final success = <String>[];
    final failed = <Map<String, String>>[];
    final alreadyInDb = <String>[];

    for (var i = 0; i < bvids.length; i++) {
      final bvid = bvids[i];
      onProgress?.call(i + 1, bvids.length);
      try {
        // 先看 DB 里有没有
        var existing = await _db.getVideo(bvid);
        int upMid = 0;
        String upName = '', upFace = '';
        if (existing == null) {
          // 从 B 站拉元信息
          final info = await _bili.getVideoInfo(bvid);
          final aid = (info['aid'] as num?)?.toInt() ?? 0;
          final title = info['title'] as String? ?? bvid;
          final cover = info['pic'] as String? ?? '';
          final uploader = (info['owner'] as Map?)?['name'] as String? ?? '';
          upMid = (info['owner'] as Map?)?['mid'] as int? ?? 0;
          upName = uploader;
          upFace = (info['owner'] as Map?)?['face'] as String? ?? '';
          final duration = (info['duration'] as num?)?.toInt() ?? 0;
          final pages = (info['pages'] as List?)?.cast<Map>() ?? [];
          await _db.upsertVideo(VideosCompanion.insert(
            bvid: bvid,
            page: 1,
      aid: aid,
            cid: drift.Value(0),
            partName: drift.Value(''),
            partTitle: drift.Value(''),
            partCover: drift.Value(''),
            duration: drift.Value(duration),
            addedAt: DateTime.now(),
          ));
        } else {
          alreadyInDb.add(bvid);
          // Get UP info from video_group
          final g = await _db.getVideoGroup(bvid);
          if (g != null) {
            upMid = g.upMid;
            upName = g.uploader;
          }
        }
        // 创建/查找 UP 主容器, 关联到视频
        if (upMid > 0) {
          try {
            final um = await _db.addOrGetUpMaster(
              uid: upMid, name: upName, face: upFace,
            );
            await _db.addVideoToUpMasterContainer(
              upMasterId: um.id, bvid: bvid,
            );
          } catch (_) {
            // 失败不影响主流程
          }
        }
        // 加入容器
        await _db.addVideoToContainer(containerId, bvid);
        success.add(bvid);
      } catch (e) {
        failed.add({'bvid': bvid, 'error': e.toString()});
      }
    }
    return {'success': success, 'failed': failed, 'alreadyInDb': alreadyInDb};
  }

  /// 从 B 站刷新视频元数据 (覆盖式) - 用于恢复后无信息场景
  Future<void> refreshVideoMetadata(String bvid, Map<String, dynamic> info) async {
    final aid = (info['aid'] as num?)?.toInt() ?? 0;
    final title = info['title'] as String? ?? bvid;
    final cover = info['pic'] as String? ?? '';
    final uploader = (info['owner'] as Map?)?['name'] as String? ?? '';
    final upMid = (info['owner'] as Map?)?['mid'] as int? ?? 0;
    final upFace = (info['owner'] as Map?)?['face'] as String? ?? '';
    final duration = (info['duration'] as num?)?.toInt() ?? 0;
    final pages = (info['pages'] as List?)?.cast<Map>() ?? [];
    final pageCount = pages.isEmpty ? 1 : pages.length;
    final pageNames = pages.map((p) => p['part'] as String? ?? '').toList();
    final now = DateTime.now();

    // UPSERT video_group (覆盖)
    await _db.insertVideoGroup(VideoGroupsCompanion.insert(
      bvid: bvid,
      title: title,
      cover: drift.Value(cover),
      uploader: drift.Value(uploader),
      upMid: drift.Value(upMid),
      upFace: drift.Value(upFace),
      totalDuration: drift.Value(duration),
      pageCount: drift.Value(pageCount),
      pageNamesJson: drift.Value(jsonEncode(pageNames)),
      addedAt: now,
    ));
    // UPSERT video page=1
    await _db.upsertVideo(VideosCompanion.insert(
      bvid: bvid,
      page: 1,
      aid: aid,
      cid: drift.Value(0),
      partName: drift.Value(''),
      partTitle: drift.Value(''),
      partCover: drift.Value(''),
      duration: drift.Value(duration),
      addedAt: now,
    ));
    // 如果是 UP 主, 同步 UP 主记录
    if (upMid > 0) {
      try {
        await _db.addOrGetUpMaster(uid: upMid, name: uploader, face: upFace);
      } catch (_) {}
    }
  }

  // ─── Facade: 委托给子仓库 ─────────────────────────────────

  SubtitleRepository get _subRepo => SubtitleRepository(_bili, _db);
  SummaryRepository get _sumRepo => SummaryRepository(_db);
  ChatRepository get _chatRepo => ChatRepository(_db);

  // Subtitle
  Future<List<VideoSubtitle>> downloadAllSubtitles(String bvid) => _subRepo.downloadAllSubtitles(bvid);
  Future<VideoSubtitle?> downloadAndStoreSubtitle(String bvid, {int? pageNum, String? language}) =>
      _subRepo.downloadAndStoreSubtitle(bvid, pageNum: pageNum, language: language);
  Future<List<Subtitle>> getAllSubtitles(String bvid) => _subRepo.getAllSubtitles(bvid);
  Future<VideoSubtitle?> getSubtitle(String bvid, {String? language, int? page}) =>
      _subRepo.getSubtitle(bvid, language: language, page: page);

  // Summary
  Future<List<summary_model.Summary>> getAllSummaries(String bvid) => _sumRepo.getAllSummaries(bvid);
  Future<summary_model.Summary?> getSummary(String id) => _sumRepo.getSummary(id);
  Future<summary_model.Summary> createSummary({required String bvid, required String content, required summary_model.SummaryType type, required String modelUsed, required String promptUsed, String? title, int page = 0, String? targetTopic}) =>
      _sumRepo.createSummary(bvid: bvid, content: content, type: type, modelUsed: modelUsed, promptUsed: promptUsed, title: title, page: page, targetTopic: targetTopic);
  Future<void> deleteSummary(String id) => _sumRepo.deleteSummary(id);

  // Chat
  Future<List<ChatSession>> getChatSessions(String bvid) => _chatRepo.getChatSessions(bvid);
  Future<ChatSession> createChatSession(String bvid, {String? title}) => _chatRepo.createChatSession(bvid, title: title);
  Future<void> deleteChatSession(String id) => _chatRepo.deleteChatSession(id);
  Future<void> updateSessionTitle(String id, String title) => _chatRepo.updateSessionTitle(id, title);
  Future<List<ChatMessage>> getChatMessages(String sessionId) => _chatRepo.getChatMessages(sessionId);
  Future<void> addChatMessage({required String sessionId, required chat_model.ChatRole role, required String content}) =>
      _chatRepo.addChatMessage(sessionId: sessionId, role: role, content: content);
  Future<int> sessionCharCount(String sessionId) => _chatRepo.sessionCharCount(sessionId);
  Future<bool> compressContextIfNeeded(String sessionId, {required LLMClient llmClient, required AIConfig config}) =>
      _chatRepo.compressContextIfNeeded(sessionId, llmClient: llmClient, config: config);
  Future<List<Map<String, String>>> buildChatMessages(String sessionId, {required String transcript, required String systemPrompt}) =>
      _chatRepo.buildChatMessages(sessionId, transcript: transcript, systemPrompt: systemPrompt);

}
