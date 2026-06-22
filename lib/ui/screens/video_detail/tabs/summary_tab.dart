import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/providers/generation_provider.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/storage/database.dart' show Summary;
import 'package:mikunotes/ui/screens/video_detail/tabs/generation_tab_base.dart';
import 'package:mikunotes/ui/screens/video_detail/widgets/shared_data.dart';

/// 摘要 Tab — 继承 GenerationTab 基类, 只实现差异点
class SummaryTab extends GenerationTab<SummaryTab> {
  const SummaryTab({
    super.key,
    required super.bvid,
    this.subtitle,
    required this.onChanged,
    this.selectedPage = 1,
    this.pageCount = 1,
  }) : super(
          subtitle: subtitle,
          onSummaryChanged: onChanged,
          selectedPage: selectedPage,
          pageCount: pageCount,
        );

  final VideoSubtitle? subtitle;
  final VoidCallback onChanged;
  final int selectedPage;
  final int pageCount;

  @override
  GenerationSource get source => GenerationSource.summary;
  @override
  String get sourceLabel => '摘要';
  @override
  TemplateType get templateType => TemplateType.summary;
  @override
  String? activeTemplateId(PromptTemplateSet t) => t.activeSummaryId;
  @override
  List<PromptTemplate> availableTemplates(PromptTemplateSet t) => t.summaries;
  @override
  // hasSourceData 在 state 实现

  @override
  ConsumerState<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends GenerationTabState<SummaryTab> {
  @override
  bool get hasSourceData => widget.subtitle != null;

  @override
  Future<void> doGenerate({
    required String? templateId,
    required String? videoTitle,
  }) async {
    // 确保用当前选中页面的字幕
    final repo = ref.read(videoRepositoryProvider);
    final page = widget.selectedPage == 0 ? null : widget.selectedPage;
    final sub = widget.subtitle?.videoId == widget.bvid
        ? widget.subtitle
        : await repo.getSubtitle(widget.bvid, page: page);
    if (sub == null || sub.entries.isEmpty) {
      if (mounted) showAppSnackBar(context, '请先下载字幕', isError: true);
      return;
    }
    await ref.read(generationProvider.notifier).startSummaryGeneration(
      bvid: widget.bvid,
      subtitle: sub,
      templateId: templateId,
      page: widget.selectedPage,
      videoTitle: videoTitle,
    );
  }

  @override
  Future<void> doContinueSummary(
    Summary selected, {
    required String? videoTitle,
  }) async {
    if (widget.subtitle == null) {
      if (mounted) {
        showAppSnackBar(context, '需要先有字幕才能继续生成', isError: true);
      }
      return;
    }
    await ref.read(generationProvider.notifier).continueSummary(
      bvid: widget.bvid,
      subtitle: widget.subtitle!,
      existingContent: selected.content,
      page: selected.page,
      videoTitle: videoTitle,
    );
  }

  @override
  Widget buildDataOrEmptyView(GenerationState? genState) {
    if (!hasSourceData) {
      return EmptyDataState(
        icon: Icons.subtitles_off,
        label: '请先下载字幕',
        downloadButtonLabel: '下载字幕',
        onDownload: widget.onDownloadRequest,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  summaries.isNotEmpty
                      ? '最新总结 · ${_formatTime(summaries.first.createdAt)}'
                      : '视频已下载, 点击下方生成总结',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SummaryToolbar(
                content: summaries.isNotEmpty ? summaries.first.content : '',
                sourceType: SourceType.summary,
              ),
            ],
          ),
        ),
        Expanded(
          child: summaries.isEmpty
              ? const Center(child: Text('暂无总结, 点击下方"生成 AI 总结"'))
              : SummaryView(summary: summaries.first),
        ),
        BottomActionBar(
          historyLabel: summaries.isNotEmpty ? '历史 (${summaries.length})' : '历史',
          onHistory: onHistoryTap,
          onContinue: null,
          mainActionLabel: '生成 AI 总结',
          onMainAction: onMainAction,
          isRunning: isRunning(genState),
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
}
