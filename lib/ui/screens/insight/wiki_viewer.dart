import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/wiki/wiki_storage.dart';
import 'package:mikunotes/core/wiki/insight_storage.dart';
import 'package:mikunotes/ui/screens/video_detail/math_markdown.dart';
import 'package:mikunotes/ui/screens/video_detail/video_detail_screen.dart';
import 'package:mikunotes/ui/screens/insight/tag_list_screen.dart';
import 'package:mikunotes/ui/screens/insight/up_master_list_screen.dart';
import 'package:mikunotes/ui/screens/insight/cross_video_screen.dart';
import 'package:intl/intl.dart' show DateFormat;

/// 📚 Wiki 浏览 — 列出所有视频 + 洞察的 .md, 点击查看
class WikiViewer extends ConsumerStatefulWidget {
    const WikiViewer({super.key});

    @override
    ConsumerState<WikiViewer> createState() => _WikiViewerState();
}

class _WikiViewerState extends ConsumerState<WikiViewer> {
    List<WikiFileInfo> _files = [];
    List<InsightFileInfo> _insights = [];
    bool _loading = true;
    String? _error;

    @override
    void initState() {
        super.initState();
        _loadFiles();
    }

    Future<void> _loadFiles() async {
        setState(() {
            _loading = true;
            _error = null;
        });
        try {
            final storage = ref.read(wikiStorageProvider);
            final insightStorage = ref.read(insightStorageProvider);
            final files = await storage.listVideos();
            final insights = await insightStorage.list();
            setState(() {
                _files = files;
                _insights = insights;
                _loading = false;
            });
        } catch (e) {
            setState(() {
                _error = '$e';
                _loading = false;
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        if (_loading) {
            return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
            return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 12),
                        Text('加载失败: $_error'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                            onPressed: _loadFiles,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试'),
                        ),
                    ],
                ),
            );
        }
        if (_files.isEmpty && _insights.isEmpty) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.description_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            Text('暂无 Wiki 记录',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                                '回到视频管理, 导入视频/生成总结/对话, 都会自动生成 .md',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.outline,
                                ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                                '目录: <app>/Documents/MikuNotes_wiki/',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.outline,
                                ),
                            ),
                        ],
                    ),
                ),
            );
        }
        return Column(
            children: [
                // 顶部信息条
                Container(
                    padding: const EdgeInsets.all(12),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Row(
                        children: [
                            Icon(Icons.folder,
                                color: Theme.of(context).colorScheme.onPrimaryContainer),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    '共 ${_files.length} 个视频 · ${_insights.length} 个洞察',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                ),
                            ),
                            IconButton(
                                icon: const Icon(Icons.refresh),
                                tooltip: '刷新',
                                onPressed: _loadFiles,
                            ),
                        ],
                    ),
                ),
                // 🔮 跨视频洞察入口
                Card(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: ListTile(
                        leading: Icon(Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.onTertiaryContainer),
                        title: Text('跨视频洞察',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                            )),
                        subtitle: Text('选 2+ 个视频 · LLM 生成深度分析报告',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                                fontSize: 12,
                            )),
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: Theme.of(context).colorScheme.onTertiaryContainer),
                        onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const CrossVideoScreen(),
                            ));
                            _loadFiles(); // 返回后刷新
                        },
                    ),
                ),
                // 文件列表
                Expanded(
                    child: ListView(
                        children: [
                            // 跨视频洞察 (历史)
                            if (_insights.isNotEmpty) ...[
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                    child: Row(
                                        children: [
                                            const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                                            const SizedBox(width: 4),
                                            Text(
                                                '跨视频洞察 (${_insights.length})',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.purple,
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                                for (final i in _insights)
                                    ListTile(
                                        leading: const Icon(Icons.lightbulb, color: Colors.purple),
                                        title: Text(
                                            i.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                            '${i.videoBvids.length} 视频 · ${_formatTime(i.createdAt)} · ${_formatSize(i.sizeBytes)}',
                                            style: const TextStyle(fontSize: 11),
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                        onTap: () => _openInsight(i),
                                    ),
                                const Divider(height: 1),
                            ],
                            // 视频文件
                            if (_files.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                    child: Row(
                                        children: [
                                            const Icon(Icons.description, size: 16, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                                '视频 Wiki (${_files.length})',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            for (final f in _files)
                                ListTile(
                                    leading: const Icon(Icons.description, color: Colors.blue),
                                    title: Text(
                                        f.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                        '${f.bvid} · ${_formatSize(f.sizeBytes)} · ${_formatTime(f.modifiedAt)}',
                                        style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                    onTap: () => _openFile(f),
                                ),
                            const SizedBox(height: 20),
                        ],
                    ),
                ),
            ],
        );
    }

    Future<void> _openInsight(InsightFileInfo i) async {
        final content = await ref.read(insightStorageProvider).read(i.id);
        if (!mounted) return;
        Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => WikiFileViewer(
                    title: '🔮 ${i.title}',
                    content: content,
                ),
            ),
        );
    }

    Future<void> _openFile(WikiFileInfo f) async {
        final storage = ref.read(wikiStorageProvider);
        final content = await storage.readFile(f.path);
        if (!mounted) return;
        Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => WikiFileViewer(
                    title: '${f.bvid} · ${f.title}',
                    content: content,
                ),
            ),
        );
    }

    String _formatSize(int bytes) {
        if (bytes < 1024) return '${bytes}B';
        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
        return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
    }

    String _formatTime(DateTime t) {
        final now = DateTime.now();
        final diff = now.difference(t);
        if (diff.inMinutes < 1) return '刚刚';
        if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
        if (diff.inDays < 1) return '${diff.inHours}小时前';
        if (diff.inDays < 7) return '${diff.inDays}天前';
        return DateFormat('yyyy-MM-dd').format(t);
    }
}

/// 单个 .md 文件查看
class WikiFileViewer extends StatelessWidget {
    final String title;
    final String content;

    const WikiFileViewer({super.key, required this.title, required this.content});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: MathMarkdownBody(
                    data: content,
                    selectable: true,
                    onWikiLinkTap: (text, href, title) {
                        if (href == null) return;
                        // wiki:bv:BVxxx → 视频详情
                        if (href.startsWith('wiki:bv:')) {
                            final bvid = href.substring('wiki:bv:'.length);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => VideoDetailScreen(bvid: bvid),
                            ));
                        }
                        // wiki:tag:xxx → Tag 列表
                        else if (href.startsWith('wiki:tag:')) {
                            final tag = href.substring('wiki:tag:'.length);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => TagListScreen(tag: tag),
                            ));
                        }
                        // wiki:up:xxx (URL encoded) → UP 主列表
                        else if (href.startsWith('wiki:up:')) {
                            final encoded = href.substring('wiki:up:'.length);
                            final name = Uri.decodeComponent(encoded);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => UpMasterListScreen(uploaderName: name),
                            ));
                        }
                    },
                ),
            ),
        );
    }
}
