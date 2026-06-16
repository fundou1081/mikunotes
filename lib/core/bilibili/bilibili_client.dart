import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// WBI 签名混料表
const _mixinKeyEncTab = <int>[
  46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35,
  27, 43, 5, 49, 33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13,
  37, 48, 7, 16, 24, 55, 40, 61, 26, 17, 0, 1, 60, 51, 30, 4,
  22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11, 36, 20, 34, 44, 52,
];

String _getMixinKey(String orig) {
  final buf = StringBuffer();
  for (final i in _mixinKeyEncTab) {
    if (i < orig.length) buf.write(orig[i]);
  }
  return buf.toString().substring(0, 32);
}

/// 对参数进行 WBI 签名，返回加上 wts + w_rid 的新字典
Map<String, dynamic> signWbi(
  Map<String, dynamic> params,
  String imgKey,
  String subKey,
) {
  final mixinKey = _getMixinKey(imgKey + subKey);
  final wts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final p = Map<String, dynamic>.from(params);
  p['wts'] = wts;

  // 按 key 排序
  final sortedKeys = p.keys.toList()..sort();
  final queryParts = sortedKeys.map((k) {
    final v = p[k];
    final encodedValue = Uri.encodeQueryComponent(v.toString());
    return '$k=$encodedValue';
  }).join('&');

  final wRid = md5.convert(('$queryParts$mixinKey').codeUnits).toString();
  p['w_rid'] = wRid;
  return p;
}

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
  String? _wbiImgKey;
  String? _wbiSubKey;
  DateTime? _wbiKeysFetchedAt;

  BilibiliClient({String? sessdata, BiliUser? user, String? wbiImgKey, String? wbiSubKey})
      : _sessdata = sessdata,
        _user = user,
        _wbiImgKey = wbiImgKey,
        _wbiSubKey = wbiSubKey,
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

  /// 从 /x/web-interface/nav 获取 wbi 签名密钥 (1 天有效)
  Future<void> _ensureWbiKeys({bool force = false}) async {
    if (!force && _wbiImgKey != null && _wbiSubKey != null) {
      if (_wbiKeysFetchedAt != null &&
          DateTime.now().difference(_wbiKeysFetchedAt!) <
              const Duration(hours: 12)) {
        return;
      }
    }
    try {
      final resp = await _dio.get('https://api.bilibili.com/x/web-interface/nav');
      final data = resp.data?['data'];
      if (data is Map && data['wbi_img'] is Map) {
        final wbi = data['wbi_img'] as Map;
        final imgUrl = wbi['img_url'] as String? ?? '';
        final subUrl = wbi['sub_url'] as String? ?? '';
        _wbiImgKey = _extractKeyFromUrl(imgUrl);
        _wbiSubKey = _extractKeyFromUrl(subUrl);
        _wbiKeysFetchedAt = DateTime.now();
      }
    } catch (_) {
      // 获取失败也不影响其他功能
    }
  }

  String _extractKeyFromUrl(String url) {
    final filename = url.split('/').last;
    final dotIdx = filename.lastIndexOf('.');
    return dotIdx > 0 ? filename.substring(0, dotIdx) : filename;
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

  /// 获取字幕列表 (需要登录 + WBI 签名)
  Future<Map<String, dynamic>> getSubtitleInfo({
    required int aid,
    required int cid,
  }) async {
    await _ensureWbiKeys();
    if (_wbiImgKey == null || _wbiSubKey == null) {
      throw Exception('WBI 密钥获取失败，无法获取字幕');
    }

    final signed = signWbi(
      {'aid': aid, 'cid': cid},
      _wbiImgKey!,
      _wbiSubKey!,
    );

    final resp = await _dio.get(
      'https://api.bilibili.com/x/player/wbi/v2',
      queryParameters: signed,
    );
    final data = resp.data?['data'];
    if (data is! Map || data['subtitle'] is! Map) {
      throw Exception('字幕信息响应格式异常: ${resp.data?['message'] ?? '未知错误'}');
    }
    return data['subtitle'] as Map<String, dynamic>;
  }

  /// 下载字幕 JSON 内容 (兼容 B站非标准 JSON)
  Future<Map<String, dynamic>> downloadSubtitle(String url) async {
    final resp = await _dio.get(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    final rawBody = resp.data as String;

    // 先尝试标准 JSON
    try {
      return Map<String, dynamic>.from(
          jsonDecode(rawBody) as Map<String, dynamic>);
    } catch (_) {
      // B站有些字幕是类 JS 格式：{key_without_quotes: value}
      // 帮它补上引号
      try {
        final fixed = _fixNonStandardJson(rawBody);
        return Map<String, dynamic>.from(
            jsonDecode(fixed) as Map<String, dynamic>);
      } catch (e) {
        // 都失败了，把原始内容抛出去让调用方看到
        throw Exception(
            '字幕 JSON 解析失败。原始内容前 200 字: ${rawBody.substring(0, rawBody.length < 200 ? rawBody.length : 200)}');
      }
    }
  }

  /// 修复非标准 JSON：给未加引号的 key 补引号
  String _fixNonStandardJson(String raw) {
    // 处理 {key: value} 和 , key: value
    return raw.replaceAllMapped(
      RegExp(r'(?<=[{,])\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:', multiLine: true),
      (m) => '"${m.group(1)}":',
    );
  }
}
