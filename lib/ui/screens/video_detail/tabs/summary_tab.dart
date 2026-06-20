import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/generation_provider.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/ui/screens/video_detail/math_markdown.dart';
import 'package:mikunotes/ui/screens/video_detail/widgets/summaries_list_sheet.dart';

class SummaryTab extends ConsumerStatefulWidget {
  final String bvid;
  final VideoSubtitle? subtitle;
  final VoidCallback onChanged;
  final int selectedPage;
  final int pageCount;
  const SummaryTab({
    required this.bvid,
    required this.subtitle,
    required this.onChanged,
    this.selectedPage = 1,
    this.pageCount = 1,
  });

  @override
  ConsumerState<SummaryTab> createState() => SummaryTabState();
}

class SummaryTabState extends ConsumerState<SummaryTab> {
  bool _downloading = false;
  String? _selectedSummaryId; // 历史中选择的总结

  Future<void> _generateSummary({String? customPrompt, String? title}) async {
    // 确保用当前选中页面的字幕 (而不是旧的 widget.subtitle)
    final repo = ref.read(videoRepositoryProvider);
    final page = widget.selectedPage == 0 ? null : widget.selectedPage;
    final subtitle = widget.subtitle?.videoId == widget.bvid
        ? widget.subtitle
        : await repo.getSubtitle(widget.bvid, page: page);
    if (subtitle == null || subtitle.entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先下载字幕')),
      );
      return;
    }
    if (ref.read(aiConfigProvider).apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置 AI')),
      );
      return;
    }
    setState(() => _selectedSummaryId = null);
    // 如果没有自定义 prompt, 弹出模板选择器
    String? templateId;
    if (customPrompt == null) {
      templateId = await _pickSummaryTemplate();
      if (templateId == null) return; // 用户取消
    }
    // fetch video title
    String? videoTitle;
    try {
      final bili = ref.read(bilibiliClientProvider);
      final info = await bili.getVideoInfo(widget.bvid);
      videoTitle = info['title'] as String?;
    } catch (_) { /* ignore - fallback to 'BV $bvid' */ }
    await ref.read(generationProvider.notifier).startSummaryGeneration(
      bvid: widget.bvid,
      subtitle: subtitle,
      customPrompt: customPrompt,
      templateId: templateId,
      page: widget.selectedPage,
      videoTitle: videoTitle,
    );
  }

  /// 摘要模板选择器（可取消 → 返回 null）
  Future<String?> _pickSummaryTemplate() async {
    final templates = ref.read(templatesProvider);
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
                    const Text('选摘要模板', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: templates.summaries.length,
                    itemBuilder: (ctx, i) {
                      final t = templates.summaries[i];
                      final isActive = t.id == templates.activeSummaryId;
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

  Future<void> _copySummary(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ 已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 提示信息: 显示当前 max_tokens, 帮用户判断是不是被截断
  String _continueTooltip(summary_model.Summary s) {
    final config = ref.read(aiConfigProvider);
    final curLen = s.content.length;
    final maxTok = config.maxTokens;
    final approxMaxChars = (maxTok * 1.5).toInt();
    return '当前内容: $curLen 字\n'
        'max_tokens: $maxTok (~ $approxMaxChars 字)\n'
        '点击从已有内容继续写';
  }

  /// 从已有总结内容继续生成 (用于被 max_tokens 截断后)
  Future<void> _continueSummary(summary_model.Summary s) async {
    if (widget.subtitle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要先有字幕才能继续生成')),
      );
      return;
    }
    // fetch video title
    String? videoTitle;
    try {
      final bili = ref.read(bilibiliClientProvider);
      final info = await bili.getVideoInfo(widget.bvid);
      videoTitle = info['title'] as String?;
    } catch (_) { /* ignore - fallback to 'BV $bvid' */ }
    await ref.read(generationProvider.notifier).continueSummary(
      bvid: widget.bvid,
      subtitle: widget.subtitle!,
      existingContent: s.content,
      page: s.page,
      videoTitle: videoTitle,
    );
    // 刷新总结列表
    widget.onChanged();
  }

  void _showExistingSummaries() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SummariesListSheet(
        bvid: widget.bvid,
        onSelect: (s) {
          Navigator.pop(ctx);
          setState(() => _selectedSummaryId = s.id);
        },
        onDelete: (s) async {
          await ref.read(videoRepositoryProvider).deleteSummary(s.id);
          widget.onChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subtitle == null) return _noSubtitleState();
    if (_downloading) return const Center(child: CircularProgressIndicator());

    final genState = ref.watch(generationProvider)[widget.bvid];
    return FutureBuilder<List<summary_model.Summary>>(
      future: ref.read(videoRepositoryProvider).getAllSummaries(widget.bvid),
      builder: (ctx, snap) {
        final summaries = snap.data ?? [];
        // 按页面过滤 (0=整体显示全部, 1+ 只显示对应页)
        final pageFiltered = widget.selectedPage == 0
            ? summaries
            : summaries.where((s) => s.page == widget.selectedPage).toList();
        final latest = pageFiltered.isNotEmpty ? pageFiltered.first : null;

        // 选中的历史总结
        if (_selectedSummaryId != null) {
          final selected = pageFiltered.firstWhere(
            (s) => s.id == _selectedSummaryId,
            orElse: () => latest!,
          );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children: [
                  Text('历史: ${selected.title}', style: Theme.of(context).textTheme.labelMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedSummaryId = null),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('最新'),
                  ),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: MathMarkdownBody(
                    data: selected.content,
                    selectable: true,
                  ),
                ),
              ),
            ],
          );
        }

        // 正在后台生成 (或刚完成 2 秒内, 保持 streaming view 避免空状念闪哾)
        if (genState != null && (genState.isRunning || genState.isCompleted)) {
          return Column(
            children: [
              const LinearProgressIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    genState.content.isEmpty ? '(AI 思考中…)' : genState.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    // ignore: unnecessary_non_null_assertion
                    if (genState!.isCompleted) {
                      // 已完成 → 立即跳到总结视图
                      ref.read(generationProvider.notifier).clear(widget.bvid);
                    } else {
                      ref.read(generationProvider.notifier).cancel(widget.bvid);
                    }
                  },
                  // ignore: unnecessary_non_null_assertion
                  icon: Icon(genState!.isCompleted ? Icons.check : Icons.stop),
                  // ignore: unnecessary_non_null_assertion
                  label: Text(genState!.isCompleted ? '查看总结' : '停止生成'),
                ),
              ),
            ],
          );
        }

        // 生成失败
        if (genState != null && genState.error != null) {
          return _buildError(genState.error!, latest);
        }

        // 有已保存的总结
        if (latest != null) {
          return _buildSummaryView(latest, pageFiltered);
        }

        // 空状态
        return _buildEmpty();
      },
    );
  }

  Widget _buildError(String error, summary_model.Summary? latest) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _generateSummary,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ]),
      ),
    );
  }

  Widget _buildSummaryView(summary_model.Summary s, List<summary_model.Summary> all) {
    return Column(
      children: [
        // 顶部菜单栏 (复制/查看原文 等)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Text(
                '总结 #${s.id.substring(0, 8)} · ${_formatTime(s.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                tooltip: '更多操作',
                onSelected: (v) {
                  if (v == 'copy') {
                    _copySummary(s.content);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(children: [
                      Icon(Icons.copy, size: 18),
                      SizedBox(width: 8),
                      Text('复制全部内容'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MathMarkdownBody(
              data: s.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                h1: Theme.of(context).textTheme.headlineSmall,
                h2: Theme.of(context).textTheme.titleMedium,
                h3: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _showExistingSummaries,
                  icon: const Icon(Icons.history, size: 18),
                  label: Text('历史 (${all.length})'),
                ),
                Tooltip(
                  message: _continueTooltip(s),
                  child: FilledButton.tonalIcon(
                    onPressed: () => _continueSummary(s),
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text('继续生成'),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _generateSummary,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('重新生成'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${t.year}-${t.month.toString().padLeft(2, "0")}-${t.day.toString().padLeft(2, "0")}';
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _generateSummary,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('生成 AI 总结'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showExistingSummaries,
              icon: const Icon(Icons.history),
              tooltip: '历史总结',
            ),
          ]),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _noSubtitleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.subtitles_off, size: 64),
            const SizedBox(height: 16),
            const Text('请先下载字幕'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                setState(() => _downloading = true);
                try {
                  final repo = ref.read(videoRepositoryProvider);
                  await repo.downloadAllSubtitles(widget.bvid);
                  widget.onChanged();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _downloading = false);
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('下载字幕'),
            ),
          ],
        ),
      ),
    );
  }
}

