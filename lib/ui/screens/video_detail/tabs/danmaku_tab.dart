import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/generation_provider.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/core/storage/database.dart' show DanmakuData;
import 'package:mikunotes/ui/screens/video_detail/math_markdown.dart';
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
  List<db.Summary> _summaries = [];
  bool _loading = true;
  bool _generating = false;
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
          .then((list) => list.where((s) => s.promptUsed.contains('danmaku')).toList());
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
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final config = ref.read(aiConfigProvider);
      if (config.apiKey.isEmpty) {
        throw '请先在设置配置 API Key';
      }
      // 弹模板选择器 (跟摘要 tab 一样的 UX)
      final templates = ref.read(templatesProvider);
      final templateId = await showTemplatePicker(
        context,
        title: '选弹幕模板',
        templates: templates.danmakus,
        activeId: templates.activeDanmakuId,
      );
      if (templateId == null) {
        setState(() => _generating = false);
        return; // 用户取消
      }
      final tpl0 = templates.danmakus.firstWhere((t) => t.id == templateId,
          orElse: () => templates.danmakus.first);
      final tpl = tpl0.content;
      // 把弹幕按时间排序
      _danmaku.sort((a, b) => a.progress.compareTo(b.progress));
      // 简单拼接 (限制长度)
      final text = _danmaku
          .map((d) => '[${_fmtTime(d.progress)}] ${d.content}')
          .join('\n');
      final bili = ref.read(bilibiliClientProvider);
      final info = await bili.getVideoInfo(widget.bvid);
      final title = info['title'] as String? ?? widget.bvid;
      // 用模板渲染
      final prompt = llm_tpl.PromptTemplate.render(tpl, {
        'video_title': title,
        'total': '${_danmaku.length}',
        'taken': '${_danmaku.length}',
        'text': text.length > 6000 ? '${text.substring(0, 6000)}...' : text,
      });
      final client = ref.read(llmClientProvider);
      final result = await client.chat(
        systemPrompt: '你是视频弹幕分析专家。',
        userMessage: prompt,
        maxTokens: 2000,
        disableReasoning: true,
      );
      await ref.read(videoRepositoryProvider).createSummary(
        bvid: widget.bvid,
        content: result,
        type: summary_model.SummaryType.structured,
        modelUsed: config.effectiveModel,
        promptUsed: 'danmaku_${tpl0.name}',
        page: _page,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ 弹幕总结已保存')),
      );
      _load();  // 重新加载, 让用户能切换到历史总结
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
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

    // 有历史总结: 显示总结视图 + picker
    if (_summaries.isNotEmpty && _selectedSummaryId != null) {
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
                onPressed: _generating ? null : _generate,
                icon: const Icon(Icons.auto_awesome),
                label: Text(_generating ? '生成中...' : '生成 AI 总结'),
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

// ─────────────────────────────────────────────────
// 原始数据 Tab — chip 多选 (字幕/评论/弹幕)
