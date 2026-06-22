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

// ─────────────────────────────────────────────────────────────────
// ⭐ 右上角工具栏 (三个 tab 复用) — 复制 + 下载设置菜单
// ─────────────────────────────────────────────────────────────────

enum SourceType { summary, comment, danmaku }

/// 右上角工具栏 — 复制 + 下载设置
class SummaryToolbar extends StatelessWidget {
  final String content; // 当前显示的总结内容 (用于复制)
  final SourceType sourceType;
  final VoidCallback? onDownloadSettings; // 点击「下载设置」后的回调

  const SummaryToolbar({
    super.key,
    required this.content,
    required this.sourceType,
    this.onDownloadSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 复制按钮
        IconButton(
          tooltip: '复制总结',
          icon: const Icon(Icons.copy, size: 20),
          onPressed: content.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: content));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制到剪贴板'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
        ),
        // 下载设置菜单 (跟复制并列)
        PopupMenuButton<String>(
          tooltip: '下载设置',
          icon: const Icon(Icons.settings, size: 20),
          onSelected: (v) {
            switch (v) {
              case 'settings':
                onDownloadSettings?.call();
                break;
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(children: [
                Icon(Icons.tune, size: 18),
                SizedBox(width: 8),
                Text('下载设置'),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ⭐ 底部动作栏 — 三个 tab 复用 — 历史/继续生成/重新生成
// ─────────────────────────────────────────────────────────────────

/// 底部动作栏 — 三个按钮排成一排
///
/// - historyLabel: 「历史 (N)」 或 「历史」 (无历史时)
/// - onContinue: null 表示不显示「继续生成」按钮 (如评论/弹幕 LLM 输出短, 默认不展示)
/// - mainActionLabel: 「生成 AI 总结」 或 「重新生成」
/// - mainActionIcon: 默认 auto_awesome
class BottomActionBar extends StatelessWidget {
  final String historyLabel;
  final VoidCallback onHistory;
  final VoidCallback? onContinue;
  final String? continueTooltip; // 「继续生成」按钮的 tooltip
  final String mainActionLabel;
  final VoidCallback onMainAction;
  final IconData mainActionIcon;
  final bool isRunning;

  const BottomActionBar({
    super.key,
    required this.historyLabel,
    required this.onHistory,
    required this.onContinue,
    required this.mainActionLabel,
    required this.onMainAction,
    this.continueTooltip,
    this.mainActionIcon = Icons.auto_awesome,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            // 历史按钮
            Expanded(
              child: OutlinedButton(
                onPressed: isRunning ? null : onHistory,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          historyLabel,  // 完整 label, 例如 '历史 (5)'
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 继续生成按钮 (可选)
            if (onContinue != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Tooltip(
                  message: continueTooltip ?? '点击从已有内容继续写',
                  child: FilledButton.tonal(
                    onPressed: isRunning ? null : onContinue,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_outline, size: 16),
                          SizedBox(width: 4),
                          Text('继续', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            // 重新生成 / 生成按钮
            Expanded(
              child: FilledButton(
                onPressed: isRunning ? null : onMainAction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(mainActionIcon, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          mainActionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ⭐ 全局 SnackBar helper — 浮起不遮挡 BottomActionBar
// ─────────────────────────────────────────────────────────────────

/// 显示 SnackBar, 浮起 + 底部留出 80px 空间 (避免遮挡 BottomActionBar 三按钮)
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      duration: duration,
      backgroundColor: isError ? Colors.red.shade700 : null,
    ),
  );
}
