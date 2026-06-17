import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/providers/providers.dart';

/// 从 B 站稍后观看批量导入 — 显示视频卡片, 一键导入 / 选择性导入
class ImportWatchLaterScreen extends ConsumerStatefulWidget {
  const ImportWatchLaterScreen({super.key});
  @override
  ConsumerState<ImportWatchLaterScreen> createState() => _ImportWatchLaterScreenState();
}

class _ImportWatchLaterScreenState extends ConsumerState<ImportWatchLaterScreen> {
  List<Map<String, String>> _videos = [];
  Set<String> _existing = {};
  Set<String> _selected = {};
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  bool _importing = false;
  int _progress = 0;
  int _progressTotal = 0;
  int _containerId = 0;
  String _search = '';
  String? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _initLoad();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(containerListProvider.notifier).syncWatchLater();
      final db = ref.read(databaseProvider);
      final c = await (db.select(db.containers)..where((c) => c.type.equals('watch_later'))).getSingleOrNull();
      if (c == null) throw Exception('稍后观看容器创建失败');
      _containerId = c.id;
      final allVids = await db.getAllVideos();
      _existing = allVids.map((v) => v.bvid).toSet();
      final bili = ref.read(bilibiliClientProvider);
      final result = await bili.getWatchLaterWithInfo(pn: 1, ps: 20);
      final videos = (result['videos'] as List<Map>).map((m) => {
        'bvid': m['bvid'] as String,
        'title': m['title'] as String,
        'cover': m['cover'] as String,
        'uploader': m['uploader'] as String,
        'duration': m['duration'] as String,
      }).toList();
      setState(() {
        _videos = videos;
        _hasMore = result['has_more'] as bool;
        _page = 1;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200 &&
        !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final bili = ref.read(bilibiliClientProvider);
      final result = await bili.getWatchLaterWithInfo(pn: _page + 1, ps: 20);
      final videos = (result['videos'] as List<Map>).map((m) => {
        'bvid': m['bvid'] as String,
        'title': m['title'] as String,
        'cover': m['cover'] as String,
        'uploader': m['uploader'] as String,
        'duration': m['duration'] as String,
      }).toList();
      setState(() {
        _videos.addAll(videos);
        _hasMore = result['has_more'] as bool;
        _page++;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  List<Map<String, String>> get _filtered {
    if (_search.isEmpty) return _videos;
    return _videos.where((v) =>
        v['bvid']!.toLowerCase().contains(_search.toLowerCase()) ||
        v['title']!.toLowerCase().contains(_search.toLowerCase())).toList();
  }

  int get _totalNotImported =>
      _videos.where((v) => !_existing.contains(v['bvid'])).length;

  Future<void> _importAll() async {
    final notImported = _videos.where((v) => !_existing.contains(v['bvid'])).toList();
    if (notImported.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有视频都已导入 ✓')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('一键导入?'),
        content: Text('将导入 ${notImported.length} 个未导入视频。\n\n不会下载字幕。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('导入')),
        ],
      ),
    );
    if (ok != true) return;
    await _doBatchImport(notImported.map((v) => v['bvid']!).toList());
  }

  Future<void> _importSelected() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先勾选视频')),
      );
      return;
    }
    await _doBatchImport(_selected.toList());
  }

  Future<void> _doBatchImport(List<String> bvids) async {
    setState(() { _importing = true; _progress = 0; _progressTotal = bvids.length; });
    final repo = ref.read(videoRepositoryProvider);
    final result = await repo.batchAddToContainer(bvids, _containerId,
      onProgress: (d, t) { if (mounted) setState(() => _progress = d); },
    );
    if (!mounted) return;
    setState(() {
      _importing = false;
      _existing.addAll((result['alreadyInDb'] as List).cast<String>());
    });
    final s = (result['success'] as List).length;
    final f = (result['failed'] as List).length;
    _existing.addAll((result['success'] as List).cast<String>());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✓ 成功 $s 个, 失败 $f 个'), duration: const Duration(seconds: 3)),
    );
    ref.read(containerListProvider.notifier).load();
    ref.read(videoListProvider.notifier).load();
    ref.read(videosInContainerProvider(_containerId).notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('从稍后观看导入'),
        actions: [
          if (!_loading && _selected.isNotEmpty)
            TextButton.icon(
              onPressed: _importing ? null : _importSelected,
              icon: const Icon(Icons.checklist, size: 18),
              label: Text('导入选中 (${_selected.length})'),
            ),
          if (!_loading)
            TextButton.icon(
              onPressed: _importing ? null : _importAll,
              icon: const Icon(Icons.download),
              label: Text('一键导入 ($_totalNotImported)'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _importing
              ? _buildImporting()
              : _error != null
                  ? _buildError()
                  : _buildList(),
    );
  }

  Widget _buildImporting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('正在导入 $_progress / $_progressTotal',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(width: 240,
            child: LinearProgressIndicator(
                value: _progressTotal == 0 ? 0 : _progress / _progressTotal, minHeight: 6)),
          const SizedBox(height: 16),
          const Text('不会下载字幕, 进视频详情手动下',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('加载失败: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _initLoad, child: const Text('重试')),
        ]),
      ),
    );
  }

  Widget _buildList() {
    final filtered = _filtered;
    final alreadyCount = _videos.where((v) => _existing.contains(v['bvid'])).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(children: [
            Text('总计 ${_videos.length}', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            Text('已导入 $alreadyCount',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 12),
            Text('未导入 ${_videos.length - alreadyCount}',
                style: const TextStyle(fontSize: 12, color: Colors.orange)),
            const Spacer(),
            if (filtered.isNotEmpty)
              TextButton(
                onPressed: () {
                  final notInFiltered = filtered.where((v) => !_existing.contains(v['bvid'])).toList();
                  final all = notInFiltered.map((v) => v['bvid']!).toSet();
                  if (_selected.containsAll(all)) {
                    _selected.removeAll(all);
                  } else {
                    _selected.addAll(all);
                  }
                  setState(() {});
                },
                child: const Text('全选未导入', style: TextStyle(fontSize: 12)),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: '搜索 BV号/标题...',
              prefixIcon: Icon(Icons.search), isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('没找到', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  controller: _scroll,
                  itemCount: filtered.length + (_loadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= filtered.length) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final m = filtered[index];
                    return _VideoCard(
                      bvid: m['bvid']!,
                      title: m['title']!,
                      cover: m['cover']!,
                      uploader: m['uploader']!,
                      duration: m['duration']!,
                      isInDb: _existing.contains(m['bvid']),
                      isSelected: _selected.contains(m['bvid']),
                      onToggle: (v) => setState(() {
                        if (v) { _selected.add(m['bvid']!); }
                        else { _selected.remove(m['bvid']!); }
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final String bvid, title, cover, uploader, duration;
  final bool isInDb, isSelected;
  final ValueChanged<bool> onToggle;

  const _VideoCard({
    required this.bvid, required this.title, required this.cover,
    required this.uploader, required this.duration,
    required this.isInDb, required this.isSelected, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: isInDb ? null : (v) => onToggle(v ?? false),
      title: Row(children: [
        if (cover.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(cover, width: 60, height: 45, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(width: 60, height: 45,
                  child: Icon(Icons.video_library_outlined, size: 24))),
          ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: isInDb ? Colors.grey : null)),
            const SizedBox(height: 4),
            Text('$uploader · ${_fmt(int.tryParse(duration) ?? 0)}',
                style: TextStyle(fontSize: 11,
                    color: Theme.of(context).colorScheme.outline)),
            if (isInDb)
              const Text('已在视频库', style: TextStyle(fontSize: 10, color: Colors.green)),
          ],
        )),
      ]),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60; final ss = s % 60;
    return m >= 60
        ? '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}'
        : '$m:${ss.toString().padLeft(2, '0')}';
  }
}
