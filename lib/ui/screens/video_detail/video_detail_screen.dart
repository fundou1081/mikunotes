import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mikunotes/ui/screens/video_detail/math_markdown.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/chat_message.dart' as chat_model;
import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/models/summary.dart' as summary_model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/generation_provider.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/bilibili/comment_client.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:drift/drift.dart' as drift show Value;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 默认总结 prompt
const _defaultSummaryPrompt = """你是B站视频内容总结助手。请严格按照以下格式输出结构化总结：

## 📺 视频概述
一句话概括视频主题。

## 🧠 核心概念/名词解释
用表格列出视频中出现的核心概念、术语、专有名词，并给出简洁解释。

## 💡 有价值的观点
列举视频中独特、有启发性的观点（3-5条），每条引用视频中的具体论据。

## 🔑 最重要的观点
提炼视频最核心的1-2个论点，说明为什么这是关键。

## 📐 行文逻辑
用流程图或层级结构展示视频的论证逻辑。

## ❓ 提问-回答
针对视频核心议题，设计3-5个关键问答（Q&A格式）。

要求:
- 使用 Markdown 格式
- 概念解释简洁准确
- 观点引用视频原话
- 板块间用 --- 分隔""";

class VideoDetailScreen extends ConsumerStatefulWidget {
  final String bvid;
  const VideoDetailScreen({super.key, required this.bvid});

  @override
  ConsumerState<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends ConsumerState<VideoDetailScreen>
    with SingleTickerProviderStateMixin {
  VideoSubtitle? _subtitle;
  List<db.Subtitle> _allSubtitles = [];
  String? _selectedLang;
  bool _loadingSubtitle = true;
  int _subtitleTabKey = 0; // 用于强制重建 db.Subtitle Tab
  int _pageCount = 1;
  int _selectedPage = 1; // 0 = 整体, 1+ = 第N部分

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final repo = ref.read(videoRepositoryProvider);
    final all = await repo.getAllSubtitles(widget.bvid);
    VideoSubtitle? sub;
    if (all.isNotEmpty) {
      sub = await repo.getSubtitle(widget.bvid);
    }
    // 加载视频组信息 (pageCount 等)
    final group = await ref.read(databaseProvider).getVideoGroup(widget.bvid);
    if (!mounted) return;
    setState(() {
      _allSubtitles = all;
      _subtitle = sub;
      _selectedLang = sub?.language ?? (all.isNotEmpty ? all.first.language : null);
      _loadingSubtitle = false;
      if (group != null) {
        _pageCount = group.pageCount;
        if (_selectedPage < 1 || _selectedPage > _pageCount) _selectedPage = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('视频 ${widget.bvid}', maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              tooltip: '在 B 站打开',
              onPressed: () => launchUrl(
                Uri.parse('https://www.bilibili.com/video/${widget.bvid}'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.comment),
              tooltip: '导出评论分析',
              onPressed: _showCommentAnalysis,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新字幕',
              onPressed: _loadingSubtitle ? null : _refreshSubtitles,
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: '摘要', icon: Icon(Icons.summarize)),
            Tab(text: '对话', icon: Icon(Icons.chat_bubble_outline)),
            Tab(text: '字幕', icon: Icon(Icons.subtitles)),
          ]),
        ),
        body: Column(
          children: [
            // 分P 选择器 (只有多P才显示)
            if (_pageCount > 1)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    _pageChip('整体', 0),
                    for (int p = 1; p <= _pageCount; p++) _pageChip('P$p', p),
                  ],
                ),
              ),
            Expanded(
            child: TabBarView(children: [
          _SummaryTab(bvid: widget.bvid, subtitle: _subtitle, onChanged: _loadAll, selectedPage: _selectedPage, pageCount: _pageCount),
          _ChatTab(bvid: widget.bvid, subtitle: _subtitle),
          _SubtitleTab(
            key: ValueKey(_subtitleTabKey),
            bvid: widget.bvid,
            allSubtitles: _allSubtitles,
            selectedLang: _selectedLang,
            selectedPage: _selectedPage,
            loading: _loadingSubtitle,
            onLanguageChanged: (lang) {
              setState(() {
                _selectedLang = lang;
                _subtitleTabKey++;
              });
              _loadSubtitleForLang(lang);
            },
          ),
        ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSubtitleForLang(String lang) async {
    final repo = ref.read(videoRepositoryProvider);
    // 加载指定页面的字幕 (page=0 时加载任一, 1+ 时加载对应页)
    final page = _selectedPage == 0 ? null : _selectedPage;
    final sub = await repo.getSubtitle(widget.bvid, language: lang, page: page);
    if (mounted) setState(() => _subtitle = sub);
  }

  Future<void> _refreshSubtitles() async {
    setState(() => _loadingSubtitle = true);
    try {
      final repo = ref.read(videoRepositoryProvider);
      await repo.downloadAllSubtitles(widget.bvid);
      await _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刷新失败: $e')),
        );
        setState(() => _loadingSubtitle = false);
      }
    }
  }

  Widget _pageChip(String label, int page) {
    final selected = _selectedPage == page;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedPage = page);
        // 切换到指定页面, 重新加载字幕
        _loadSubtitleForLang(_selectedLang ?? 'zh');
      },
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Future<void> _showCommentAnalysis() async {
    // 1. 问用户要拉多少条
    final count = await showDialog<int>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('拉取多少条评论？'),
        children: [
          _countOption(c, 50, '50 条 (快速概览)'),
          _countOption(c, 100, '100 条'),
          _countOption(c, 300, '300 条'),
          _countOption(c, 500, '500 条 (深度分析)'),
          _countOption(c, -1, '全部 (可能较慢)'),
        ],
      ),
    );
    if (count == null) return; // 用户取消
    final maxPages = count == -1 ? 100 : (count ~/ 20).clamp(1, 100);

    _showLoading('正在拉取评论...');
    try {
      // 从 B 站 API 拿 aid
      final bili = ref.read(bilibiliClientProvider);
      final info = await bili.getVideoInfo(widget.bvid);
      final aid = info['aid'] as int?;
      final title = info['title'] as String? ?? '';
      if (aid == null || aid == 0) {
        if (mounted) Navigator.pop(context);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法获取视频 aid')),
        );
        return;
      }
      final client = ref.read(commentClientProvider);
      final result = await client.fetchComments(aid, maxPages: maxPages);
      if (!mounted) return;
      Navigator.pop(context);
      if (result.comments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该视频暂无评论')),
        );
        return;
      }
      _showLoading('正在 AI 分析评论...');
      final config = ref.read(aiConfigProvider);
      final llmClient = ref.read(llmClientProvider);
      final templates = ref.read(templatesProvider);
      final activeComment = templates.activeComment;
      final tpl = activeComment?.content ?? llm_tpl.communityCommentTemplate;
      final text = result.toText();
      // 渲染模板变量
      final prompt = llm_tpl.PromptTemplate.render(tpl, {
        'video_title': title,
        'total': '${result.total}',
        'taken': '${result.comments.length}',
        'text': text.length > 8000 ? '${text.substring(0, 8000)}...(已截断)' : text,
      });
      final analysis = await llmClient.chat(
        systemPrompt: '你是视频评论分析助手。',
        userMessage: prompt,
        maxTokens: 2000,
        disableReasoning: true,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('评论分析 (${result.comments.length}/${result.total}条)'),
          content: SizedBox(width: 500, height: 400,
            child: SingleChildScrollView(child: SelectableText(analysis)),
          ),
          actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text('关闭'))],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('评论分析失败: $e')),
      );
    }
  }

  void _showLoading(String msg) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (c) => AlertDialog(title: Text(msg),
        content: const SizedBox(height:60, child:Center(child:CircularProgressIndicator())),
      ),
    );
  }
}

// ─── 摘要 Tab ──────────────────────────────────────────────────

class _SummaryTab extends ConsumerStatefulWidget {
  final String bvid;
  final VideoSubtitle? subtitle;
  final VoidCallback onChanged;
  final int selectedPage;
  final int pageCount;
  const _SummaryTab({
    required this.bvid,
    required this.subtitle,
    required this.onChanged,
    this.selectedPage = 1,
    this.pageCount = 1,
  });

  @override
  ConsumerState<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends ConsumerState<_SummaryTab> {
  bool _downloading = false;
  String? _selectedSummaryId; // 历史中选择的总结

  Future<void> _generateSummary({String? customPrompt, String? title}) async {
    if (widget.subtitle == null || widget.subtitle!.entries.isEmpty) {
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
    await ref.read(generationProvider.notifier).startSummaryGeneration(
      bvid: widget.bvid,
      subtitle: widget.subtitle!,
      customPrompt: customPrompt,
      templateId: templateId,
      page: widget.selectedPage,
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

  void _showExistingSummaries() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SummariesListSheet(
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
                    if (genState!.isCompleted) {
                      // 已完成 → 立即跳到总结视图
                      ref.read(generationProvider.notifier).clear(widget.bvid);
                    } else {
                      ref.read(generationProvider.notifier).cancel(widget.bvid);
                    }
                  },
                  icon: Icon(genState!.isCompleted ? Icons.check : Icons.stop),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _showExistingSummaries,
                  icon: const Icon(Icons.history, size: 18),
                  label: Text('历史 (${all.length})'),
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

class _SummariesListSheet extends ConsumerWidget {
  final String bvid;
  final Function(summary_model.Summary) onSelect;
  final Function(summary_model.Summary) onDelete;
  const _SummariesListSheet({
    required this.bvid,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, scrollController) {
        return FutureBuilder<List<summary_model.Summary>>(
          future: ref.read(videoRepositoryProvider).getAllSummaries(bvid),
          builder: (ctx, snap) {
            final items = snap.data ?? [];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.history),
                      const SizedBox(width: 8),
                      const Text('历史总结',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('共 ${items.length} 条',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('暂无历史总结')),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final s = items[i];
                        return ListTile(
                          title: Text(
                            s.title.isEmpty ? '总结 ${i + 1}' : s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_typeLabel(s.type)} · ${_formatDate(s.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => onSelect(s),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => onDelete(s),
                          ),
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

  String _typeLabel(summary_model.SummaryType t) {
    switch (t) {
      case summary_model.SummaryType.structured:
        return '结构化';
      case summary_model.SummaryType.topicExpansion:
        return '主题展开';
      case summary_model.SummaryType.compare:
        return '对比';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── 对话 Tab ──────────────────────────────────────────────────

class _ChatTab extends ConsumerStatefulWidget {
  final String bvid;
  final VideoSubtitle? subtitle;
  const _ChatTab({required this.bvid, required this.subtitle});

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  db.ChatSession? _currentSession;
  List<db.ChatMessage> _messages = [];
  String _streamingContent = '';
  bool _streaming = false;
  int _messageIndex = 0;
  int _tokensUsed = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final repo = ref.read(videoRepositoryProvider);
    final sessions = await repo.getChatSessions(widget.bvid);
    if (!mounted) return;
    if (sessions.isEmpty) {
      // 创建默认会话
      final s = await repo.createChatSession(widget.bvid);
      if (mounted) setState(() {
        _currentSession = s;
        _loading = false;
      });
    } else {
      _switchToSession(sessions.first);
    }
  }

  Future<void> _switchToSession(db.ChatSession s) async {
    final repo = ref.read(videoRepositoryProvider);
    final msgs = await repo.getChatMessages(s.id);
    final totalChars = msgs.fold(0, (sum, m) => sum + m.content.length);
    if (!mounted) return;
    setState(() {
      _currentSession = s;
      _messages = msgs;
      _streamingContent = '';
      _streaming = false;
      _messageIndex = msgs.length;
      _tokensUsed = LLMClient.estimateTokens(
        '${widget.subtitle?.fullText ?? ''}$totalChars',
      );
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _newSession() async {
    final repo = ref.read(videoRepositoryProvider);
    final s = await repo.createChatSession(widget.bvid);
    _switchToSession(s);
  }

  void _showSessionList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SessionListSheet(
        bvid: widget.bvid,
        currentId: _currentSession?.id,
        onSelect: (s) {
          Navigator.pop(ctx);
          _switchToSession(s);
        },
        onDelete: (s) async {
          await ref.read(videoRepositoryProvider).deleteChatSession(s.id);
        },
        onRename: (s) async {
          final newTitle = await _showRenameDialog(ctx, s.title);
          if (newTitle != null && newTitle.isNotEmpty) {
            await ref.read(videoRepositoryProvider)
                .updateSessionTitle(s.id, newTitle);
          }
        },
      ),
    );
  }

  Future<String?> _showRenameDialog(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _streaming) return;
    if (widget.subtitle == null) {
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

    final repo = ref.read(videoRepositoryProvider);
    if (_currentSession == null) {
      final s = await repo.createChatSession(widget.bvid);
      _currentSession = s;
    }
    final session = _currentSession!;

    // 上下文压缩
    final config = ref.read(aiConfigProvider);
    final compressed = await repo.compressContextIfNeeded(
      session.id,
      llmClient: ref.read(llmClientProvider),
      config: config,
    );
    if (compressed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已自动压缩早期对话历史'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 保存用户消息
    await repo.addChatMessage(
      sessionId: session.id,
      role: chat_model.ChatRole.user,
      content: text,
    );

    final newUserMsg = db.ChatMessage(
      id: _uuid.v4(),
      sessionId: session.id,
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
      isCompressed: false,
    );

    setState(() {
      _messages = [..._messages, newUserMsg];
      _streaming = true;
      _streamingContent = '';
    });
    _messageIndex = _messages.length;
    _controller.clear();
    _scrollToBottom();

    // 构造上下文
    final sessionMsgs = await repo.getChatMessages(session.id);
    final history = sessionMsgs
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    // 使用模板渲染 system prompt — 优先使用激活的 chat 模板
    final templates = ref.read(templatesProvider);
    final activeChat = templates.activeChat;
    final chatTemplate = activeChat?.content ??
        (config.chatTemplate.isNotEmpty ? config.chatTemplate : llm_tpl.defaultChatTemplate);
    final systemPrompt = llm_tpl.PromptTemplate.render(chatTemplate, {
      'title': 'BV ${widget.bvid}',
      'bvid': widget.bvid,
      'subtitle': widget.subtitle!.fullText,
      'subtitle_truncated': widget.subtitle!.fullText,
      'language': widget.subtitle!.language,
      'uploader': '',
      'duration': '',
      'page_count': '',
    });

    try {
      final client = ref.read(llmClientProvider);
      final config = ref.read(aiConfigProvider);
      final disableReasoning = config.provider == LLMProvider.minimax;
          
      final buffer = StringBuffer();
      await for (final chunk in client.chatStreamWithFallback(
        systemPrompt: systemPrompt,
        messages: history,
        disableReasoning: disableReasoning,
      )) {
        buffer.write(chunk);
        setState(() => _streamingContent = buffer.toString());
        _scrollToBottom();
      }

      // 保存助手消息
      await repo.addChatMessage(
        sessionId: session.id,
        role: chat_model.ChatRole.assistant,
        content: buffer.toString(),
      );

      // 重新加载消息列表
      final msgs = await repo.getChatMessages(session.id);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _streamingContent = '';
          _streaming = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _streaming = false;
        _streamingContent = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('错误: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.subtitle == null) {
      return const Center(child: Text('请先下载字幕'));
    }

    return Column(
      children: [
        _SessionBar(
          title: _currentSession?.title ?? '新对话',
          messageCount: _messages.length,
          tokensUsed: _tokensUsed,
          maxTokens: ref.read(aiConfigProvider).maxContextChars ~/ 2,
          onTap: _showSessionList,
          onNew: _newSession,
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_streaming ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _messages.length && _streaming) {
                return _ChatBubble(
                  content: _streamingContent,
                  isUser: false,
                  isStreaming: true,
                );
              }
              final m = _messages[i];
              return _ChatBubble(
                content: m.content,
                isUser: m.role == 'user',
                isStreaming: false,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: '问点关于这个视频的问题...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(
                onPressed: _streaming ? null : _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionBar extends StatelessWidget {
  final String title;
  final int messageCount;
  final int tokensUsed;
  final int maxTokens;
  final VoidCallback onTap;
  final VoidCallback onNew;

  const _SessionBar({
    required this.title,
    required this.messageCount,
    required this.tokensUsed,
    required this.maxTokens,
    required this.onTap,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final usage = maxTokens > 0 ? (tokensUsed / maxTokens).clamp(0.0, 1.0) : 0.0;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble, size: 16),
                    const SizedBox(width: 4),
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 16),
                  ],
                ),
              ),
            ),
            Text('~$tokensUsed tokens',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                value: usage,
                backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              tooltip: '新对话',
              onPressed: onNew,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionListSheet extends ConsumerWidget {
  final String bvid;
  final String? currentId;
  final Function(db.ChatSession) onSelect;
  final Function(db.ChatSession) onDelete;
  final Function(db.ChatSession) onRename;
  const _SessionListSheet({
    required this.bvid,
    required this.currentId,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, scrollController) {
        return FutureBuilder<List<db.ChatSession>>(
          future: ref.read(videoRepositoryProvider).getChatSessions(bvid),
          builder: (ctx, snap) {
            final items = snap.data ?? [];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.chat),
                      const SizedBox(width: 8),
                      const Text('对话会话',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('共 ${items.length} 条',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('暂无对话会话')),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final s = items[i];
                        final isCurrent = s.id == currentId;
                        return ListTile(
                          leading: Icon(
                            isCurrent
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          title: Text(s.title),
                          subtitle: Text(_formatDate(s.lastActiveAt),
                              style: Theme.of(context).textTheme.bodySmall),
                          onTap: () => onSelect(s),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => onRename(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () => onDelete(s),
                              ),
                            ],
                          ),
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

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isStreaming;
  const _ChatBubble({
    required this.content,
    required this.isUser,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MathMarkdownBody(
              data: content.isEmpty ? (isStreaming ? '...' : ' ') : content,
              selectable: !isStreaming,
            ),
            if (isStreaming)
              const SizedBox(
                height: 3,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 字幕 Tab ──────────────────────────────────────────────────

class _SubtitleTab extends ConsumerStatefulWidget {
  final String bvid;
  final List<db.Subtitle> allSubtitles;
  final String? selectedLang;
  final bool loading;
  final ValueChanged<String> onLanguageChanged;
  final int selectedPage;
  const _SubtitleTab({
    super.key,
    required this.bvid,
    required this.allSubtitles,
    required this.selectedLang,
    required this.loading,
    required this.onLanguageChanged,
    this.selectedPage = 1,
  });

  @override
  ConsumerState<_SubtitleTab> createState() => _SubtitleTabState();
}

class _SubtitleTabState extends ConsumerState<_SubtitleTab> {
  VideoSubtitle? _subtitle;
  bool _loading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loading = true;
    _loadSubtitle();
  }

  @override
  void didUpdateWidget(covariant _SubtitleTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLang != widget.selectedLang) {
      _loadSubtitle();
    }
  }

  Future<void> _loadSubtitle() async {
    setState(() => _loading = true);
    final repo = ref.read(videoRepositoryProvider);
    final sub = await repo.getSubtitle(
      widget.bvid,
      language: widget.selectedLang,
    );
    if (mounted) setState(() {
      _subtitle = sub;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading || _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.allSubtitles.isEmpty) {
      return const Center(child: Text('暂无字幕'));
    }

    final filteredEntries = _subtitle?.entries.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList() ?? [];

    return Column(
      children: [
        // 语言选择 + 统计
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.translate, size: 16),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: widget.selectedLang,
                    isDense: true,
                    items: widget.allSubtitles
                        .map((s) => DropdownMenuItem(
                              value: s.language,
                              child: Text(s.language),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) widget.onLanguageChanged(v);
                    },
                  ),
                  const Spacer(),
                  if (_subtitle != null)
                    Text(
                      '${_subtitle!.entries.length} 条 · ${_subtitle!.fullText.length} 字 · ~${LLMClient.estimateTokens(_subtitle!.fullText)} tokens',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              if (widget.allSubtitles.length > 1) ...[
                const SizedBox(height: 4),
                Text(
                  '共 ${widget.allSubtitles.length} 种语言',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        // 搜索框
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索字幕...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // 字幕列表
        Expanded(
          child: _subtitle == null || filteredEntries.isEmpty
              ? Center(child: Text(_searchQuery.isEmpty ? '暂无字幕' : '无匹配结果'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredEntries.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (ctx, i) {
                    final e = filteredEntries[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.from.toStringAsFixed(1)}s - ${e.to.toStringAsFixed(1)}s',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        _highlightSearch(e.content),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _highlightSearch(String text) {
    if (_searchQuery.isEmpty) return Text(text);
    final lower = text.toLowerCase();
    final query = _searchQuery.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx == -1) return Text(text);

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + _searchQuery.length),
            style: TextStyle(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(idx + _searchQuery.length)),
        ],
      ),
    );
  }
}
Widget _countOption(BuildContext c, int count, String label) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(c, count),
      child: Text(label),
    );
  }
// 📦 PARTFIX marker for the end of the file - to be replaced
