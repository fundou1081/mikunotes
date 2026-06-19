import 'package:drift/drift.dart' as drift show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart';
import 'package:mikunotes/core/subtitle/subtitle_parser.dart';

/// 字幕子仓库 — 从 VideoRepository 拆分
class SubtitleRepository {
  final BilibiliClient _bili;
  final AppDatabase _db;

  SubtitleRepository(this._bili, this._db);

  /// 下载一个视频的所有可用语言字幕 (按分P分别下载)
  Future<List<VideoSubtitle>> downloadAllSubtitles(String bvid) async {
    final video = await _db.getVideo(bvid);
    if (video == null) throw Exception('视频未在数据库中');

    final info = await _bili.getVideoInfo(bvid);
    final pages = (info['pages'] as List?)?.cast<Map>() ?? [];
    if (pages.isEmpty) throw Exception('视频无分P信息');

    final results = <VideoSubtitle>[];
    int totalSaved = 0;
    int failedPages = 0;

    // 遍历所有分P, 分别为每个分P下载并保存
    for (int pIdx = 0; pIdx < pages.length; pIdx++) {
      final pageNum = pIdx + 1; // 1-indexed
      final cid = pages[pIdx]['cid'] as int;
      if (cid == 0) continue;

      try {
        final subtitleData = await _bili.getSubtitleInfo(aid: video.aid, cid: cid);
        final subtitles = (subtitleData['subtitles'] as List?)?.cast<Map>() ?? [];
        if (subtitles.isEmpty) {
          // 该分P无字幕, 跳过
          continue;
        }

        for (final s in subtitles) {
          final lan = s['lan_doc'] as String? ?? s['lan'] as String? ?? 'unknown';
          final rawUrl = s['subtitle_url'] as String? ?? '';
          if (rawUrl.isEmpty) continue;
          final url = rawUrl.startsWith('//') ? 'https:$rawUrl' : rawUrl;

          try {
            final rawBody = await _bili.downloadSubtitleRaw(url);
            final entries = SubtitleParser.parseBilibiliJson(rawBody);
            final plainText = SubtitleParser.toPlainText(entries);

            await _db.upsertSubtitle(SubtitlesCompanion(
              id: const drift.Value.absent(),
              bvid: drift.Value(bvid),
              page: drift.Value(pageNum),
              language: drift.Value(lan),
              rawJson: drift.Value(rawBody),
              plainText: drift.Value(plainText),
              charCount: drift.Value(plainText.length),
              entryCount: drift.Value(entries.length),
              downloadedAt: drift.Value(DateTime.now()),
            ));

            totalSaved++;
            results.add(VideoSubtitle(
              videoId: bvid,
              language: lan,
              entries: entries,
            ));
          } catch (_) {
            // 单个语言失败不影响其他
          }
        }
      } catch (_) {
        failedPages++;
        // 单个分P获取失败不影响其他分P
      }
    }

    if (totalSaved == 0) {
      if (failedPages > 0) {
        throw Exception('该视频没有字幕 (${failedPages}个分P获取失败)');
      }
      throw Exception('该视频没有字幕');
    }
    return results;
  }

  /// 下载指定语言的字幕
  Future<VideoSubtitle?> downloadAndStoreSubtitle(
    String bvid, {
    int? pageNum,
    String? language,
  }) async {
    final video = await _db.getVideo(bvid);
    if (video == null) return null;
    final cid = await _bili.getCidForPage(bvid, page: pageNum ?? 1);
    if (cid == 0) return null;
    final subtitleData = await _bili.getSubtitleInfo(aid: video.aid, cid: cid);
    final subtitles = (subtitleData['subtitles'] as List?)?.cast<Map>() ?? [];
    for (final s in subtitles) {
      final lan = s['lan_doc'] as String? ?? s['lan'] as String? ?? '';
      if (language != null && lan != language) continue;
      final rawUrl = s['subtitle_url'] as String? ?? '';
      if (rawUrl.isEmpty) continue;
      final url = rawUrl.startsWith('//') ? 'https:$rawUrl' : rawUrl;
      final rawBody = await _bili.downloadSubtitleRaw(url);
      final entries = SubtitleParser.parseBilibiliJson(rawBody);
      final plainText = SubtitleParser.toPlainText(entries);
      await _db.upsertSubtitle(SubtitlesCompanion(
        id: const drift.Value.absent(),
        bvid: drift.Value(bvid),
        page: drift.Value(pageNum ?? 1),
        language: drift.Value(lan),
        rawJson: drift.Value(rawBody),
        plainText: drift.Value(plainText),
        charCount: drift.Value(plainText.length),
        entryCount: drift.Value(entries.length),
        downloadedAt: drift.Value(DateTime.now()),
      ));
      return VideoSubtitle(videoId: bvid, language: lan, entries: entries);
    }
    return null;
  }

  /// 获取一个视频的所有字幕记录
  Future<List<Subtitle>> getAllSubtitles(String bvid) async {
    return _db.getSubtitlesForVideo(bvid);
  }

  /// 获取一个视频的指定语言字幕
  Future<VideoSubtitle?> getSubtitle(String bvid,
      {String? language, int? page}) async {
    final subs = await _db.getSubtitlesForVideo(bvid);
    if (subs.isEmpty) return null;

    // 过滤 by page
    final pageFiltered =
        page != null ? subs.where((s) => s.page == page).toList() : subs;
    if (pageFiltered.isEmpty) return null;

    final matched = language != null
        ? pageFiltered.firstWhere(
            (s) => s.language == language,
            orElse: () => pageFiltered.first,
          )
        : pageFiltered.firstWhere(
            (s) =>
                s.language.contains('中文') || s.language.toLowerCase().contains('zh'),
            orElse: () => pageFiltered.first,
          );

    final entries = SubtitleParser.parseBilibiliJson(matched.rawJson);
    return VideoSubtitle(
      videoId: bvid,
      language: matched.language,
      entries: entries,
    );
  }
}

final subtitleRepositoryProvider = Provider<SubtitleRepository>((ref) {
  return SubtitleRepository(
    ref.watch(bilibiliClientProvider),
    ref.watch(databaseProvider),
  );
});