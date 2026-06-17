import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Detect $...$ inline math in Markdown, render with monospace style
class MathInlineSyntax extends md.InlineSyntax {
  MathInlineSyntax() : super(r'\$([^$]+)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.text('math-inline', match.group(1)!);
    parser.addNode(element);
    return true;
  }
}

class MathElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Text(
        element.textContent,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Markdown widget with $...$ math rendering support
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

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: data,
      selectable: selectable,
      styleSheet: styleSheet,
      builders: {'math-inline': MathElementBuilder()},
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          MathInlineSyntax(),
        ],
      ),
    );
  }
}
