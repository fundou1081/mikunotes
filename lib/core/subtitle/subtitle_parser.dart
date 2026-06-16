import 'dart:convert';
import 'package:mikunotes/core/models/subtitle.dart';

/// B站 CC 字幕 JSON → SRT 文本 → 结构化数据
class SubtitleParser {
  /// 解析 B站 CC JSON 格式字幕 (用于已从数据库读取的)
  static List<SubtitleEntry> parseBilibiliJson(String jsonString) {
    final data = _lenientDecode(jsonString);
    final body = data['body'] as List<dynamic>? ?? [];

    return body.asMap().entries.map((e) {
      final item = e.value as Map<String, dynamic>;
      return SubtitleEntry(
        index: e.key + 1,
        from: (item['from'] as num).toDouble(),
        to: (item['to'] as num).toDouble(),
        content: item['content'] as String? ?? '',
      );
    }).toList();
  }

  /// 从已解析的 Map 创建字幕条目
  static List<SubtitleEntry> fromMap(Map<String, dynamic> data) {
    final body = data['body'] as List<dynamic>? ?? [];
    return body.asMap().entries.map((e) {
      final item = e.value as Map<String, dynamic>;
      return SubtitleEntry(
        index: e.key + 1,
        from: (item['from'] as num).toDouble(),
        to: (item['to'] as num).toDouble(),
        content: item['content'] as String? ?? '',
      );
    }).toList();
  }

  /// 宽松 JSON 解析: 先标准 jsonDecode，失败则补引号再试
  static Map<String, dynamic> _lenientDecode(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      final fixed = raw.replaceAllMapped(
        RegExp(r'(?<=[{,])\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:', multiLine: true),
        (m) => '"${m.group(1)}":',
      );
      return jsonDecode(fixed) as Map<String, dynamic>;
    }
  }

  /// 字幕条目列表 → 纯文本 (用于 LLM)
  static String toPlainText(List<SubtitleEntry> entries) {
    return entries.map((e) => e.content).join('\n');
  }

  /// 字幕条目列表 → SRT 格式
  static String toSrt(List<SubtitleEntry> entries) {
    final buf = StringBuffer();
    for (final e in entries) {
      buf.writeln(e.index);
      buf.writeln('${_formatTime(e.from)} --> ${_formatTime(e.to)}');
      buf.writeln(e.content.replaceAll('\n', r'\N'));
      buf.writeln();
    }
    return buf.toString();
  }

  static String _formatTime(double seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toInt().toString().padLeft(2, '0');
    final ms =
        ((seconds - seconds.toInt()) * 1000).toInt().toString().padLeft(3, '0');
    return '$h:$m:$s,$ms';
  }
}
