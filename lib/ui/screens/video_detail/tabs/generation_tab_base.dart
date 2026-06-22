import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/generation_provider.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/storage/database.dart' show Summary;
import 'package:mikunotes/ui/screens/video_detail/widgets/shared_data.dart';
import 'package:mikunotes/ui/screens/video_detail/widgets/summaries_list_sheet.dart';

/// 三 tab (摘要 / 评论 / 弹幕) 共用的基类
///
/// 设计目标:
/// - 子类只声明 source 和空状态 UI, 其他 90% 逻辑复用
/// - 共享 build() 主分支 (selected / streaming / empty / error)
/// - 共享 streaming view / error view / summary view / bottom action bar
/// - 加新 source (如 wiki 总结) 只需 ~100 行
///
/// 用法:
/// ```dart
/// class SummaryTab extends GenerationTab<SummaryTab> {
///   const SummaryTab({super.key, required this.bvid, ...});
///   final String bvid;
///   final VideoSubtitle? subtitle;  // summary 用 widget 传入的 subtitle
///
///   @override GenerationSource get source => GenerationSource.summary;
///   @override String get emptyStateLabel => '请先下载字幕';
///   ...
/// }
///
/// class _SummaryTabState extends GenerationTabState<SummaryTab> {
///   @override
///   Widget get emptyState => const EmptyDataState(
///     icon: Icons.subtitles_off,
///     label: '请先下载字幕',
///     downloadButtonLabel: '下载字幕',
///     onDownload: null,  // summary 字幕从 appbar 下载
///   );
/// }
/// ```
abstract class GenerationTab<T extends GenerationTab<T>>
    extends ConsumerStatefulWidget {
  /// 视频 ID (BV 号)
  final String bvid;

  /// 当前分P (0 = 整体)
  final int selectedPage;

  /// 触发下载的回调 (从父组件 VideoDetailScreen 传入)
  final VoidCallback? onDownloadRequest;

  /// summary 专用: 字幕 (从父组件传入, 不需要自己 load)
  final VideoSubtitle? subtitle;

  /// 总结变化后回调 (summary 通知父组件刷新, comment/danmaku 不需要)
  final VoidCallback? onSummaryChanged;

  /// subtitle/pageCount 仅 summary 用 (其他 tab 忽略)
  final int pageCount;

  const GenerationTab({
    super.key,
    required this.bvid,
    this.selectedPage = 0,
    this.subtitle,
    this.onDownloadRequest,
    this.onSummaryChanged,
    this.pageCount = 1,
  });

  /// 子类必须实现: 这是哪个 source
  GenerationSource get source;

  /// 子类必须实现: 源标签 (用于提示文案)
  String get sourceLabel;

  /// 子类必须实现: 模板类型 (用于 _pickTemplate)
  TemplateType get templateType;

  /// 子类必须实现: 当前激活的模板 ID (从 templatesProvider)
  String? activeTemplateId(PromptTemplateSet t);

  /// 子类必须实现: 模板列表 (用于 _pickTemplate)
  List<PromptTemplate> availableTemplates(PromptTemplateSet t);

  /// 子类实现: source 类型描述 (给日志/调试用)
  String get sourceName => source.name;
}

/// 基类 state — 公共逻辑都在这里
abstract class GenerationTabState<T extends GenerationTab<T>>
    extends ConsumerState<T> {
  bool _loading = true;
  String? _error;
  List<Summary> _summaries = [];
  String? _selectedSummaryId;

  // 公共 getters
  bool get loading => _loading;
  String? get error => _error;
  List<Summary> get summaries => _summaries;
  String? get selectedSummaryId => _selectedSummaryId;

  // ─── 生命周期 ──────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// 默认实现: 加载 summaries + 选中最新
  /// 子类可 override 添加自己的 source data 加载
  @mustCallSuper
  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bvid != widget.bvid || oldWidget.selectedPage != widget.selectedPage) {
      _reload();
    }
  }

  /// 统一 reload 入口 (子类的 loadSourceData 被调用)
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await loadSourceData();  // 子类实现: 加载评论/弹幕/字幕
      await loadSummaries();   // 基类提供
      _autoSelectLatest();
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 默认实现: 只加载 summaries (过滤 source-specific)
  /// 子类可 override 提供额外的 source data 加载
  @protected
  Future<void> loadSourceData() async {
    // 默认无操作, 子类 override (summary 用 widget.subtitle, 不需要 load)
  }

  /// 加载 summaries (基类使用, 不需要子类覆盖)
  @protected
  Future<void> loadSummaries() async {
    final dbLocal = ref.read(databaseProvider);
    final all = await dbLocal.getSummariesForVideo(widget.bvid);
    // 过滤 page: 0=全部, N=仅 N
    final pageFiltered = widget.selectedPage == 0
        ? all
        : all.where((s) => s.page == widget.selectedPage).toList();
    _summaries = pageFiltered
        .where((s) => _isMySummary(s))
        .toList();
  }

  /// 子类必须实现: 判断 summary 是否属于本 source
  /// 默认实现: 用 promptUsed 前缀判断
  bool _isMySummary(Summary s) {
    final src = widget.source.name;  // 'summary' / 'comment' / 'danmaku'
    return s.promptUsed == src || s.promptUsed.startsWith('${src}_');
  }

  /// 自动选中最新总结 (如果没有选中)
  void _autoSelectLatest() {
    if (_summaries.isNotEmpty && _selectedSummaryId == null) {
      _selectedSummaryId = _summaries.first.id;
    } else if (_selectedSummaryId != null &&
        !_summaries.any((s) => s.id == _selectedSummaryId)) {
      _selectedSummaryId = _summaries.isNotEmpty ? _summaries.first.id : null;
    }
  }

  // ─── 用户事件 ──────────────────────────────────────────

  /// 用户点击"生成"按钮 (主操作)
  Future<void> onMainAction() async {
    // ⭐ 等待 AI 配置 + 模板加载
    await Future.wait([
      ref.read(aiConfigProvider.notifier).ensureLoaded(),
      ref.read(templatesProvider.notifier).ensureLoaded(),
    ]);
    if (ref.read(aiConfigProvider).apiKey.isEmpty) {
      if (mounted) showAppSnackBar(context, '请先配置 AI', isError: true);
      return;
    }
    if (!hasSourceData) {
      if (mounted) showAppSnackBar(context, '请先准备数据');
      return;
    }

    // 选模板
    final templates = ref.read(templatesProvider);
    final templateId = await showTemplatePicker(
      context,
      title: '选${widget.sourceLabel}模板',
      templates: widget.availableTemplates(templates),
      activeId: widget.activeTemplateId(templates),
    );
    if (templateId == null) return;  // 用户取消

    // fetch video title (用于 system prompt 模板)
    final videoTitle = await _fetchVideoTitle();
    if (!mounted) return;

    // 调用子类实现的 doGenerate (在 state 里)
    await doGenerate(templateId: templateId, videoTitle: videoTitle);
    if (mounted) await _reload();  // 刷新 summaries
    widget.onSummaryChanged?.call();
  }

  /// 用户点击"继续生成"按钮 (从已有 summary 续写)
  Future<void> onContinueSummary(Summary selected) async {
    await ref.read(aiConfigProvider.notifier).ensureLoaded();
    if (ref.read(aiConfigProvider).apiKey.isEmpty) {
      if (mounted) showAppSnackBar(context, '请先配置 AI', isError: true);
      return;
    }
    final videoTitle = await _fetchVideoTitle();
    if (!mounted) return;
    await doContinueSummary(selected, videoTitle: videoTitle);
    if (mounted) await _reload();
    widget.onSummaryChanged?.call();
  }

  /// 用户点击"历史"按钮 → 弹 sheet 选择
  void onHistoryTap() {
    if (_summaries.isEmpty) {
      showAppSnackBar(context, '还没有历史总结');
      return;
    }
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
          if (mounted) await _reload();
          widget.onSummaryChanged?.call();
        },
      ),
    );
  }

  /// 用户点击"最新"按钮 (从历史回到最新)
  void onShowLatest() {
    setState(() => _selectedSummaryId = null);
  }

  /// 用户取消生成
  void onCancel() {
    ref.read(generationProvider.notifier).cancel(widget.bvid);
  }

  /// 用户清除 genState (生成完成后, 回到 summary view)
  void onClearGeneration() {
    ref.read(generationProvider.notifier).clear(widget.bvid);
    if (mounted) setState(() {});
  }

  /// 用户删除 summary
  Future<void> onDeleteSummary(Summary s) async {
    await ref.read(videoRepositoryProvider).deleteSummary(s.id);
    if (mounted) await _reload();
    widget.onSummaryChanged?.call();
  }

  // ─── 辅助方法 ──────────────────────────────────────────

  Future<String?> _fetchVideoTitle() async {
    try {
      final bili = ref.read(bilibiliClientProvider);
      final info = await bili.getVideoInfo(widget.bvid);
      return info['title'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─── 主 UI: build() ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('错误: $_error'));

    final genState = ref.watch(generationProvider)[widget.bvid];

    // 选择主内容
    final Widget content;
    if (_summaries.isNotEmpty && _selectedSummaryId != null && genState == null) {
      content = _buildSelectedSummaryView(genState);
    } else if (genState != null &&
        genState.source == widget.source &&
        (genState.isRunning || genState.isCompleted)) {
      content = _buildStreamingView(genState);
    } else if (genState != null &&
        genState.source == widget.source &&
        genState.error != null) {
      content = _buildErrorView(genState);
    } else {
      content = _buildDataOrEmptyView(genState);
    }

    // ⭐ 其他 source 在生成时, 加顶部 banner (明确反馈跨 tab 状态)
    return _wrapWithOtherSourceBanner(content, genState);
  }

  /// 包装: 当其他 source 在生成时, 顶部加 banner
  Widget _wrapWithOtherSourceBanner(Widget content, GenerationState? genState) {
    final other = genState;
    if (other == null) return content;
    if (other.source == widget.source) return content;
    if (!other.isRunning) return content;
    final src = other.source;  // local for type promotion
    final sourceLabel = _sourceLabel(src);
    return Column(
      children: [
        _buildOtherSourceBanner(sourceLabel, other),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildOtherSourceBanner(String sourceLabel, GenerationState genState) {
    return Material(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$sourceLabel 正在生成中... ${genState.content.length} 字',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(generationProvider.notifier).cancel(widget.bvid);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('取消'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sourceLabel(GenerationSource? source) {
    return switch (source) {
      GenerationSource.summary => '摘要',
      GenerationSource.comment => '评论',
      GenerationSource.danmaku => '弹幕',
      GenerationSource.chat => '对话',
      null => '生成',
    };
  }

  Widget _buildSelectedSummaryView(GenerationState? genState) {
    final selected = _summaries.firstWhere(
      (s) => s.id == _selectedSummaryId,
      orElse: () => _summaries.first,
    );
    return Column(
      children: [
        // 顶部: 状态文字 + 工具栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '历史 (${_summaries.length}) · 选中 #${selected.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SummaryToolbar(
                content: selected.content,
                sourceType: _sourceType(),
                onDownloadSettings: widget.onDownloadRequest,
              ),
              IconButton(
                tooltip: '回到最新',
                icon: const Icon(Icons.arrow_back, size: 18),
                onPressed: onShowLatest,
              ),
            ],
          ),
        ),
        Expanded(child: SummaryView(summary: selected)),
        // ⭐ 底部: 三按钮一排 (历史/继续/重新生成)
        BottomActionBar(
          historyLabel: '历史 (${_summaries.length})',
          onHistory: onHistoryTap,
          onContinue: () => onContinueSummary(selected),
          mainActionLabel: '重新生成',
          onMainAction: onMainAction,
          isRunning: isRunning(genState),
        ),
      ],
    );
  }

  Widget _buildStreamingView(GenerationState genState) {
    return Column(
      children: [
        const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 0),
          child: Row(children: [
            const Icon(Icons.auto_awesome, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                genState.isRunning
                    ? 'AI 思考中… ${genState.content.length} 字'
                    : '已完成 ${genState.content.length} 字',
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SummaryToolbar(
              content: genState.content,
              sourceType: _sourceType(),
              onDownloadSettings: widget.onDownloadRequest,
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              genState.content.isEmpty ? '(AI 思考中…)' : genState.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        BottomActionBar(
          historyLabel: _summaries.isNotEmpty ? '历史 (${_summaries.length})' : '历史',
          onHistory: onHistoryTap,
          onContinue: null,
          mainActionLabel: genState.isCompleted ? '查看总结' : '停止生成',
          mainActionIcon: genState.isCompleted ? Icons.check : Icons.stop,
          onMainAction: genState.isCompleted ? onClearGeneration : onCancel,
          isRunning: !genState.isCompleted,
        ),
      ],
    );
  }

  Widget _buildErrorView(GenerationState genState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('生成失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(genState.error ?? '',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onClearGeneration,
              icon: const Icon(Icons.refresh),
              label: const Text('清除状态'),
            ),
          ],
        ),
      ),
    );
  }

  /// 子类必须实现: 决定空状态 vs 有数据无总结 的视图
  Widget _buildDataOrEmptyView(GenerationState? genState);

  // ─── 内部辅助 ──────────────────────────────────────────

  /// 当前 source 对应的 UI 标识 (用于 SummaryToolbar)
  SourceType _sourceType() {
    return switch (widget.source) {
      GenerationSource.summary => SourceType.summary,
      GenerationSource.comment => SourceType.comment,
      GenerationSource.danmaku => SourceType.danmaku,
      GenerationSource.chat => SourceType.summary,  // chat 不在这里
    };
  }

  /// 当前是否在运行 (用于禁用底部按钮) - 公开让子类用
  bool isRunning(GenerationState? genState) {
    return genState?.source == widget.source && (genState?.isRunning ?? false);
  }

  // ─── 子类 override (可访问 ref/mounted/context) ──────────

  /// 子类实现: 是否有数据可生成 (用于启用"生成"按钮)
  bool get hasSourceData;

  /// 子类实现: 生成入口 (调 generationProvider.start*Generation)
  Future<void> doGenerate({
    required String? templateId,
    required String? videoTitle,
  });

  /// 子类实现: 续生成入口
  Future<void> doContinueSummary(
    Summary selected, {
    required String? videoTitle,
  });
}
