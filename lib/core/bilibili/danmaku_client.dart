import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/providers/providers.dart' show bilibiliClientProvider;

/// 单条弹幕
class BilibiliDanmaku {
    final int progress;  // 出现时间 (ms)
    final int time;      // 发送时间 (unix sec)
    final String content;
    final int color;

    const BilibiliDanmaku({
        required this.progress,
        required this.time,
        required this.content,
        required this.color,
    });

    factory BilibiliDanmaku.fromJson(Map<String, dynamic> j) {
        return BilibiliDanmaku(
            progress: (j['progress'] as num?)?.toInt() ?? 0,
            time: (j['time'] as num?)?.toInt() ?? 0,
            content: (j['content'] as String?) ?? '',
            color: (j['color'] as num?)?.toInt() ?? 0xffffff,
        );
    }
}

/// 拉取结果
class DanmakuResult {
    final List<BilibiliDanmaku> danmaku;
    final int totalCount;       // B 站返回的总数
    final bool truncated;       // 是否被截断
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
/// v0.7.1: 占位 (返回空)
/// v0.7.2: 实现 protobuf 解析 (B 站弹幕 API 是 protobuf 格式)
class DanmakuClient {
    final Dio _dio;
    final String _sessdata;

    DanmakuClient({required String sessdata})
        : _sessdata = sessdata,
          _dio = Dio(BaseOptions(
            baseUrl: 'https://api.bilibili.com',
            connectTimeout: const Duration(seconds: 15),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
              'Referer': 'https://www.bilibili.com/',
            },
          ));

    /// 拉弹幕 (历史弹幕 API, 一次性最多 3000 条/段)
    /// cid = 视频的 cid (不是 aid)
    Future<DanmakuResult> fetchDanmaku(int cid, {int maxSegments = 1}) async {
        try {
            if (_sessdata.isNotEmpty) {
                _dio.options.headers['Cookie'] = 'SESSDATA=$_sessdata';
            }
            // ⚠️ B 站 /x/v2/dm/web/seg.so 返回 protobuf 二进制
            // v0.7.1 暂不实现, v0.7.2 用自定义 protobuf 解析
            return DanmakuResult.empty(
                error: '弹幕下载将在 v0.7.2 实现 (protobuf 解析)',
            );
        } catch (e) {
            return DanmakuResult.empty(error: '$e');
        }
    }
}

final danmakuClientProvider = Provider<DanmakuClient>((ref) {
    final bili = ref.watch(bilibiliClientProvider);
    return DanmakuClient(sessdata: bili.sessdata);
});
