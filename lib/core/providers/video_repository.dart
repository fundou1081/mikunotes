import 'dart:convert';
import 'package:drift/drift.dart' as drift show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
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

const _uuid = Uuid();

/// 视频仓库 — 整合 B站 API、字幕下载、数据库存储
class VideoRepository {
  final BilibiliClient _bili;
  final AppDatabase _db;
  final Ref _ref;

  VideoRepository(this._bili, this._db, this._ref);

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
    return video;
  }

  /// 下载一个视频的所有可用语言字幕
  Future<List<VideoSubtitle>> downloadAllSubtitles(String bvid) async {
    final video = await _db.getVideo(bvid);
    if (video == null) throw Exception('视频未在数据库中');

    final info = await _bili.getVideoInfo(bvid);
    final pages = (info['pages'] as List?)?.cast<Map>() ?? [];
    if (pages.isEmpty) throw Exception('视频无分P信息');

    final pageIdx = 0;
    final cid = pages[pageIdx]['cid'] as int;
    final subtitleData = await _bili.getSubtitleInfo(aid: video.aid, cid: cid);
    final subtitles = subtitleData['subtitles'] as List? ?? [];
    if (subtitles.isEmpty) {
      throw Exception('该视频没有字幕 (WBI签名可能失败)');
    }

    final results = <VideoSubtitle>[];
    for (final s in subtitles.cast<Map>()) {
      final lan = s['lan_doc'] as String? ?? s['lan'] as String? ?? 'unknown';
      final url = (s['subtitle_url'] as String? ?? '').startsWith('//')
          ? 'https:${s['subtitle_url']}'
          : s['subtitle_url'] as String;
      if (url.isEmpty) continue;

      try {
        final rawBody = await _bili.downloadSubtitleRaw(url);
        final entries = SubtitleParser.parseBilibiliJson(rawBody);
        final plainText = SubtitleParser.toPlainText(entries);

        await _db.upsertSubtitle(SubtitlesCompanion(
          id: const drift.Value.absent(),
          bvid: drift.Value(bvid),
          page: drift.Value(1),
          language: drift.Value(lan),
          rawJson: drift.Value(rawBody),
          plainText: drift.Value(plainText),
          charCount: drift.Value(plainText.length),
          entryCount: drift.Value(entries.length),
          downloadedAt: drift.Value(DateTime.now()),
        ));

        results.add(VideoSubtitle(
          videoId: bvid,
          language: lan,
          entries: entries,
        ));
      } catch (_) {
        // 单个语言失败不影响其他
      }
    }
    return results;
  }

  /// 下载指定语言的字幕
  Future<VideoSubtitle?> downloadAndStoreSubtitle(
    String bvid, {
    int? pageNum,
    String? language,
  }) async {
    final subs = await _db.getSubtitlesForVideo(bvid);
    if (subs.isNotEmpty) {
      // 已有字幕，直接返回请求的语言 (或第一个)
      final target = language != null
          ? subs.firstWhere(
              (s) => s.language == language,
              orElse: () => subs.first,
            )
          : subs.first;
      final entries = SubtitleParser.parseBilibiliJson(target.rawJson);
      return VideoSubtitle(
        videoId: bvid,
        language: target.language,
        entries: entries,
      );
    }

    // 没有字幕，下载全部 (然后挑一个)
    final downloaded = await downloadAllSubtitles(bvid);
    if (downloaded.isEmpty) return null;
    if (language != null) {
      final match = downloaded.firstWhere(
        (s) => s.language == language,
        orElse: () => downloaded.first,
      );
      return match;
    }
    // 优先中文
    return downloaded.firstWhere(
      (s) => s.language.contains('中文') || s.language.toLowerCase().contains('zh'),
      orElse: () => downloaded.first,
    );
  }

  /// 获取一个视频的所有字幕语言
  Future<List<Subtitle>> getAllSubtitles(String bvid) async {
    return _db.getSubtitlesForVideo(bvid);
  }

  /// 获取一个视频的指定语言字幕
  Future<VideoSubtitle?> getSubtitle(String bvid, {String? language, int? page}) async {
    final subs = await _db.getSubtitlesForVideo(bvid);
    if (subs.isEmpty) return null;

    // 过滤 by page
    final pageFiltered = page != null
        ? subs.where((s) => s.page == page).toList()
        : subs;
    if (pageFiltered.isEmpty) return null;

    final matched = language != null
        ? pageFiltered.firstWhere(
            (s) => s.language == language,
            orElse: () => pageFiltered.first,
          )
        : pageFiltered.firstWhere(
            (s) => s.language.contains('中文') || s.language.toLowerCase().contains('zh'),
            orElse: () => pageFiltered.first,
          );

    final entries = SubtitleParser.parseBilibiliJson(matched.rawJson);
    return VideoSubtitle(
      videoId: bvid,
      language: matched.language,
      entries: entries,
    );
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

  Future<summary_model.Summary?> getSummary(String id) async {
    final r = await _db.getSummary(id);
    if (r == null) return null;
    return summary_model.Summary(
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
    );
  }

  /// 创建总结 (返回保存的记录)
  Future<summary_model.Summary> createSummary({
    required String bvid,
    required String content,
    required summary_model.SummaryType type,
    String? title,
    String? modelUsed,
    String? promptUsed,
    String? targetTopic,
    int page = 0,
  }) async {
    final id = _uuid.v4();
    final finalTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : _autoTitle(content, type);

    final summary = summary_model.Summary(
      id: id,
      videoId: bvid,
      type: type,
      content: content,
      modelUsed: modelUsed ?? '',
      promptUsed: promptUsed ?? '',
      createdAt: DateTime.now(),
      title: finalTitle,
      page: page,
    );

    await _db.saveSummary(SummariesCompanion.insert(
      id: id,
      bvid: bvid,
      page: drift.Value(page),
      title: drift.Value(finalTitle),
      type: type.name,
      content: content,
      modelUsed: drift.Value(modelUsed ?? ''),
      promptUsed: drift.Value(promptUsed ?? ''),
      targetTopic: drift.Value(targetTopic ?? ''),
      createdAt: summary.createdAt,
    ));

    return summary;
  }

  Future<void> deleteSummary(String id) => _db.deleteSummary(id);

  String _autoTitle(String content, summary_model.SummaryType type) {
    final firstLine = content.split('\n').firstWhere(
      (l) => l.trim().isNotEmpty && !l.startsWith('#'),
      orElse: () => '',
    );
    final cleaned = firstLine.replaceAll(RegExp(r'[#*\[\]]'), '').trim();
    if (cleaned.isEmpty) {
      return '${type.name} ${DateTime.now().toIso8601String().substring(11, 16)}';
    }
    return cleaned.length > 40 ? '${cleaned.substring(0, 40)}...' : cleaned;
  }

  // ─── 对话会话 CRUD ──────────────────────────────────────────────

  Future<List<ChatSession>> getChatSessions(String bvid) =>
      _db.getChatSessionsForVideo(bvid);

  Future<ChatSession> createChatSession(String bvid, {String? title}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final session = ChatSession(
      id: id,
      bvid: bvid,
      title: title ?? _autoSessionTitle(),
      createdAt: now,
      lastActiveAt: now,
    );
    await _db.saveChatSession(ChatSessionsCompanion.insert(
      id: id,
      bvid: bvid,
      title: drift.Value(session.title),
      createdAt: now,
      lastActiveAt: now,
    ));
    return session;
  }

  String _autoSessionTitle() {
    final now = DateTime.now();
    return '对话 ${now.month}/${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> deleteChatSession(String id) => _db.deleteChatSession(id);

  Future<void> updateSessionTitle(String id, String title) =>
      (_db.update(_db.chatSessions)..where((s) => s.id.equals(id)))
          .write(ChatSessionsCompanion(title: drift.Value(title)));

  /// 获取会话历史
  Future<List<ChatMessage>> getChatMessages(String sessionId) =>
      _db.getChatMessages(sessionId);

  /// 添加消息到会话
  Future<void> addChatMessage({
    required String sessionId,
    required chat_model.ChatRole role,
    required String content,
  }) async {
    await _db.saveChatMessage(ChatMessagesCompanion.insert(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: role.name,
      content: content,
      timestamp: DateTime.now(),
    ));
    await _db.updateChatSessionLastActive(sessionId);
  }

  // ─── 上下文压缩 ──────────────────────────────────────────────

  /// 计算消息总字符数
  Future<int> sessionCharCount(String sessionId) async {
    final List<ChatMessage> msgs = await _db.getChatMessages(sessionId);
    int total = 0;
    for (final m in msgs) {
      total += m.content.length;
    }
    return total;
  }

  /// 自动压缩: 超出 maxContextChars 时，将最早的几条消息用 LLM 总结成一条
  Future<bool> compressContextIfNeeded(
    String sessionId, {
    required LLMClient llmClient,
    required AIConfig config,
  }) async {
    final msgs = await _db.getChatMessages(sessionId);
    if (msgs.length < 4) return false; // 太短不压缩

    final totalChars = msgs.fold(0, (sum, m) => sum + m.content.length);
    if (totalChars <= config.maxContextChars) return false;

    // 取最早的几条消息 (不包含压缩后的 summary)
    final toCompress = msgs
        .where((m) => !m.isCompressed)
        .take(msgs.length ~/ 2) // 压缩一半
        .toList();
    if (toCompress.isEmpty) return false;

    final textToCompress = toCompress
        .map((m) => '${m.role == "user" ? "用户" : "助手"}: ${m.content}')
        .join('\n');

    try {
      final disableReasoning = config.provider == LLMProvider.minimax;
          
      final summary = await llmClient.chat(
        systemPrompt:
            '你是一个对话历史压缩助手。请将以下对话历史压缩为简洁的要点摘要，保留关键信息：\n1. 用户的问题/需求\n2. 助手给出的重要结论/数据\n3. 任何重要的上下文\n\n用中文输出，控制在 ${config.compressTargetChars ~/ 2} 字以内。',
        userMessage: '以下是需要压缩的对话历史：\n\n$textToCompress',
        maxTokens: 1000,
        temperature: 0.2,
        disableReasoning: disableReasoning,
      );

      // 删除最早的消息
      await _db.deleteOldestMessages(sessionId, toCompress.length);
      // 添加压缩后的系统消息
      await _db.saveChatMessage(ChatMessagesCompanion.insert(
        id: _uuid.v4(),
        sessionId: sessionId,
        role: 'system',
        content: '[历史摘要] $summary',
        timestamp: DateTime.now(),
      ));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 构造发给 LLM 的对话历史
  Future<List<Map<String, String>>> buildChatMessages(
    String sessionId, {
    required String transcript,
  }) async {
    final msgs = await _db.getChatMessages(sessionId);
    return [
      {
        'role': 'system',
        'content':
            '你是视频内容问答助手。基于以下字幕内容回答用户问题。如果问题超出字幕范围，明确告知用户。\n\n字幕内容:\n$transcript',
      },
      ...msgs.map((m) => {
            'role': m.role,
            'content': m.content,
          }),
    ];
  }

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
}
