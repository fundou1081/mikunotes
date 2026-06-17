import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 摘要 markdown 渲染: 把 $...$ 数学公式转成内联代码 (避开了
/// 自定义 InlineSyntax 跟 GFM 解析器的冲突, 保证整段 markdown 渲染正常)
class MathMarkdownBody extends StatelessWidget {
  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;
  const MathMarkdownBody({
    super.key,
    required this.data,
    this.selectable = true,
    this.styleSheet,
  });

  /// 把 $...$ 转成内联代码, 让 MarkdownBody 渲染为等宽灰底
  /// 避免引入自定义 InlineSyntax 破坏 GFM 解析
  String _processMath(String text) {
    return text.replaceAllMapped(
      RegExp(r'\$([^$\n]+?)\$'),
      (m) => '`${m.group(1)}`',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _processMath(data),
      selectable: selectable,
      styleSheet: styleSheet,
    );
  }
}
