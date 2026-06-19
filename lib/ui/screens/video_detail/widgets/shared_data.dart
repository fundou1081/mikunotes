import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/core/storage/database.dart' show Comment, DanmakuData;
import 'package:mikunotes/ui/screens/video_detail/math_markdown.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/danmaku_client.dart';
import 'package:mikunotes/core/bilibili/comment_client.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/prompt_template.dart';

import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/generation_provider.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/core/storage/database.dart' show Comment, DanmakuData;
import 'package:mikunotes/ui/screens/video_detail/math_markdown.dart';
import 'package:mikunotes/ui/screens/insight/wiki_viewer.dart' show WikiFileViewer;

/// 来源类型 (用于 chip 多选)
enum DataSource {
  subtitle('字幕'),
  comment('评论'),
  danmaku('弹幕');

  final String label;
  const DataSource(this.label);
}

/// 通用模板选择 Sheet (Summary/Comment/Danmaku 复用)
/// Returns: 选中的模板 id, 或 null (取消)
Future<String?> showTemplatePicker(
  BuildContext context, {
  required String title,
  required List<PromptTemplate> templates,
  required String? activeId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.description),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: templates.length,
                  itemBuilder: (ctx, i) {
                    final t = templates[i];
                    final isActive = t.id == activeId;
                    return ListTile(
                      leading: isActive
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.circle_outlined),
                      title: Text(t.name),
                      subtitle: Text(
                        t.content.replaceAll('\n', ' ').substring(
                            0,
                            t.content.length < 60
                                ? t.content.length
                                : 60),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: t.isBuiltIn
                          ? const Chip(label: Text('内置'))
                          : null,
                      onTap: () => Navigator.pop(ctx, t.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

// ─────────────────────────────────────────────────
// 评论 Tab — 跟摘要 tab 一样, 但 source = 'comment'

class EmptyDataState extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onDownload;
  final String? downloadButtonLabel;

  const EmptyDataState({
    required this.icon,
    required this.label,
    this.onDownload,
    this.downloadButtonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontSize: 14)),
            if (onDownload != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download),
                label: Text(downloadButtonLabel ?? '下载'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SummaryView extends StatelessWidget {
  final db.Summary summary;
  const SummaryView({required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MathMarkdownBody(
        data: summary.content,
        selectable: true,
      ),
    );
  }
}

class SummaryPicker extends StatelessWidget {
  final List<db.Summary> summaries;
  final String? selectedId;
  final Function(db.Summary) onSelect;
  final Function(db.Summary) onDelete;

  const SummaryPicker({
    required this.summaries,
    required this.selectedId,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const Text('历史:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: summaries.map((s) {
                  final isSel = s.id == selectedId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InputChip(
                      label: Text(_fmtDate(s.createdAt), style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      onSelected: (_) => onSelect(s),
                      onDeleted: () => onDelete(s),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
