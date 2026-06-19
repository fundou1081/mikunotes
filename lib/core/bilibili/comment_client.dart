// import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// B 站评论客户端
class CommentClient {
  final Dio _dio;
  final BilibiliClient _bili;

  CommentClient({required BilibiliClient bili})
      : _bili = bili,
        _dio = Dio(BaseOptions(
          baseUrl: 'https://api.bilibili.com',
          connectTimeout: const Duration(seconds: 15),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Referer': 'https://www.bilibili.com/',
          },
        ));

  /// 拉视频评论（主评论 + 子评论）
  /// [oid] = aid, [maxPages] = 最多页数（每页 20 条）
  Future<CommentResult> fetchComments(int aid, {int maxPages = 15}) async {
    final allComments = <BilibiliComment>[];
    int totalCount = 0;

    final sessdata = _bili.sessdata;
    final cookies = 'SESSDATA=$sessdata; buvid3=${_bili.buvid3}';

    for (int page = 1; page <= maxPages; page++) {
      final response = await _dio.get(
        '/x/v2/reply',
        queryParameters: {
          'type': 1, // 视频评论
          'oid': aid,
          'pn': page,
          'ps': 20,
          'sort': 2, // 按热度
        },
        options: Options(
          headers: {'Cookie': cookies},
          extra: {'withCredentials': true},
        ),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['code'] != 0) break;

      final pageData = data['data'] as Map<String, dynamic>?;
      if (pageData == null) break;

      totalCount = pageData['page']?['count'] as int? ?? 0;

      final replies = pageData['replies'] as List? ?? [];
      if (replies.isEmpty) break;

      for (final r in replies) {
        final member = r['member'] as Map<String, dynamic>? ?? {};
        final content = r['content'] as Map<String, dynamic>? ?? {};
        final mainComment = BilibiliComment(
          rpid: r['rpid'] as int? ?? 0,
          uname: member['uname'] as String? ?? '',
          level: member['level_info']?['current_level'] as int? ?? 0,
          content: content['message'] as String? ?? '',
          like: r['like'] as int? ?? 0,
          ctime: r['ctime'] as int? ?? 0,
        );

        // 子评论
        final subReplies = (r['replies'] as List?) ?? [];
        for (final sr in subReplies) {
          final srMember = sr['member'] as Map<String, dynamic>? ?? {};
          final srContent = sr['content'] as Map<String, dynamic>? ?? {};
          mainComment.subReplies.add(SubReply(
            uname: srMember['uname'] as String? ?? '',
            content: srContent['message'] as String? ?? '',
            like: sr['like'] as int? ?? 0,
          ));
        }
        allComments.add(mainComment);
      }
      if (replies.length < 20) break;
    }

    return CommentResult(
      comments: allComments,
      total: totalCount,
    );
  }
}

/// 评论数据结构
class BilibiliComment {
  final int rpid;
  final String uname;
  final int level;
  final String content;
  final int like;
  final int ctime;
  final List<SubReply> subReplies;

  BilibiliComment({
    required this.rpid,
    required this.uname,
    required this.level,
    required this.content,
    required this.like,
    required this.ctime,
    List<SubReply>? subReplies,
  }) : subReplies = subReplies ?? [];
}

class SubReply {
  final String uname;
  final String content;
  final int like;
  SubReply({required this.uname, required this.content, required this.like});
}

class CommentResult {
  final List<BilibiliComment> comments;
  final int total;
  CommentResult({required this.comments, required this.total});

  String toText() {
    final buf = StringBuffer();
    for (final c in comments) {
      buf.writeln('👍${c.like} ${c.uname}(Lv${c.level}): ${c.content}');
      for (final s in c.subReplies) {
        buf.writeln('  ↳ ${s.uname}: ${s.content}');
      }
    }
    return buf.toString();
  }
}

final commentClientProvider = Provider<CommentClient>((ref) {
  final bili = ref.watch(bilibiliClientProvider);
  return CommentClient(bili: bili);
});
