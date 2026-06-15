import 'package:dio/dio.dart';

/// B站 API 客户端
/// 
/// 核心流程: 二维码登录 → 获取视频信息 → 下载字幕
class BilibiliClient {
  final Dio _dio;
  String? _sessdata;

  BilibiliClient({String? sessdata})
      : _sessdata = sessdata,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Referer': 'https://www.bilibili.com/',
          },
        )) {
    _updateCookies();
  }

  void _updateCookies() {
    if (_sessdata != null) {
      _dio.options.headers['Cookie'] = 'SESSDATA=$_sessdata';
    }
  }

  void setSessdata(String sessdata) {
    _sessdata = sessdata;
    _updateCookies();
  }

  bool get isLoggedIn => _sessdata != null && _sessdata!.isNotEmpty;

  /// 生成二维码登录 URL 和 qrcode_key
  Future<Map<String, String>> generateQrCode() async {
    final resp = await _dio.get(
      'https://passport.bilibili.com/x/passport-login/web/qrcode/generate',
    );
    final data = resp.data['data'];
    return {
      'url': data['url'] as String,
      'qrcode_key': data['qrcode_key'] as String,
    };
  }

  /// 轮询二维码状态
  /// 返回: { "status": "scanning"|"scanned"|"done", "sessdata"?: "..." }
  Future<Map<String, dynamic>> pollQrCode(String qrcodeKey) async {
    final resp = await _dio.get(
      'https://passport.bilibili.com/x/passport-login/web/qrcode/poll',
      queryParameters: {'qrcode_key': qrcodeKey},
    );
    final data = resp.data['data'];
    final code = data['code'] as int;

    if (code == 0) {
      // 登录成功，从响应 cookie 取 sessdata
      final cookies = resp.headers['set-cookie'];
      // 实际 sessdata 在轮询成功后通过另一个接口获取
      return {'status': 'done'};
    } else if (code == 86038) {
      return {'status': 'timeout'};
    } else if (code == 86090) {
      return {'status': 'scanned'};
    } else {
      return {'status': 'scanning'};
    }
  }

  /// 获取视频信息
  Future<Map<String, dynamic>> getVideoInfo(String bvid) async {
    final resp = await _dio.get(
      'https://api.bilibili.com/x/web-interface/view',
      queryParameters: {'bvid': bvid},
    );
    return resp.data['data'] as Map<String, dynamic>;
  }

  /// 获取字幕列表 (需要登录)
  Future<Map<String, dynamic>> getSubtitleInfo({
    required int aid,
    required int cid,
  }) async {
    // WBI 签名在客户端实现比较复杂，这里用简化版
    // 生产环境需要完整的 WBI 签名算法
    final resp = await _dio.get(
      'https://api.bilibili.com/x/player/wbi/v2',
      queryParameters: {
        'aid': aid,
        'cid': cid,
      },
    );
    return resp.data['data']['subtitle'] as Map<String, dynamic>;
  }

  /// 下载字幕 JSON 内容
  Future<Map<String, dynamic>> downloadSubtitle(String url) async {
    final resp = await _dio.get(url);
    return resp.data as Map<String, dynamic>;
  }
}
