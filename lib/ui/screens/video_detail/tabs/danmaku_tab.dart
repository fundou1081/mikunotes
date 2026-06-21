import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/providers/generation_provider.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/storage/database.dart' show DanmakuData, Summary;
import 'package:mikunotes/ui/screens/video_detail/tabs/generation_tab_base.dart';
import 'package:mikunotes/ui/screens/video_detail/widgets/shared_data.dart';

/// 弹幕 Tab — 继承 GenerationTab 基类
class DanmakuTab extends GenerationTab<DanmakuTab> {
  const DanmakuTab({
    super.key,
    required super.bvid,
    this.selectedPage = 0,
    this.onDownloadRequest,
  }) : super(selectedPage: selectedPage, onDownloadRequest: onDownloadRequest);

  final int selectedPage;
  final VoidCallback? onDownloadRequest;

  @override
  GenerationSource get source => GenerationSource.danmaku;
  @override
  String get sourceLabel => '弹幕';
  @override
  TemplateType get templateType => TemplateType.danmaku;
  @override
  String? activeTemplateId(PromptTemplateSet t) => t.activeDanmakuId;
  @override
  List<PromptTemplate> availableTemplates(PromptTemplateSet t) => t.danmakus;

  @override
  ConsumerState<DanmakuTab> createState() => _DanmakuTabState();
}

class _DanmakuTabState extends GenerationTabState<DanmakuTab> {
  List<DanmakuData> _danmaku = [];

  @override
  bool get hasSourceData => _danmaku.isNotEmpty;

  @override
  Future<void> loadSourceData() async {
    final dbLocal = ref.read(databaseProvider);
    _danmaku = await dbLocal.getDanmakuForVideo(widget.bvid, page: _page);
  }

  int get _page => widget.selectedPage == 0 ? 1 : widget.selectedPage;

  @override
  Future<void> doGenerate({
    required String? templateId,
    required String? videoTitle,
  }) async {
    if (_danmaku.isEmpty) {
      if (mounted) showAppSnackBar(context, '请先点击上方「下载弹幕」');
      return;
    }
    await ref.read(generationProvider.notifier).startDanmakuGeneration(
      bvid: widget.bvid,
      danmaku: _danmaku,
      templateId: templateId,
      page: _page,
      videoTitle: videoTitle,
    );
  }

  @override
  Future<void> doContinueSummary(
    Summary selected, {
    required String? videoTitle,
  }) async {
    if (_danmaku.isEmpty) {
      if (mounted) showAppSnackBar(context, '请先下载弹幕');
      return;
    }
    await ref.read(generationProvider.notifier).continueDanmakuGeneration(
      bvid: widget.bvid,
      danmaku: _danmaku,
      existingContent: selected.content,
      page: _page,
      videoTitle: videoTitle,
    );
  }

  @override
  Widget _buildDataOrEmptyView(GenerationState? genState) {
    if (_danmaku.isEmpty) {
      return EmptyDataState(
        icon: Icons.lightbulb_outline,
        label: '请先下载弹幕',
        downloadButtonLabel: '下载弹幕',
        onDownload: widget.onDownloadRequest,
      );
    }
    return _buildDataView(genState);
  }

  Widget _buildDataView(GenerationState? genState) {
    return Column(
      children: [
        // 顶部: 数据信息条
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '共 ${_danmaku.length} 条弹幕',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              IconButton(
                tooltip: '重新下载弹幕',
                icon: Icon(Icons.refresh, size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
                onPressed: widget.onDownloadRequest,
              ),
            ],
          ),
        ),
        const Spacer(),
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
}
