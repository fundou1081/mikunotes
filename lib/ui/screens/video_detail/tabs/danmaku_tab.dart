import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/generation_provider.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/storage/database.dart' show DanmakuData, Summary;
import 'package:mikunotes/ui/screens/video_detail/widgets/shared_data.dart';

class DanmakuTab extends ConsumerStatefulWidget {
  final String bvid;
  final int selectedPage;
  final VoidCallback? onDownloadRequest;

  const DanmakuTab({
    super.key,
    required this.bvid,
    this.selectedPage = 1,
    this.onDownloadRequest,
  });

  @override
  ConsumerState<DanmakuTab> createState() => DanmakuTabState();
}

class DanmakuTabState extends ConsumerState<DanmakuTab> {
  List<DanmakuData> _danmaku = [];
  List<Summary> _summaries = [];
  bool _loading = true;
  String? _error;
  String? _selectedSummaryId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _page => widget.selectedPage == 0 ? 1 : widget.selectedPage;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dbLocal = ref.read(databaseProvider);
      _danmaku = await dbLocal.getDanmakuForVideo(widget.bvid, page: _page);
      _summaries = await dbLocal.getSummariesForVideo(widget.bvid)
          .then((list) => list.where((s) =>
              s.promptUsed == 'danmaku' ||
              s.promptUsed.startsWith('danmaku_')
          ).toList());
      // ⭐ 自动选中最新总结 (如果没有选中)
      if (_summaries.isNotEmpty && _selectedSummaryId == null) {
        _selectedSummaryId = _summaries.first.id;
      } else if (_selectedSummaryId != null && !_summaries.any((s) => s.id == _selectedSummaryId)) {
        _selectedSummaryId = _summaries.isNotEmpty ? _summaries.first.id : null;
      }
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    if (_danmaku.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先点击上方「下载弹幕」')),
      );
      return;
    }
    final templates = ref.read(templatesProvider);
    // 弹模板选择器 (跟摘要 tab 一样的 UX)
    final templateId = await showTemplatePicker(
      context,
      title: '选弹幕模板',
      templates: templates.danmakus,
      activeId: templates.activeDanmakuId,
    );
    if (templateId == null) return; // 用户取消

    // ⭐ 调用流式生成 (跟摘要 tab 一样, 实时显示)
    // fetch video title
    String? videoTitle;
    try {
      final bili = ref.read(bilibiliClientProvider);
      final info = await bili.getVideoInfo(widget.bvid);
      videoTitle = info['title'] as String?;
    } catch (_) { /* ignore - fallback to 'BV $bvid' */ }
    await ref.read(generationProvider.notifier).startDanmakuGeneration(
      bvid: widget.bvid,
      danmaku: _danmaku,
      templateId: templateId,
      page: _page,
      videoTitle: videoTitle,
    );
    // 完成后刷新列表
    if (mounted) _load();
  }

  String _fmtTime(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final h = m ~/ 60;
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}'
        : '${(m % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('错误: $_error'));

    final genState = ref.watch(generationProvider)[widget.bvid];

    // 有历史总结: 显示总结视图 + picker
    if (_summaries.isNotEmpty && _selectedSummaryId != null && genState == null) {
      return Column(
        children: [
          SummaryPicker(
            summaries: _summaries,
            selectedId: _selectedSummaryId,
            onSelect: (s) => setState(() => _selectedSummaryId = s.id),
            onDelete: (s) async {
              await ref.read(videoRepositoryProvider).deleteSummary(s.id);
              _load();
            },
          ),
          Expanded(
            child: SummaryView(summary: _summaries.firstWhere((s) => s.id == _selectedSummaryId)),
          ),
        ],
      );
    }

    // ⭐ 正在生成 (或刚完成, 避免闪屏)
    if (genState != null && genState.source == GenerationSource.danmaku && (genState.isRunning || genState.isCompleted)) {
      return Column(
        children: [
          const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              const Icon(Icons.auto_awesome, size: 18),
              const SizedBox(width: 8),
              Text('${genState.content.length} 字 · ${genState.isCompleted ? "已完成" : "AI 思考中..."}',
                  style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () {
                  if (genState.isCompleted) {
                    ref.read(generationProvider.notifier).clear(widget.bvid);
                    if (mounted) setState(() {});
                  } else {
                    ref.read(generationProvider.notifier).cancel(widget.bvid);
                  }
                },
                icon: Icon(genState.isCompleted ? Icons.check : Icons.stop, size: 18),
                label: Text(genState.isCompleted ? '查看总结' : '停止'),
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
        ],
      );
    }

    // 生成失败
    if (genState != null && genState.source == GenerationSource.danmaku && genState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('生成失败', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(genState.error ?? '', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.read(generationProvider.notifier).clear(widget.bvid),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 空状态: 还没下载弹幕
    if (_danmaku.isEmpty) {
      return EmptyDataState(
        icon: Icons.lightbulb_outline,
        label: '请先下载弹幕',
        downloadButtonLabel: '下载弹幕',
        onDownload: widget.onDownloadRequest,
      );
    }

    // 有弹幕但还没总结: 显示生成按钮 + 历史入口 (跟 Summary tab 一致)
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '共 ${_danmaku.length} 条弹幕',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
                IconButton(
                  tooltip: '重新下载弹幕',
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: widget.onDownloadRequest,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: genState?.isRunning == true ? null : _generate,
                icon: const Icon(Icons.auto_awesome),
                label: Text(genState?.isRunning == true ? '生成中...' : '生成 AI 总结'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_summaries.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _selectedSummaryId = _summaries.first.id),
                icon: const Icon(Icons.history),
                tooltip: '历史总结',
              ),
            ],
          ]),
          const Spacer(),
        ],
      ),
    );
  }

}
// 原始数据 Tab — chip 多选 (字幕/评论/弹幕)
