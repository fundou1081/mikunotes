import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:mikunotes/core/bilibili/danmaku_client.dart';
import 'package:mikunotes/core/bilibili/comment_client.dart';
import 'package:mikunotes/ui/screens/video_detail/page_list_page.dart';
import 'package:mikunotes/ui/screens/video_detail/data_tabs.dart' show RawDataTab, CommentTab, DanmakuTab, DataSource;
import 'package:mikunotes/core/storage/database.dart' show DanmakuData, Comment;
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/core/storage/database.dart' show CommentsCompanion, DanmakuCompanion;
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show Value;
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
  int _dataTabKey = 0; // 用于强制重建 Comment/Danmaku Tab (下载后)
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
    // 加载当前选中页面的字幕
    final page = _selectedPage == 0 ? null : _selectedPage;
    if (all.isNotEmpty) {
      sub = await repo.getSubtitle(widget.bvid, page: page, language: _selectedLang);
      // fallback: any page
      sub ??= await repo.getSubtitle(widget.bvid);
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
      length: 5,
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              tooltip: '下载原始数据',
              onSelected: (v) {
                if (v == 'subtitle') _refreshSubtitles();
                if (v == 'comment') _showDownloadCommentsSheet();
                if (v == 'danmaku') _showDownloadDanmakuSheet();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'subtitle',
                  child: Row(children: [
                    Icon(Icons.subtitles, size: 18),
                    SizedBox(width: 8),
                    Text('刷新字幕'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'comment',
                  child: Row(children: [
                    Icon(Icons.comment, size: 18),
                    SizedBox(width: 8),
                    Text('下载评论'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'danmaku',
                  child: Row(children: [
                    Icon(Icons.lightbulb_outline, size: 18),
                    SizedBox(width: 8),
                    Text('下载弹幕'),
                  ]),
                ),
              ],
            ),
          ],
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: '摘要', icon: Icon(Icons.summarize)),
            Tab(text: '评论', icon: Icon(Icons.comment)),
            Tab(text: '弹幕', icon: Icon(Icons.lightbulb_outline)),
            Tab(text: '对话', icon: Icon(Icons.chat_bubble_outline)),
            Tab(text: '原始数据', icon: Icon(Icons.subtitles)),
          ]),
        ),
        body: Column(
          children: [
            // 分P 选择器 (只有多P才显示) - 点击打开全分P 列表页
            if (_pageCount > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PageListPage(
                          bvid: widget.bvid,
                          selectedPage: _selectedPage,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() => _selectedPage = result);
                      _loadSubtitleForLang(_selectedLang ?? 'zh');
                    }
                  },
                  icon: const Icon(Icons.list, size: 16),
                  label: Text(_pageChipLabel(), style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            Expanded(
            child: TabBarView(children: [
          _SummaryTab(bvid: widget.bvid, subtitle: _subtitle, onChanged: _loadAll, selectedPage: _selectedPage, pageCount: _pageCount),
          CommentTab(key: ValueKey('comment_$_dataTabKey'), bvid: widget.bvid, selectedPage: _selectedPage, onDownloadRequest: _showDownloadCommentsSheet),
          DanmakuTab(key: ValueKey('danmaku_$_dataTabKey'), bvid: widget.bvid, selectedPage: _selectedPage, onDownloadRequest: _showDownloadDanmakuSheet),
          _ChatTab(key: ValueKey('chat_$_dataTabKey'), bvid: widget.bvid, subtitle: _subtitle, selectedPage: _selectedPage),
          RawDataTab(
            key: ValueKey('raw_$_subtitleTabKey'),
            bvid: widget.bvid,
            subtitle: _subtitle,
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
            onRefresh: () {
                _loadSubtitleForLang(_selectedLang ?? 'zh');
                _subtitleTabKey++;
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
    final page = _selectedPage == 0 ? null : _selectedPage;
    setState(() => _loadingSubtitle = true);
    final sub = await repo.getSubtitle(widget.bvid, language: lang, page: page);
    if (mounted) {
      setState(() {
        _subtitle = sub;
        _loadingSubtitle = false;
      });
    }
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

  String _pageChipLabel() {
    if (_selectedPage == 0) return '整体 (所有分P) · $_pageCount 个 P';
    return 'P$_selectedPage / $_pageCount';
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

  Widget _countOption(BuildContext c, int count, String label) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(c, count),
      child: Text(label),
    );
  }

  void _showLoading(String msg) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (c) => AlertDialog(title: Text(msg),
        content: const SizedBox(height:60, child:Center(child:CircularProgressIndicator())),
      ),
    );
  }

  // ─── 下载评论 (手动) ─────────────────────────────────────

  Future<void> _showDownloadCommentsSheet() async {
    final result = await showModalBottomSheet<_CommentDownloadConfig>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _DownloadCommentsSheet(),
    );
    if (result == null) return;

    _showLoading('拉取评论中...');
    try {
      // 先拿 aid
      final bili = ref.read(bilibiliClientProvider);
      final info = await bili.getVideoInfo(widget.bvid);
      final aid = (info['aid'] as int?) ?? 0;
      if (aid == 0) throw '无法获取视频 aid';
      // 拉评论
      final client = ref.read(commentClientProvider);
      final pageCount = _pageCount;
      final pagesToFetch = (result.maxCount / 20).ceil().clamp(1, 30);
      final fetched = await client.fetchComments(aid, maxPages: pagesToFetch);
      // 过滤
      var comments = fetched.comments;
      if (result.filterShort) {
        comments = comments.where((c) => c.content.length >= result.minLength).toList();
      }
      if (result.filterDigits) {
        comments = comments.where((c) {
            final t = c.content.trim();
            return !RegExp(r'^[\\d\\?\\!\\.\\s]+$').hasMatch(t);
        }).toList();
      }
      if (result.filterDuplicate) {
        final seen = <String>{};
        comments = comments.where((c) {
            final key = c.content.substring(0, c.content.length > 20 ? 20 : c.content.length);
            if (seen.contains(key)) return false;
            seen.add(key);
            return true;
        }).toList();
      }
      // 采样 (随机/前N)
      if (result.mode == 'random') {
        comments.shuffle();
      }
      if (comments.length > result.maxCount) {
        comments = comments.sublist(0, result.maxCount);
      }
      // 存 DB (全部都存, 按 page=selectedPage)
      final page = _selectedPage == 0 ? 1 : _selectedPage;
      final db = ref.read(databaseProvider);
      await db.clearComments(widget.bvid, page: page);
      await db.insertComments(comments.map((c) => CommentsCompanion.insert(
        bvid: widget.bvid,
        page: drift.Value(page),
        aid: aid,
        rpid: c.rpid,
        uname: c.uname,
        content: c.content,
        likes: drift.Value(c.like),
        rcount: drift.Value(0),  // BilibiliComment 无此字段
        parent: const drift.Value.absent(),  // 只存主评论, 不存子评论
        ctime: DateTime.fromMillisecondsSinceEpoch(c.ctime * 1000),
        fetchedMode: Value(result.mode),
      )).toList());

      if (!mounted) return;
      Navigator.pop(context); // close loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ 评论已保存: ${comments.length} 条 (page=$page)')),
      );
      setState(() => _dataTabKey++); // 强制重建 CommentTab
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✗ 下载评论失败: $e')),
      );
    }
  }

  // ─── 下载弹幕 (手动) ──────────────────────────

  Future<void> _showDownloadDanmakuSheet() async {
    final result = await showModalBottomSheet<_DanmakuDownloadConfig>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _DownloadDanmakuSheet(),
    );
    if (result == null) return;

    final db = ref.read(databaseProvider);
    final page = _selectedPage == 0 ? 1 : _selectedPage;
    final existingCount = await db.getDanmakuCount(widget.bvid);
    if (existingCount > 0) {
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('已有弹幕数据'),
          content: Text('当前有 \$existingCount 条弹幕, 覆盖吗?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('覆盖')),
          ],
        ),
      );
      if (overwrite != true) return;
    }

    _showLoading('拉取弹幕中...');
    try {
      // 直接从 B站 API 拿 cid (不再依赖本地 videos 表, 无需先下字幕)
      final bili = ref.read(bilibiliClientProvider);
      final cid = await bili.getCidForPage(widget.bvid, page: page);
      if (!mounted) return;
      Navigator.pop(context);
      if (cid == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('cid 为 0, 请检查视频是否存在')),
        );
        return;
      }
      final client = ref.read(danmakuClientProvider);
      final fetched = await client.fetchDanmaku(cid);
      if (!mounted) return;
      if (fetched.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✗ \${fetched.error}'), duration: const Duration(seconds: 4)),
        );
        return;
      }
      if (fetched.danmaku.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该视频暂无弹幕')),
        );
        return;
      }
      // 过滤
      var danmaku = fetched.danmaku;
      if (result.filterShort) {
        danmaku = danmaku.where((d) => d.content.length >= result.minLength).toList();
      }
      if (result.filterDigits) {
        danmaku = danmaku.where((d) {
          final t = d.content.trim();
          return !RegExp(r'^[\\d\\?\\!\\.\\s]+\$').hasMatch(t);
        }).toList();
      }
      if (result.filterDuplicate) {
        final seen = <String>{};
        danmaku = danmaku.where((d) {
          final key = d.content.length > 20 ? d.content.substring(0, 20) : d.content;
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        }).toList();
      }
      if (danmaku.length > result.maxCount) {
        danmaku = danmaku.take(result.maxCount).toList();
      }
      // 存 DB
      await db.clearDanmaku(widget.bvid, page: page);
      await db.insertDanmaku(danmaku.map((d) => DanmakuCompanion.insert(
        bvid: widget.bvid,
        cid: cid,
        progress: d.progress,
        time: d.time,
        content: d.content,
        color: Value(d.color),
      )).toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ 弹幕已保存: \${danmaku.length} 条')),
      );
      setState(() => _dataTabKey++); // 强制重建 DanmakuTab
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✗ 下载弹幕失败: \$e')),
      );
    }
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
    await ref.read(generationProvider.notifier).startSummaryGeneration(
      bvid: widget.bvid,
      subtitle: subtitle,
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
    await ref.read(generationProvider.notifier).continueSummary(
      bvid: widget.bvid,
      subtitle: widget.subtitle!,
      existingContent: s.content,
      page: s.page,
    );
    // 刷新总结列表
    widget.onChanged();
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
  final int selectedPage;
  const _ChatTab({super.key, required this.bvid, required this.subtitle, this.selectedPage = 1});

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

  // 数据源选择
  Set<DataSource> _chatSources = {DataSource.subtitle};
  List<Comment> _comments = [];
  List<DanmakuData> _danmaku = [];

  @override
  void initState() {
    super.initState();
    _initSession();
    _loadSources();
  }

  int get _page => widget.selectedPage == 0 ? 1 : widget.selectedPage;

  Future<void> _loadSources() async {
    final dbLocal = ref.read(databaseProvider);
    _comments = await dbLocal.getCommentsForVideo(widget.bvid, page: _page);
    _danmaku = await dbLocal.getDanmakuForVideo(widget.bvid, page: _page);
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant _ChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 分P 切换时: 重新计算 tokens + 重新加载评论/弹幕数据
    if (oldWidget.subtitle != widget.subtitle) {
      final msgsTotal = _messages.fold(0, (sum, m) => sum + m.content.length);
      setState(() {
        _tokensUsed = LLMClient.estimateTokens(
          '${widget.subtitle?.fullText ?? ''}$msgsTotal',
        );
      });
    }
    if (oldWidget.selectedPage != widget.selectedPage) {
      _loadSources();
    }
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

    // 构造上下文 (根据数据源 chip 选择)
    final subText = widget.subtitle?.fullText ?? '';
    final commentText = _chatSources.contains(DataSource.comment)
        ? _comments.map((c) => '【${c.likes}赞】${c.uname}: ${c.content}').join('\n')
        : '';
    final danmakuText = _chatSources.contains(DataSource.danmaku)
        ? _danmaku.take(300).map((d) => '[${_fmtTimeMs(d.progress)}] ${d.content}').join('\n')
        : '';

    final sourceContext = <String>[];
    if (subText.isNotEmpty && _chatSources.contains(DataSource.subtitle)) {
      final truncated = subText.length > 4000 ? '${subText.substring(0, 4000)}...(已截断)' : subText;
      sourceContext.add('## 字幕文本\n' + truncated);
    }
    if (commentText.isNotEmpty) {
      final truncated = commentText.length > 2000 ? '${commentText.substring(0, 2000)}...(已截断)' : commentText;
      sourceContext.add('## 评论\n' + truncated);
    }
    if (danmakuText.isNotEmpty) {
      final truncated = danmakuText.length > 2000 ? '${danmakuText.substring(0, 2000)}...(已截断)' : danmakuText;
      sourceContext.add('## 弹幕\n' + truncated);
    }

    final sessionMsgs = await repo.getChatMessages(session.id);
    final history = sessionMsgs
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    // 使用模板渲染 system prompt (但用选中的数据源替换字幕)
    final templates = ref.read(templatesProvider);
    final activeChat = templates.activeChat;
    final chatTemplate = activeChat?.content ??
        (config.chatTemplate.isNotEmpty ? config.chatTemplate : llm_tpl.defaultChatTemplate);
    // Build source text from selected chips
    final sourceText = sourceContext.join('\n\n');
    final systemPrompt = llm_tpl.PromptTemplate.render(chatTemplate, {
      'title': 'BV ${widget.bvid}',
      'bvid': widget.bvid,
      'subtitle': sourceText,
      'subtitle_truncated': sourceText,
      'language': widget.subtitle?.language ?? '',
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

  String _fmtTimeMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '\${m.toString().padLeft(2, "0")}:\${(s % 60).toString().padLeft(2, "0")}';
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
        // 数据源 chip
        Container(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(
            children: [
              const Text('数据源:', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              ...DataSource.values.map((s) {
                // 判断是否可点: subtitle 由 widget.subtitle 决定; comment/danmaku 由列表长度决定
                final available = switch (s) {
                  DataSource.subtitle => widget.subtitle != null,
                  DataSource.comment => _comments.isNotEmpty,
                  DataSource.danmaku => _danmaku.isNotEmpty,
                };
                return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilterChip(
                  label: Text(s.label, style: const TextStyle(fontSize: 10)),
                  selected: _chatSources.contains(s),
                  onSelected: available ? (sel) {
                    setState(() {
                      if (sel) {
                        _chatSources.add(s);
                      } else {
                        _chatSources.remove(s);
                      }
                    });
                  } : null,
                  visualDensity: VisualDensity.compact,
                  tooltip: available ? null : '${s.label} 未下载',
                  backgroundColor: available ? null : Colors.grey.shade200,
                ),
              );}),
            ],
          ),
        ),
        _ChatSubtitleContext(subtitle: widget.subtitle, selectedPage: widget.selectedPage),
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

class _ChatSubtitleContext extends StatelessWidget {
  final VideoSubtitle? subtitle;
  final int selectedPage;
  const _ChatSubtitleContext({required this.subtitle, required this.selectedPage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSub = subtitle != null;
    final pageLabel = selectedPage == 0 ? '整体' : 'P$selectedPage';
    return Material(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(
              hasSub ? Icons.subtitles_outlined : Icons.subtitles_off_outlined,
              size: 14,
              color: hasSub ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasSub
                    ? '📑 $pageLabel · ${subtitle!.language} · ${subtitle!.entries.length} 条'
                    : '未加载字幕 · $pageLabel',
                style: TextStyle(
                  fontSize: 12,
                  color: hasSub ? scheme.onSurface : scheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              hasSub ? '~${LLMClient.estimateTokens(subtitle!.fullText)} tokens' : '',
              style: TextStyle(fontSize: 11, color: scheme.outline),
            ),
          ],
        ),
      ),
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

// ─── 下载评论 配置 + Sheet ─────────────────────────────────

class _CommentDownloadConfig {
    final String mode;     // 'first' | 'random'
    final int maxCount;
    final int minLength;   // 短内容阈值 (字符数)
    final bool filterShort;
    final bool filterDigits;
    final bool filterDuplicate;

    const _CommentDownloadConfig({
        required this.mode,
        required this.maxCount,
        this.minLength = 2,
        this.filterShort = false,
        this.filterDigits = false,
        this.filterDuplicate = false,
    });
}

class _DownloadCommentsSheet extends StatefulWidget {
    const _DownloadCommentsSheet();

    @override
    State<_DownloadCommentsSheet> createState() => _DownloadCommentsSheetState();
}

class _DownloadCommentsSheetState extends State<_DownloadCommentsSheet> {
    String _mode = 'first';
    int _maxCount = 100;
    int _minLength = 2;
    bool _filterShort = false;
    bool _filterDigits = true;
    bool _filterDuplicate = true;

    @override
    Widget build(BuildContext context) {
        return SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text('下载评论', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('B 站评论手动下载, 按 (bvid, page) 分P 存',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 16),
                        const Text('采样方式', style: TextStyle(fontWeight: FontWeight.bold)),
                        RadioListTile(
                            value: 'first', groupValue: _mode,
                            onChanged: (v) => setState(() => _mode = v!),
                            title: const Text('前 N 条 (按时间/热度)'),
                        ),
                        RadioListTile(
                            value: 'random', groupValue: _mode,
                            onChanged: (v) => setState(() => _mode = v!),
                            title: const Text('随机 N 条'),
                        ),
                        const SizedBox(height: 8),
                        const Text('下载数量', style: TextStyle(fontWeight: FontWeight.bold)),
                        Slider(
                            value: _maxCount.toDouble(),
                            min: 20, max: 500, divisions: 24,
                            label: '$_maxCount 条',
                            onChanged: (v) => setState(() => _maxCount = v.round()),
                        ),
                        Text('共 $_maxCount 条', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const Divider(),
                        const Text('过滤选项', style: TextStyle(fontWeight: FontWeight.bold)),
                        CheckboxListTile(
                            value: _filterShort,
                            onChanged: (v) => setState(() => _filterShort = v ?? false),
                            title: const Text('过滤短内容'),
                            subtitle: Slider(
                                value: _minLength.toDouble(),
                                min: 1, max: 10, divisions: 9,
                                label: '< $_minLength 字',
                                onChanged: _filterShort ? (v) => setState(() => _minLength = v.round()) : null,
                            ),
                            dense: true,
                        ),
                        CheckboxListTile(
                            value: _filterDigits,
                            onChanged: (v) => setState(() => _filterDigits = v ?? false),
                            title: const Text('过滤纯数字/标点 (1234, ???)'),
                            dense: true,
                        ),
                        CheckboxListTile(
                            value: _filterDuplicate,
                            onChanged: (v) => setState(() => _filterDuplicate = v ?? false),
                            title: const Text('过滤重复 (前 20 字去重)'),
                            dense: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                            children: [
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('取消'),
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: FilledButton.icon(
                                        onPressed: () {
                                            Navigator.pop(context,
                                                _CommentDownloadConfig(
                                                    mode: _mode,
                                                    maxCount: _maxCount,
                                                    minLength: _minLength,
                                                    filterShort: _filterShort,
                                                    filterDigits: _filterDigits,
                                                    filterDuplicate: _filterDuplicate,
                                                ));
                                        },
                                        icon: const Icon(Icons.download),
                                        label: const Text('下载'),
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        );
    }
}

// ─── 下载弹幕 配置 + Sheet ─────────────────────────────────

class _DanmakuDownloadConfig {
    final int maxCount;
    final int minLength;   // 短内容阈值
    final bool filterShort;
    final bool filterDigits;
    final bool filterDuplicate;

    const _DanmakuDownloadConfig({
        required this.maxCount,
        this.minLength = 2,
        this.filterShort = false,
        this.filterDigits = false,
        this.filterDuplicate = false,
    });
}

class _DownloadDanmakuSheet extends StatefulWidget {
    const _DownloadDanmakuSheet();

    @override
    State<_DownloadDanmakuSheet> createState() => _DownloadDanmakuSheetState();
}

class _DownloadDanmakuSheetState extends State<_DownloadDanmakuSheet> {
    int _maxCount = 200;
    int _minLength = 2;
    bool _filterShort = false;
    bool _filterDigits = true;
    bool _filterDuplicate = true;

    @override
    Widget build(BuildContext context) {
        return SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text('下载弹幕', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('B 站弹幕手动下载, 按 (bvid, page) 分P 存\n格式: <d p="time,type,...">内容</d>',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 16),
                        const Text('下载数量', style: TextStyle(fontWeight: FontWeight.bold)),
                        Slider(
                            value: _maxCount.toDouble(),
                            min: 50, max: 1000, divisions: 19,
                            label: '$_maxCount 条',
                            onChanged: (v) => setState(() => _maxCount = v.round()),
                        ),
                        Text('共 $_maxCount 条', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const Divider(),
                        const Text('过滤选项', style: TextStyle(fontWeight: FontWeight.bold)),
                        CheckboxListTile(
                            value: _filterShort,
                            onChanged: (v) => setState(() => _filterShort = v ?? false),
                            title: const Text('过滤短内容'),
                            subtitle: Slider(
                                value: _minLength.toDouble(),
                                min: 1, max: 10, divisions: 9,
                                label: '< $_minLength 字',
                                onChanged: _filterShort ? (v) => setState(() => _minLength = v.round()) : null,
                            ),
                            dense: true,
                        ),
                        CheckboxListTile(
                            value: _filterDigits,
                            onChanged: (v) => setState(() => _filterDigits = v ?? false),
                            title: const Text('过滤纯数字/标点'),
                            dense: true,
                        ),
                        CheckboxListTile(
                            value: _filterDuplicate,
                            onChanged: (v) => setState(() => _filterDuplicate = v ?? false),
                            title: const Text('过滤重复 (前 20 字去重)'),
                            dense: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                            children: [
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('取消'),
                                    ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: FilledButton.icon(
                                        onPressed: () {
                                            Navigator.pop(context,
                                                _DanmakuDownloadConfig(
                                                    maxCount: _maxCount,
                                                    minLength: _minLength,
                                                    filterShort: _filterShort,
                                                    filterDigits: _filterDigits,
                                                    filterDuplicate: _filterDuplicate,
                                                ));
                                        },
                                        icon: const Icon(Icons.download),
                                        label: const Text('下载'),
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        );
    }
}
