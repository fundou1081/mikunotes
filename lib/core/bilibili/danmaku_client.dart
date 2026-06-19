import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart' show bilibiliClientProvider;

/// 单条弹幕
class BilibiliDanmaku {
    final int id;         // 弹幕 ID
    final int progress;   // 出现时间 (ms)
    final int time;       // 发送时间 (unix sec)
    final String content;
    final int color;

    const BilibiliDanmaku({
        required this.id,
        required this.progress,
        required this.time,
        required this.content,
        required this.color,
    });
}

/// 拉取结果
class DanmakuResult {
    final List<BilibiliDanmaku> danmaku;
    final int totalCount;
    final bool truncated;
    final String? error;

    const DanmakuResult({
        required this.danmaku,
        required this.totalCount,
        required this.truncated,
        this.error,
    });

    factory DanmakuResult.empty({String? error}) => DanmakuResult(
        danmaku: const [],
        totalCount: 0,
        truncated: false,
        error: error,
    );
}

/// B 站弹幕客户端
/// 使用 XML API: https://comment.bilibili.com/{cid}.xml
/// 返回格式: <d p="time,type,size,color,unix_time,pool,sender_hash,id">内容</d>
class DanmakuClient {
    final Dio _dio;

    DanmakuClient()
        : _dio = Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
              'Referer': 'https://www.bilibili.com/',
            },
          ));

    /// 拉弹幕通过 XML API (不需要 protobuf)
    /// cid = 视频的 cid (不是 aid)
    Future<DanmakuResult> fetchDanmaku(int cid, {int maxSegments = 1}) async {
        try {
            // 优先使用 XML API: https://comment.bilibili.com/{cid}.xml
            final response = await _dio.get(
                'https://comment.bilibili.com/$cid.xml',
                options: Options(
                    responseType: ResponseType.plain,
                    receiveTimeout: const Duration(seconds: 30),
                ),
            );
            if (response.statusCode != 200) {
                return DanmakuResult.empty(
                    error: 'HTTP ${response.statusCode}: 弹幕获取失败',
                );
            }
            final body = response.data as String?;
            if (body == null || body.isEmpty) {
                return DanmakuResult.empty(error: '空响应');
            }
            return _parseXmlDanmaku(body);
        } catch (e) {
            return DanmakuResult.empty(error: '$e');
        }
    }

    /// 解析 XML 格式的弹幕
    /// <d p="490.19100,1,25,16777215,1584268892,0,a16fe0dd,29950852386521095">弹幕内容</d>
    DanmakuResult _parseXmlDanmaku(String xml) {
        final danmaku = <BilibiliDanmaku>[];
        // 正则匹配所有 <d p="..."> 标签
        final regex = RegExp(r'<d\s+p="([^"]+)"[^>]*>([^<]*)</d>');
        for (final match in regex.allMatches(xml)) {
            final attrs = match.group(1) ?? '';
            final content = match.group(2) ?? '';
            final parts = attrs.split(',');
            if (parts.length < 8) continue;

            try {
                // p="time,type,size,color,unix_time,pool,sender_hash,id"
                final time = double.parse(parts[0]);  // 秒 (带小数)
                final sendTime = int.parse(parts[4]);  // unix sec
                final id = int.parse(parts[7]);        // danmaku id
                final color = int.parse(parts[3]);      // color
                final progressMs = (time * 1000).toInt();  // 秒 → ms

                danmaku.add(BilibiliDanmaku(
                    id: id,
                    progress: progressMs,
                    time: sendTime,
                    content: content.trim(),
                    color: color,
                ));
            } catch (_) {
                continue;
            }
        }

        if (danmaku.isEmpty) {
            return DanmakuResult.empty(error: '该视频暂无弹幕');
        }

        // 按时间排序
        danmaku.sort((a, b) => a.progress.compareTo(b.progress));

        return DanmakuResult(
            danmaku: danmaku,
            totalCount: danmaku.length,
            truncated: false,
        );
    }
}

final danmakuClientProvider = Provider<DanmakuClient>((ref) {
    return DanmakuClient();
});
