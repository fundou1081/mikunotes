import 'package:dio/dio.dart';

/// B站登录用户信息
class BiliUser {
  final int mid;
  final String uname;
  final String face;
  final int level;
  final int vipType;
  final int coins;
  final String sign;

  const BiliUser({
    required this.mid,
    required this.uname,
    this.face = '',
    this.level = 0,
    this.vipType = 0,
    this.coins = 0,
    this.sign = '',
  });

  bool get isVip => vipType > 0;

  factory BiliUser.fromJson(Map<String, dynamic> json) => BiliUser(
        mid: (json['mid'] as num?)?.toInt() ?? 0,
        uname: (json['uname'] as String?) ?? '',
        face: (json['face'] as String?) ?? '',
        level: (json['level_info'] is Map
            ? (json['level_info']['current_level'] as num?)?.toInt() ?? 0
            : 0),
        vipType: (json['vip'] is Map
            ? (json['vip']['type'] as num?)?.toInt() ?? 0
            : (json['vipType'] as num?)?.toInt() ?? 0),
        coins: (json['money'] as num?)?.toInt() ?? (json['coins'] as num?)?.toInt() ?? 0,
        sign: (json['sign'] as String?) ?? '',
      );
}

/// B站 API 客户端
class BilibiliClient {
  final Dio _dio;
  String? _sessdata;
  BiliUser? _user;

  BilibiliClient({String? sessdata, BiliUser? user})
      : _sessdata = sessdata,
        _user = user,
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

  void setUser(BiliUser? user) {
    _user = user;
  }

  bool get isLoggedIn => _sessdata != null && _sessdata!.isNotEmpty;
  BiliUser? get user => _user;

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
  /// 返回:
  ///   { "status": "scanning"|"scanned"|"done"|"timeout",
  ///     "sessdata"?: "..." (仅 done 时返回)
  ///     "user"?: {...}    (登录成功后附带用户信息)
  ///   }
  Future<Map<String, dynamic>> pollQrCode(String qrcodeKey) async {
    final resp = await _dio.get(
      'https://passport.bilibili.com/x/passport-login/web/qrcode/poll',
      queryParameters: {'qrcode_key': qrcodeKey},
    );
    final data = resp.data['data'];
    final code = data['code'] as int;

    if (code == 0) {
      // 登录成功，从 Set-Cookie 头提取 SESSDATA
      String? sessdata;
      final rawCookies = resp.headers['set-cookie'];
      if (rawCookies != null) {
        for (final c in rawCookies) {
          if (c.toLowerCase().startsWith('sessdata=')) {
            sessdata = c.substring(9).split(';').first;
            break;
          }
        }
      }

      final result = <String, dynamic>{'status': 'done'};
      if (sessdata != null && sessdata.isNotEmpty) {
        result['sessdata'] = sessdata;
        // 立即设置，下次 fetchVideoInfo 不需要再传
        setSessdata(sessdata);
        try {
          final user = await fetchUserInfo();
          result['user'] = user;
        } catch (_) {}
      }
      return result;
    } else if (code == 86038) {
      return {'status': 'timeout'};
    } else if (code == 86090) {
      return {'status': 'scanned'};
    } else {
      return {'status': 'scanning'};
    }
  }

  /// 获取当前登录用户信息 (需要 SESSDATA)
  Future<BiliUser> fetchUserInfo() async {
    final resp = await _dio.get(
      'https://api.bilibili.com/x/web-interface/nav',
    );
    if (resp.data['code'] != 0) {
      throw Exception('未登录或 SESSDATA 失效');
    }
    final user = BiliUser.fromJson(resp.data['data']);
    _user = user;
    return user;
  }

  /// 获取视频信息
  Future<Map<String, dynamic>> getVideoInfo(String bvid) async {
    final resp = await _dio.get(
      'https://api.bilibili.com/x/web-interface/view',
      queryParameters: {'bvid': bvid},
    );
    return resp.data['data'] as Map<String, dynamic>;
  }

  /// 解析 b23.tv 短链接，返回真实 B站 URL
  /// 处理: b23.tv/xxx, bili2233.cn/xxx, 各种短链服务
  Future<String> resolveShortUrl(String shortUrl) async {
    if (!shortUrl.contains('b23.tv') &&
        !shortUrl.contains('bili2233.cn') &&
        !shortUrl.contains('bili22.cn')) {
      return shortUrl;
    }

    // 使用 HEAD 跟随重定向（但有些服务不响应 HEAD，用 GET 保险）
    try {
      final resp = await _dio.head(
        shortUrl,
        options: Options(
          followRedirects: true,
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return resp.realUri.toString();
    } catch (e) {
      // HEAD 失败，尝试 GET
      final resp = await _dio.get(
        shortUrl,
        options: Options(
          followRedirects: true,
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return resp.realUri.toString();
    }
  }

  /// 获取字幕列表 (需要登录)
  Future<Map<String, dynamic>> getSubtitleInfo({
    required int aid,
    required int cid,
  }) async {
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
