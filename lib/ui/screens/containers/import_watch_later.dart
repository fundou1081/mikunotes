import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';

/// 从 B 站稍后观看批量导入
class ImportWatchLaterScreen extends ConsumerStatefulWidget {
  const ImportWatchLaterScreen({super.key});

  @override
  ConsumerState<ImportWatchLaterScreen> createState() => _ImportWatchLaterScreenState();
}

class _ImportWatchLaterScreenState extends ConsumerState<ImportWatchLaterScreen> {
  List<String> _bvids = [];
  Set<String> _existing = {};
  Set<String> _selected = {};
  bool _loading = true;
  bool _importing = false;
  int _progress = 0;
  int _progressTotal = 0;
  String? _error;
  int _containerId = 0;
  String _search = '';
  bool _selectAll = false;

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
      await ref.read(containerListProvider.notifier).syncWatchLater();
      final db = ref.read(databaseProvider);
      final c = await (db.select(db.containers)
            ..where((c) => c.type.equals('watch_later')))
          .getSingleOrNull();
      if (c == null) throw Exception('稍后观看容器创建失败');
      _containerId = c.id;
      final bili = ref.read(bilibiliClientProvider);
      final bvids = await bili.getWatchLaterBvids();
      final allVideos = await db.getAllVideos();
      _existing = allVideos.map((v) => v.bvid).toSet();
      setState(() {
        _bvids = bvids;
        _loading = false;
        _selected = {};
        _selectAll = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<String> get _filtered {
    if (_search.isEmpty) return _bvids;
    return _bvids.where((b) => b.toLowerCase().contains(_search.toLowerCase())).toList();
  }

  Future<void> _doImport() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要导入的视频')),
      );
      return;
    }
    setState(() {
      _importing = true;
      _progress = 0;
      _progressTotal = _selected.length;
    });
    final repo = ref.read(videoRepositoryProvider);
    final result = await repo.batchAddToContainer(
      _selected.toList(),
      _containerId,
      onProgress: (done, total) {
        if (mounted) setState(() => _progress = done);
      },
    );
    if (!mounted) return;
    setState(() {
      _importing = false;
      _existing.addAll((result['alreadyInDb'] as List).cast<String>());
    });
    final success = (result['success'] as List).length;
    final failed = (result['failed'] as List).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ 成功 $success 个, 失败 $failed 个'),
        duration: const Duration(seconds: 4),
      ),
    );
    ref.read(containerListProvider.notifier).load();
    ref.read(videoListProvider.notifier).load();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('从稍后观看导入'),
        actions: [
          if (!_loading)
            TextButton.icon(
              onPressed: _importing ? null : _doImport,
              icon: const Icon(Icons.download),
              label: Text('导入 (${_selected.length})'),
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('加载失败: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildImporting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text('正在导入 $_progress / $_progressTotal',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: 240,
              child: LinearProgressIndicator(
                value: _progressTotal == 0 ? 0 : _progress / _progressTotal,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            const Text('不会下载字幕, 进视频详情手动下',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final filtered = _filtered;
    final alreadyCount = _bvids.where((b) => _existing.contains(b)).length;
    final newCount = _bvids.length - alreadyCount;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '稍后观看导入的不会自动下载字幕, 进视频详情后手动下载。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Text('总计 ${_bvids.length}',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Text('已导入 $alreadyCount',
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 12),
              Text('未导入 $newCount',
                  style: const TextStyle(fontSize: 12, color: Colors.orange)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectAll = !_selectAll;
                    if (_selectAll) {
                      _selected = filtered.where((b) => !_existing.contains(b)).toSet();
                    } else {
                      _selected = {};
                    }
                  });
                },
                child: Text(_selectAll ? '取消全选' : '全选未导入'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: '搜索 BV 号',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('没找到', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final bvid = filtered[index];
                    final isInDb = _existing.contains(bvid);
                    final isSelected = _selected.contains(bvid);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: isInDb
                          ? null
                          : (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(bvid);
                                } else {
                                  _selected.remove(bvid);
                                }
                              });
                            },
                      title: Text(
                        bvid,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: isInDb ? Colors.grey : null,
                        ),
                      ),
                      subtitle: isInDb
                          ? const Text('已在视频库 (跳过)',
                              style: TextStyle(color: Colors.green, fontSize: 11))
                          : null,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
