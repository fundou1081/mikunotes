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
// ─────────────────────────────────────────────────

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
          _SummaryPicker(
            summaries: _summaries,
            selectedId: _selectedSummaryId,
            onSelect: (s) => setState(() => _selectedSummaryId = s.id),
            onDelete: (s) async {
              await ref.read(videoRepositoryProvider).deleteSummary(s.id);
              _load();
            },
          ),
          Expanded(
            child: _SummaryView(summary: _summaries.firstWhere((s) => s.id == _selectedSummaryId)),
          ),
        ],
      );
    }

    // 空状态: 还没下载评论
    if (_comments.isEmpty) {
      return _EmptyDataState(
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
class _EmptyDataState extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onDownload;
  final String? downloadButtonLabel;

  const _EmptyDataState({
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

class _SummaryView extends StatelessWidget {
  final db.Summary summary;
  const _SummaryView({required this.summary});

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

class _SummaryPicker extends StatelessWidget {
  final List<db.Summary> summaries;
  final String? selectedId;
  final Function(db.Summary) onSelect;
  final Function(db.Summary) onDelete;

  const _SummaryPicker({
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

// ─────────────────────────────────────────────────
// 弹幕 Tab — 跟摘要 tab 一样, 但 source = 'danmaku'
// ─────────────────────────────────────────────────

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
        templates: templates.comments, // 复用评论模板 (都是文本分析)
        activeId: templates.activeCommentId,
      );
      if (templateId == null) {
        setState(() => _generating = false);
        return; // 用户取消
      }
      final tpl0 = templates.comments.firstWhere((t) => t.id == templateId,
          orElse: () => templates.comments.first);
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
          _SummaryPicker(
            summaries: _summaries,
            selectedId: _selectedSummaryId,
            onSelect: (s) => setState(() => _selectedSummaryId = s.id),
            onDelete: (s) async {
              await ref.read(videoRepositoryProvider).deleteSummary(s.id);
              _load();
            },
          ),
          Expanded(
            child: _SummaryView(summary: _summaries.firstWhere((s) => s.id == _selectedSummaryId)),
          ),
        ],
      );
    }

    // 空状态: 还没下载弹幕
    if (_danmaku.isEmpty) {
      return _EmptyDataState(
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
// ─────────────────────────────────────────────────

class RawDataTab extends ConsumerStatefulWidget {
  final String bvid;
  final VideoSubtitle? subtitle;
  final int selectedPage;
  final List<db.Subtitle> allSubtitles;
  final String? selectedLang;
  final bool loading;
  final Function(String) onLanguageChanged;
  final VoidCallback onRefresh;

  const RawDataTab({
    super.key,
    required this.bvid,
    required this.subtitle,
    required this.selectedPage,
    required this.allSubtitles,
    required this.selectedLang,
    required this.loading,
    required this.onLanguageChanged,
    required this.onRefresh,
  });

  @override
  ConsumerState<RawDataTab> createState() => RawDataTabState();
}

class RawDataTabState extends ConsumerState<RawDataTab> {
  Set<DataSource> _selectedSources = {DataSource.subtitle};  // 默认只看字幕
  List<db.Comment> _comments = [];
  List<DanmakuData> _danmaku = [];
  String? _activeSubLang;  // 当前显示的字幕语言
  // 字幕+弹幕 合并视图用
  List<_SrtCue> _srtCues = [];

  @override
  void initState() {
    super.initState();
    _activeSubLang = widget.selectedLang;
    _loadComments();
    _loadDanmaku();
    _loadSrtCues();
  }

  @override
  void didUpdateWidget(RawDataTab old) {
    super.didUpdateWidget(old);
    if (widget.selectedLang != old.selectedLang) {
      _activeSubLang = widget.selectedLang;
      _loadSrtCues();
    }
    if (widget.selectedPage != old.selectedPage) {
      _loadComments();
      _loadDanmaku();
      _loadSrtCues();
    }
  }

  int get _page => widget.selectedPage == 0 ? 1 : widget.selectedPage;

  Future<void> _loadComments() async {
    final dbLocal = ref.read(databaseProvider);
    _comments = await dbLocal.getCommentsForVideo(widget.bvid, page: _page);
    if (mounted) setState(() {});
  }

  Future<void> _loadDanmaku() async {
    final dbLocal = ref.read(databaseProvider);
    _danmaku = await dbLocal.getDanmakuForVideo(widget.bvid, page: _page);
    if (mounted) setState(() {});
  }

  /// 从 SRT 解析 cues (用于对齐弹幕)
  Future<void> _loadSrtCues() async {
    if (widget.allSubtitles.isEmpty || _activeSubLang == null) {
      _srtCues = [];
      return;
    }
    final sub = widget.allSubtitles.firstWhere(
      (s) => s.language == _activeSubLang && s.page == _page,
      orElse: () => widget.allSubtitles.first,
    );
    _srtCues = _parseSrtCues(sub.rawJson);
    if (mounted) setState(() {});
  }

  /// 简单 SRT 解析 (返回 [start, end, text])
  static List<_SrtCue> _parseSrtCues(String srtText) {
    final cues = <_SrtCue>[];
    final lines = srtText.split('\n');
    int i = 0;
    while (i < lines.length) {
      // 跳过空行
      while (i < lines.length && lines[i].trim().isEmpty) i++;
      if (i >= lines.length) break;
      // 序号行
      if (RegExp(r'^\d+$').hasMatch(lines[i].trim())) i++;
      if (i >= lines.length) break;
      // 时间码行: 00:00:01,000 --> 00:00:04,500
      final m = RegExp(r'(\d+):(\d+):(\d+),(\d+)\s*-->\s*(\d+):(\d+):(\d+),(\d+)').firstMatch(lines[i]);
      if (m != null) {
        final start = int.parse(m.group(1)!) * 3600000 +
            int.parse(m.group(2)!) * 60000 +
            int.parse(m.group(3)!) * 1000 +
            int.parse(m.group(4)!);
        final end = int.parse(m.group(5)!) * 3600000 +
            int.parse(m.group(6)!) * 60000 +
            int.parse(m.group(7)!) * 1000 +
            int.parse(m.group(8)!);
        i++;
        // 文本行
        final textLines = <String>[];
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i].trim());
          i++;
        }
        cues.add(_SrtCue(start, end, textLines.join(' ')));
      } else {
        i++;
      }
    }
    return cues;
  }

  String _fmtTime(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// 把弹幕按时间戳对齐到字幕 cue
  List<_AlignedSegment> _alignDanmakuToCues() {
    if (_srtCues.isEmpty || _danmaku.isEmpty) return [];
    final aligned = <_AlignedSegment>[];
    for (final cue in _srtCues) {
      // 找在 [cue.start, cue.end] 区间内的弹幕
      final inRange = _danmaku.where((d) => d.progress >= cue.start && d.progress <= cue.end).toList();
      aligned.add(_AlignedSegment(
        start: cue.start,
        end: cue.end,
        text: cue.text,
        danmaku: inRange,
      ));
    }
    return aligned;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部: 多选 chip
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: DataSource.values.map((s) {
                    // 判断是否可点
                    final available = switch (s) {
                      DataSource.subtitle => widget.allSubtitles.isNotEmpty,
                      DataSource.comment => _comments.isNotEmpty,
                      DataSource.danmaku => _danmaku.isNotEmpty,
                    };
                    return FilterChip(
                    label: Text(s.label, style: const TextStyle(fontSize: 12)),
                    selected: _selectedSources.contains(s),
                    onSelected: available ? (sel) {
                      setState(() {
                        if (sel) {
                          _selectedSources.add(s);
                        } else {
                          _selectedSources.remove(s);
                        }
                      });
                    } : null,
                    backgroundColor: available ? null : Colors.grey.shade200,
                    tooltip: available ? null : '${s.label} 未下载',
                  );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // 字幕语言选择
        if (_selectedSources.contains(DataSource.subtitle) && widget.allSubtitles.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Text('字幕语言:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    children: widget.allSubtitles
                        .where((s) => s.page == _page)
                        .map((s) => ChoiceChip(
                              label: Text(s.language, style: const TextStyle(fontSize: 11)),
                              selected: _activeSubLang == s.language,
                              onSelected: (_) => widget.onLanguageChanged(s.language),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        // 内容区
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_selectedSources.isEmpty) {
      return const Center(child: Text('请至少选一个数据源'));
    }
    final parts = <Widget>[];

    // 字幕 + 弹幕 合并视图
    final wantSubDanmaku = _selectedSources.contains(DataSource.subtitle) &&
        _selectedSources.contains(DataSource.danmaku);

    if (wantSubDanmaku && _srtCues.isNotEmpty) {
      final aligned = _alignDanmakuToCues();
      parts.add(Container(
        padding: const EdgeInsets.all(8),
        color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        child: const Text('📺 字幕 + 弹幕 (按时间戳对齐)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ));
      for (final seg in aligned) {
        parts.add(_buildAlignedSegment(seg));
      }
    } else {
      // 单独显示字幕
      if (_selectedSources.contains(DataSource.subtitle) && widget.subtitle != null) {
        parts.add(_buildSubtitleSection());
      }
      // 单独显示弹幕
      if (_selectedSources.contains(DataSource.danmaku)) {
        parts.add(_buildDanmakuSection());
      }
    }

    // 评论
    if (_selectedSources.contains(DataSource.comment)) {
      parts.add(_buildCommentSection());
    }

    return ListView(
      padding: const EdgeInsets.all(0),
      children: parts,
    );
  }

  Widget _buildAlignedSegment(_AlignedSegment seg) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_fmtTime(seg.start)} - ${_fmtTime(seg.end)}',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                if (seg.danmaku.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${seg.danmaku.length} 条弹幕',
                      style: const TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(seg.text, style: const TextStyle(fontSize: 13, height: 1.4)),
            if (seg.danmaku.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: seg.danmaku.take(5).map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: Colors.orange.shade700)),
                        Expanded(
                          child: Text(
                            d.content,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                        Text(
                          _fmtTime(d.progress),
                          style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              if (seg.danmaku.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('... 还有 ${seg.danmaku.length - 5} 条',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleSection() {
    final sub = widget.subtitle;
    if (sub == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('暂无字幕, 请先在 AppBar 菜单下载'),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: const Text('📄 字幕 (完整)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            sub.fullText,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDanmakuSection() {
    if (_danmaku.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('暂无弹幕, 请先在 AppBar 菜单下载'),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Text('💬 弹幕 (${_danmaku.length} 条)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        for (final d in _danmaku.take(200))
          ListTile(
            leading: SizedBox(
              width: 56,
              child: Text(
                _fmtTime(d.progress),
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
              ),
            ),
            title: Text(d.content, maxLines: 1, overflow: TextOverflow.ellipsis),
            dense: true,
          ),
        if (_danmaku.length > 200)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('... 仅显示前 200 条',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _buildCommentSection() {
    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('暂无评论, 请先在 AppBar 菜单下载'),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Text('💭 评论 (${_comments.length} 条)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        for (final c in _comments.take(100))
          ListTile(
            leading: CircleAvatar(
              radius: 14,
              child: Text(c.uname.isNotEmpty ? c.uname[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12)),
            ),
            title: Text(c.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('${c.uname} · 👍 ${c.likes}', style: const TextStyle(fontSize: 11)),
            isThreeLine: true,
            dense: true,
          ),
        if (_comments.length > 100)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('... 仅显示前 100 条',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
      ],
    );
  }
}

class _SrtCue {
  final int start;  // ms
  final int end;    // ms
  final String text;
  _SrtCue(this.start, this.end, this.text);
}

class _AlignedSegment {
  final int start;
  final int end;
  final String text;
  final List<DanmakuData> danmaku;
  _AlignedSegment({required this.start, required this.end, required this.text, required this.danmaku});
}
