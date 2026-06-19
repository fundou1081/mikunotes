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
import 'package:mikunotes/ui/screens/video_detail/data_tabs.dart';
import 'package:mikunotes/core/storage/database.dart' show DanmakuData, Comment;
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/core/storage/database.dart' show CommentsCompanion, DanmakuCompanion;
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' show Value;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:mikunotes/ui/screens/video_detail/sheets/download_comments_sheet.dart';
import 'package:mikunotes/ui/screens/video_detail/sheets/download_danmaku_sheet.dart';
import 'package:mikunotes/ui/screens/video_detail/sheets/download_comments_sheet.dart';
import 'package:mikunotes/ui/screens/video_detail/sheets/download_danmaku_sheet.dart';
import 'package:mikunotes/ui/screens/video_detail/tabs/summary_tab.dart';
import 'package:mikunotes/ui/screens/video_detail/tabs/chat_tab.dart';

/// 默认总结 prompt

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
          SummaryTab(bvid: widget.bvid, subtitle: _subtitle, onChanged: _loadAll, selectedPage: _selectedPage, pageCount: _pageCount),
          CommentTab(key: ValueKey('comment_$_dataTabKey'), bvid: widget.bvid, selectedPage: _selectedPage, onDownloadRequest: _showDownloadCommentsSheet),
          DanmakuTab(key: ValueKey('danmaku_$_dataTabKey'), bvid: widget.bvid, selectedPage: _selectedPage, onDownloadRequest: _showDownloadDanmakuSheet),
          ChatTab(key: ValueKey('chat_$_dataTabKey'), bvid: widget.bvid, subtitle: _subtitle, selectedPage: _selectedPage),
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
    final result = await showModalBottomSheet<CommentDownloadConfig>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const DownloadCommentsSheet(),
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
    final result = await showModalBottomSheet<DanmakuDownloadConfig>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const DownloadDanmakuSheet(),
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

