import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:mikunotes/core/storage/database.dart' show Comment;
import 'package:mikunotes/ui/screens/video_detail/math_markdown.dart';
import 'package:mikunotes/ui/screens/video_detail/widgets/shared_data.dart';

class CommentTab extends ConsumerStatefulWidget {
  final String bvid;
  final int selectedPage;
  final VoidCallback? onDownloadRequest;

  const CommentTab({
    super.key,
    required this.bvid,
    this.selectedPage = 1,
    this.onDownloadRequest,
  });

  @override
  ConsumerState<CommentTab> createState() => CommentTabState();
}

class CommentTabState extends ConsumerState<CommentTab> {
  List<db.Summary> _summaries = [];
  List<db.Comment> _comments = [];
  bool _loading = true;
  bool _generating = false;
  String? _error;
  String? _selectedSummaryId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dbLocal = ref.read(databaseProvider);
      _comments = await dbLocal.getCommentsForVideo(widget.bvid, page: _page);
      _summaries = await dbLocal.getSummariesForVideo(widget.bvid)
          .then((list) => list.where((s) => s.promptUsed.contains('评论') || s.promptUsed.contains('community') || s.promptUsed.contains('舆情')).toList());
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _page => widget.selectedPage == 0 ? 1 : widget.selectedPage;



  Future<void> _generate() async {
    if (_comments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先点击上方「下载评论」')),
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
      final templates = ref.read(templatesProvider);
      // 弹模板选择器 (跟摘要 tab 一样的 UX)
      final templateId = await showTemplatePicker(
        context,
        title: '选评论模板',
        templates: templates.comments,
        activeId: templates.activeCommentId,
      );
      if (templateId == null) {
        setState(() => _generating = false);
        return; // 用户取消
      }
      final tpl0 = templates.comments.firstWhere((t) => t.id == templateId,
          orElse: () => templates.comments.first);
      final tpl = tpl0.content;
      // 拼装评论文本
      final text = _comments
          .map((c) => '【${c.likes}赞】${c.uname}: ${c.content}')
          .join('\n');
      final bili = ref.read(bilibiliClientProvider);
      final info = await bili.getVideoInfo(widget.bvid);
      final title = info['title'] as String? ?? widget.bvid;
      final prompt = llm_tpl.PromptTemplate.render(tpl, {
        'video_title': title,
        'total': '${_comments.length}',
        'taken': '${_comments.length}',
        'text': text.length > 8000 ? '${text.substring(0, 8000)}...(已截断)' : text,
      });
      final client = ref.read(llmClientProvider);
      final result = await client.chat(
        systemPrompt: '你是视频评论分析助手。',
        userMessage: prompt,
        maxTokens: 2000,
        disableReasoning: true,
      );
      await ref.read(videoRepositoryProvider).createSummary(
        bvid: widget.bvid,
        content: result,
        type: summary_model.SummaryType.structured,
        modelUsed: config.effectiveModel,
        promptUsed: tpl0.name,
        page: _page,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ 评论总结已保存')),
      );
      _load();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
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

    // 空状态: 还没下载评论
    if (_comments.isEmpty) {
      return EmptyDataState(
        icon: Icons.comment_outlined,
        label: '请先下载评论',
        downloadButtonLabel: '下载评论',
        onDownload: widget.onDownloadRequest,
      );
    }

    // 有评论但还没总结: 显示生成按钮 + 历史入口 (跟 Summary tab 一致)
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
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

/// 统一空状态 — 跟 Summary tab 的 _noSubtitleState 风格一致
