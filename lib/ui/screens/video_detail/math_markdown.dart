import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 摘要 markdown 渲染: 把 $...$ 数学公式转成内联代码 (避开了
/// 自定义 InlineSyntax 跟 GFM 解析器的冲突, 保证整段 markdown 渲染正常)
///
/// Wiki 链接: 把 `[[BVxxx]]` `[[tag:xxx]]` `[[uploader:xxx]]`
/// 预处理成标准 markdown link `[显示](wiki:xxx)`,
/// 让 flutter_markdown 渲染为可点击的 TextSpan,
/// 由 onTapLink 回调处理跳转
class MathMarkdownBody extends StatelessWidget {
  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;
  final MarkdownTapLinkCallback? onWikiLinkTap;

  const MathMarkdownBody({
    super.key,
    required this.data,
    this.selectable = true,
    this.styleSheet,
    this.onWikiLinkTap,
  });

  /// 把 $...$ 转成内联代码, 让 MarkdownBody 渲染为等宽灰底
  String _processMath(String text) {
    return text.replaceAllMapped(
      RegExp(r'\$([^$\n]+?)\$'),
      (m) => '`${m.group(1)}`',
    );
  }

  /// 把 [[BVxxx]] 转换为 [BVxxx](wiki:bv:BVxxx)
  /// 把 [[tag:xxx]] 转换为 [#xxx](wiki:tag:xxx)
  /// 把 [[uploader:xxx]] 转换为 [@xxx](wiki:up:xxx)
  String _processWikiLinks(String text) {
    // BVxxx 链接
    var result = text.replaceAllMapped(
      RegExp(r'\[\[([Bb][Vv][a-zA-Z0-9]+)\]\]'),
      (m) => '[${m.group(1)}](wiki:bv:${m.group(1)})',
    );
    // tag:xxx 链接
    result = result.replaceAllMapped(
      RegExp(r'\[\[tag:([^\]]+?)\]\]'),
      (m) => '[#${m.group(1)}](wiki:tag:${m.group(1)})',
    );
    // uploader:xxx 链接
    result = result.replaceAllMapped(
      RegExp(r'\[\[uploader:([^\]]+?)\]\]'),
      (m) => '[@${m.group(1)}](wiki:up:${Uri.encodeComponent(m.group(1)!)})',
    );
    return result;
  }

  String _processAll(String text) {
    return _processWikiLinks(_processMath(text));
  }

  @override
  Widget build(BuildContext context) {
    // 自定义 onTapLink: 拦截 wiki: 链接
    return MarkdownBody(
      data: _processAll(data),
      selectable: selectable,
      styleSheet: styleSheet,
      onTapLink: (text, href, title) {
        if (href == null) return;
        // 我们自己的 wiki 链接
        if (href.startsWith('wiki:')) {
          onWikiLinkTap?.call(text, href, title);
          return;
        }
        // 外部链接 - 默认行为 (打开浏览器)
        // flutter_markdown 默认会处理
      },
    );
  }
}
