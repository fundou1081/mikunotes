import 'package:drift/drift.dart' as drift show Value;
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/models/video.dart' as model;
import 'package:mikunotes/core/storage/database.dart';
import 'package:mikunotes/core/subtitle/subtitle_parser.dart';

/// 视频仓库 — 整合 B站 API、字幕下载、数据库存储
class VideoRepository {
  final BilibiliClient _bili;
  final AppDatabase _db;

  VideoRepository(this._bili, this._db);

  /// 从 URL 或 BV号 解析 BV号
  /// 支持的输入格式:
  ///   - "BV1xxx" (纯 BV 号)
  ///   - "https://www.bilibili.com/video/BV1xxx" (完整链接)
  ///   - "https://b23.tv/xxx" (短链接)
  ///   - "【标题】 https://b23.tv/xxx" (分享整段文本)
  Future<String?> parseBvid(String input) async {
    String text = input.trim();

    // 从整段文本中提取出 URL (例如 "【标题】 https://b23.tv/xxx")
    final urlMatch = RegExp(r'https?://[^\s\u4e00-\u9fff]+').firstMatch(text);
    String url = urlMatch?.group(0) ?? text;

    // 短链接需要先解析
    if (RegExp(r'https?://(b23\.tv|bili2233\.cn|bili22\.cn)/[A-Za-z0-9]+')
        .hasMatch(url)) {
      try {
        url = await _bili.resolveShortUrl(url);
      } catch (e) {
        // 解析失败，fallthrough
      }
    }

    // 匹配 BV 号
    final match = RegExp(r'BV[A-Za-z0-9]{10}').firstMatch(url);
    return match?.group(0);
  }

  /// 导入视频: 获取信息 + 下载字幕
  Future<model.Video?> addVideo(String urlOrBvid) async {
    final bvid = await parseBvid(urlOrBvid);
    if (bvid == null) {
      throw const FormatException(
          '无法从输入中提取 BVID（请检查链接是否正确）');
    }

    if (!_bili.isLoggedIn) {
      throw const FormatException('请先登录 B站');
    }

    // 1. 获取视频信息
    final info = await _bili.getVideoInfo(bvid);
    final aid = info['aid'] as int;
    final title = info['title'] as String;
    final cover = info['pic'] as String? ?? '';
    final uploader = (info['owner'] as Map?)?['name'] as String? ?? '';
    final duration = (info['duration'] as num?)?.toInt() ?? 0;
    final pages = (info['pages'] as List?)?.cast<Map>() ?? [];

    // 2. 保存元数据
    final video = model.Video(
      id: bvid,
      bvid: bvid,
      title: title,
      coverUrl: cover,
      uploader: uploader,
      duration: duration,
      pageCount: pages.length,
      addedAt: DateTime.now(),
    );

    await _db.upsertVideo(VideosCompanion(
      bvid: drift.Value(video.bvid),
      title: drift.Value(video.title),
      coverUrl: drift.Value(video.coverUrl),
      uploader: drift.Value(video.uploader),
      aid: drift.Value(aid),
      duration: drift.Value(video.duration),
      pageCount: drift.Value(video.pageCount),
      addedAt: drift.Value(video.addedAt),
    ));

    // 3. 下载字幕 (第一P)
    if (pages.isNotEmpty) {
      await _downloadAndStoreSubtitle(bvid, aid, 1, pages[0]['cid'] as int);
    }

    return video;
  }

  Future<VideoSubtitle?> _downloadAndStoreSubtitle(
    String bvid,
    int aid,
    int pageNum,
    int cid,
  ) async {
    try {
      final subtitleData = await _bili.getSubtitleInfo(aid: aid, cid: cid);
      final subtitles = subtitleData['subtitles'] as List? ?? [];

      if (subtitles.isEmpty) return null;

      // 优先中文字幕
      Map? target;
      for (final s in subtitles.cast<Map>()) {
        final lan = s['lan'] as String? ?? '';
        final lanDoc = s['lan_doc'] as String? ?? '';
        if (lan.toLowerCase().contains('zh') || lanDoc.contains('中文')) {
          target = s;
          break;
        }
      }
      target ??= subtitles.first as Map;

      final url = (target['subtitle_url'] as String? ?? '').startsWith('//')
          ? 'https:${target['subtitle_url']}'
          : target['subtitle_url'] as String;
      final lan = target['lan_doc'] as String? ?? target['lan'] as String? ?? 'unknown';

      if (url.isEmpty) return null;

      final content = await _bili.downloadSubtitle(url);
      final jsonString = content.toString();
      final entries = SubtitleParser.parseBilibiliJson(jsonString);
      final plainText = SubtitleParser.toPlainText(entries);

      await _db.upsertSubtitle(SubtitlesCompanion(
        bvid: drift.Value(bvid),
        pageNum: drift.Value(pageNum),
        language: drift.Value(lan),
        rawJson: drift.Value(jsonString),
        plainText: drift.Value(plainText),
        downloadedAt: drift.Value(DateTime.now()),
      ));

      return VideoSubtitle(
        videoId: bvid,
        language: lan,
        entries: entries,
      );
    } catch (e) {
      // 字幕下载失败不影响视频入库
      return null;
    }
  }

  Future<List<model.Video>> getAllVideos() async {
    final rows = await _db.getAllVideos();
    return rows
        .map((r) => model.Video(
              id: r.bvid,
              bvid: r.bvid,
              title: r.title,
              coverUrl: r.coverUrl,
              uploader: r.uploader,
              duration: r.duration,
              pageCount: r.pageCount,
              addedAt: r.addedAt,
              tags: r.tags.isEmpty
                  ? const []
                  : r.tags.split(',').map((t) => t.trim()).toList(),
            ))
        .toList();
  }

  Future<VideoSubtitle?> getSubtitle(String bvid, {int pageNum = 1, String? lang}) async {
    final rows = await _db.getSubtitlesForVideo(bvid);
    if (rows.isEmpty) return null;

    // 优先中文字幕
    final matched = rows.firstWhere(
      (s) => s.language.toLowerCase().contains('zh') || s.language.contains('中文'),
      orElse: () => rows.first,
    );

    final entries = SubtitleParser.parseBilibiliJson(matched.rawJson);
    return VideoSubtitle(
      videoId: bvid,
      language: matched.language,
      entries: entries,
    );
  }

  Future<void> deleteVideo(String bvid) => _db.deleteVideo(bvid);
}

