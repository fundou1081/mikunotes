import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';

/// 批量导入页配置
class BatchImportConfig {
  final String appBarTitle;
  final String hintText; // "收藏夹" / "稍后观看" / "UP 主"
  final Future<int> Function() resolveContainerId;
  final Future<List<Map<String, String>>> Function(int page, int pageSize) loadPage;
  final int? totalCount; // null = unknown (稍后观看: 边拉边算)
  final Future<void> Function()? onSync; // 可选, null = 不自动 sync

  const BatchImportConfig({
    required this.appBarTitle,
    required this.hintText,
    required this.resolveContainerId,
    required this.loadPage,
    this.totalCount,
    this.onSync,
  });
}

/// 通用批量导入页: 显示视频卡片, 一键导入 / 选择性导入
class BatchImportScreen extends ConsumerStatefulWidget {
  final BatchImportConfig config;
  const BatchImportScreen({super.key, required this.config});

  @override
  ConsumerState<BatchImportScreen> createState() => _BatchImportScreenState();
}

class _BatchImportScreenState extends ConsumerState<BatchImportScreen> {
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
      // 容器可能还没创建 (例如首次打开稍后观看)
      // 如果 resolveContainerId 抛错, 显示"请先同步"提示
      try {
        _containerId = await widget.config.resolveContainerId();
      } catch (_) {
        if (mounted) setState(() { _loading = false; _error = '需要先同步'; });
        return;
      }
      final db = ref.read(databaseProvider);
      _existing = (await db.getAllVideos()).map((v) => v.bvid).toSet();
      final result = await widget.config.loadPage(1, 20);
      setState(() {
        _videos = result;
        _hasMore = result.length >= 20;
        _page = 1;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onScroll() {
    final p = _scroll.position;
    if (p.pixels > p.maxScrollExtent - 200 && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final result = await widget.config.loadPage(_page + 1, 20);
      setState(() {
        _videos.addAll(result);
        _hasMore = result.length >= 20;
        _page++;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  List<Map<String, String>> get _filtered {
    if (_search.isEmpty) return _videos;
    return _videos.where((v) {
      final b = v['bvid']!; final t = v['title']!;
      return b.toLowerCase().contains(_search.toLowerCase()) ||
             t.toLowerCase().contains(_search.toLowerCase());
    }).toList();
  }

  int get _totalNotImported =>
      _videos.where((v) => !_existing.contains(v['bvid'])).length;

  Future<void> _sync() async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.config.onSync == null) return;
    setState(() => _loading = true);
    try {
      await widget.config.onSync!.call();
      messenger.showSnackBar(const SnackBar(content: Text('✓ 同步完成')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('✗ 同步失败: $e')));
    }
    if (mounted) setState(() => _loading = false);
    if (mounted) _initLoad();
  }

  Future<void> _importAll() async {
    final notImported = _videos
        .where((v) => !_existing.contains(v['bvid'])).toList();
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
        content: Text('将导入 ${notImported.length} 个视频。\n\n不会下载字幕。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(c, true),
              child: const Text('导入')),
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
    final result = await repo.batchAddToContainer(
      bvids, _containerId,
      onProgress: (d, _) { if (mounted) setState(() => _progress = d); },
    );
    if (!mounted) return;
    setState(() {
      _importing = false;
      _existing.addAll((result['alreadyInDb'] as List).cast<String>());
      _existing.addAll((result['success'] as List).cast<String>());
    });
    final s = (result['success'] as List).length;
    final f = (result['failed'] as List).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✓ 成功 $s 个, 失败 $f 个'),
          duration: const Duration(seconds: 3)),
    );
    ref.read(containerListProvider.notifier).load();
    ref.read(videoListProvider.notifier).load();
    ref.read(videosInContainerProvider(_containerId).notifier).load();
    ref.read(allFavoriteVideosProvider.notifier).load();
    ref.read(allUpMasterVideosProvider.notifier).load();
    ref.read(upMasterListProvider.notifier).load();
  }

  // ── UI ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.appBarTitle),
        actions: [
          if (!_loading && widget.config.onSync != null)
            TextButton.icon(
              onPressed: _importing ? null : _sync,
              icon: const Icon(Icons.cloud_sync),
              label: const Text('同步'),
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
              ? _ImportProgressWidget(progress: _progress, total: _progressTotal)
              : _error != null
                  ? _ImportErrorWidget(
                      error: _error!, onRetry: _sync,
                      retryLabel: _error!.contains('同步') ? '从 B 站同步' : '重试')
                  : _buildList(),
    );
  }

  Widget _buildList() {
    final filtered = _filtered;
    final alreadyCount = _videos.where((v) => _existing.contains(v['bvid'])).length;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 统计 + 操作栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: cs.surfaceContainerHighest,
          child: Row(children: [
            Text('总计 ${_videos.length}', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            Text('已导入 $alreadyCount',
                style: TextStyle(fontSize: 12, color: cs.primary)),
            const SizedBox(width: 12),
            Text('未导入 ${_videos.length - alreadyCount}',
                style: const TextStyle(fontSize: 12, color: Colors.orange)),
            const Spacer(),
            if (filtered.isNotEmpty)
              TextButton(
                onPressed: () {
                  final notInFiltered = filtered
                      .where((v) => !_existing.contains(v['bvid'])).toList();
                  final all = notInFiltered.map((v) => v['bvid']!).toSet();
                  setState(() {
                    if (_selected.containsAll(all)) {
                      _selected.removeAll(all);
                    } else {
                      _selected.addAll(all);
                    }
                  });
                },
                child: const Text('全选未导入', style: TextStyle(fontSize: 12)),
              ),
            const SizedBox(width: 8),
            if (_selected.isNotEmpty)
              FilledButton.tonalIcon(
                onPressed: _importSelected,
                icon: const Icon(Icons.checklist, size: 16),
                label: Text('${_selected.length}个', style: const TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ]),
        ),
        // 搜索
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索 BV号/标题...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: const OutlineInputBorder(),
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
                    return _ImportVideoCard(
                      bvid: m['bvid']!,
                      title: m['title']!,
                      cover: m['cover']!,
                      uploader: m['uploader']!,
                      duration: int.tryParse(m['duration'] ?? '0') ?? 0,
                      isInDb: _existing.contains(m['bvid']),
                      isSelected: _selected.contains(m['bvid']),
                      onToggle: (v) => setState(() {
                        v ? _selected.add(m['bvid']!) : _selected.remove(m['bvid']!);
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Shared reusable widgets ─────────────────────────────

class _ImportVideoCard extends StatelessWidget {
  final String bvid, title, cover, uploader;
  final int duration;
  final bool isInDb, isSelected;
  final ValueChanged<bool> onToggle;

  const _ImportVideoCard({
    required this.bvid, required this.title, required this.cover,
    required this.uploader, required this.duration,
    required this.isInDb, required this.isSelected, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CheckboxListTile(
      value: isSelected,
      onChanged: isInDb ? null : (v) => onToggle(v ?? false),
      title: Row(children: [
        if (cover.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(cover, width: 60, height: 45, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                  width: 60, height: 45,
                  child: Icon(Icons.video_library_outlined, size: 24))),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: isInDb ? Colors.grey : null)),
            const SizedBox(height: 4),
            Text('$uploader · ${_fmt(duration)}',
                style: TextStyle(fontSize: 11, color: cs.outline)),
            if (isInDb)
              const Text('已在视频库', style: TextStyle(fontSize: 10, color: Colors.green)),
          ]),
        ),
      ]),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60, ss = s % 60;
    return m >= 60
        ? '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}'
        : '$m:${ss.toString().padLeft(2, '0')}';
  }
}

class _ImportProgressWidget extends StatelessWidget {
  final int progress, total;
  const _ImportProgressWidget({required this.progress, required this.total});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('正在导入 $progress / $total',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(width: 240,
            child: LinearProgressIndicator(
                value: total == 0 ? 0 : progress / total, minHeight: 6)),
          const SizedBox(height: 16),
          const Text('不会下载字幕, 进视频详情手动下',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _ImportErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final String? retryLabel;
  const _ImportErrorWidget({required this.error, required this.onRetry, this.retryLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_isSyncNeeded(error) ? Icons.cloud_off : Icons.error_outline,
              size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: Icon(_isSyncNeeded(error) ? Icons.cloud_sync : Icons.refresh),
            label: Text(retryLabel ?? (_isSyncNeeded(error) ? '从 B 站同步' : '重试')),
          ),
        ]),
      ),
    );
  }

  bool _isSyncNeeded(String e) => e.contains('需要先同步') || e.contains('未登录') || e.contains('未创建');
}
