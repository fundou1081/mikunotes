import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/providers/generation_provider.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/storage/database.dart' show Comment, Summary;
import 'package:mikunotes/ui/screens/video_detail/tabs/generation_tab_base.dart';
import 'package:mikunotes/ui/screens/video_detail/widgets/shared_data.dart';

/// 评论 Tab — 继承 GenerationTab 基类
class CommentTab extends GenerationTab<CommentTab> {
  const CommentTab({
    super.key,
    required super.bvid,
    this.selectedPage = 0,
    this.onDownloadRequest,
  }) : super(selectedPage: selectedPage, onDownloadRequest: onDownloadRequest);

  final int selectedPage;
  final VoidCallback? onDownloadRequest;

  @override
  GenerationSource get source => GenerationSource.comment;
  @override
  String get sourceLabel => '评论';
  @override
  TemplateType get templateType => TemplateType.comment;
  @override
  String? activeTemplateId(PromptTemplateSet t) => t.activeCommentId;
  @override
  List<PromptTemplate> availableTemplates(PromptTemplateSet t) => t.comments;

  @override
  ConsumerState<CommentTab> createState() => _CommentTabState();
}

class _CommentTabState extends GenerationTabState<CommentTab> {
  List<Comment> _comments = [];

  @override
  bool get hasSourceData => _comments.isNotEmpty;

  @override
  Future<void> loadSourceData() async {
    final dbLocal = ref.read(databaseProvider);
    _comments = await dbLocal.getCommentsForVideo(widget.bvid, page: _page);
  }

  int get _page => widget.selectedPage == 0 ? 1 : widget.selectedPage;

  @override
  Future<void> doGenerate({
    required String? templateId,
    required String? videoTitle,
  }) async {
    if (_comments.isEmpty) {
      if (mounted) showAppSnackBar(context, '请先点击上方「下载评论」');
      return;
    }
    await ref.read(generationProvider.notifier).startCommentGeneration(
      bvid: widget.bvid,
      comments: _comments,
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
    if (_comments.isEmpty) {
      if (mounted) showAppSnackBar(context, '请先下载评论');
      return;
    }
    await ref.read(generationProvider.notifier).continueCommentGeneration(
      bvid: widget.bvid,
      comments: _comments,
      existingContent: selected.content,
      page: _page,
      videoTitle: videoTitle,
    );
  }

  @override
  Widget _buildDataOrEmptyView(GenerationState? genState) {
    if (_comments.isEmpty) {
      return EmptyDataState(
        icon: Icons.comment_outlined,
        label: '请先下载评论',
        downloadButtonLabel: '下载评论',
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
              Icon(Icons.comment, color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '共 ${_comments.length} 条评论',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              IconButton(
                tooltip: '重新下载评论',
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
