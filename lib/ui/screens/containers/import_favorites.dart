import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/containers/home_shell.dart';

/// 从 B 站收藏夹批量导入
/// Step 1: 选文件夹
/// Step 2: 进入该文件夹, 看到未导入视频列表, 全选/勾选, 批量入库 (不下字幕)
class ImportFavoritesScreen extends ConsumerStatefulWidget {
  const ImportFavoritesScreen({super.key});

  @override
  ConsumerState<ImportFavoritesScreen> createState() => _ImportFavoritesScreenState();
}

class _ImportFavoritesScreenState extends ConsumerState<ImportFavoritesScreen> {
  List<Map<String, dynamic>>? _folders;
  bool _loading = true;
  String? _error;

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
      final bili = ref.read(bilibiliClientProvider);
      final folders = await bili.getFavFolders();
      // 加上 DB 里的已导入数
      final containersState = ref.read(containerListProvider);
      final dbContainers = containersState.maybeWhen(
        data: (list) => list,
        orElse: () => <ContainerInfo>[],
      );
      for (final f in folders) {
        final fid = f['id']?.toString() ?? '';
        final match = dbContainers.where(
            (c) => c.type == ContainerType.favorite && c.externalId == fid);
        if (match.isNotEmpty) {
          f['_imported'] = match.first.importedCount;
          f['_containerId'] = match.first.id;
        } else {
          f['_imported'] = 0;
          f['_containerId'] = null;
        }
      }
      // 按 total 从大到小
      folders.sort((a, b) =>
          ((b['media_count'] as num?)?.toInt() ?? 0)
              .compareTo((a['media_count'] as num?)?.toInt() ?? 0));
      setState(() {
        _folders = folders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('从收藏夹导入'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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

  Widget _buildList() {
    if (_folders == null || _folders!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('没有收藏夹', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
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
                  '收藏夹导入的不会自动下载字幕, 进视频详情后手动下载。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _folders!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final f = _folders![index];
              final total = (f['media_count'] as num?)?.toInt() ?? 0;
              final imported = f['_imported'] as int? ?? 0;
              return ListTile(
                leading: const Icon(Icons.folder, size: 32),
                title: Text(f['title'] as String? ?? '未命名'),
                subtitle: Text('已导入 $imported / $total'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final fid = (f['id'] as num).toInt();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImportFavFolderScreen(
                        fid: fid,
                        title: f['title'] as String? ?? '未命名',
                        total: total,
                      ),
                    ),
                  );
                  // 返回后刷新
                  _load();
                  ref.read(containerListProvider.notifier).load();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 进入某个收藏夹: 列出未导入视频, 勾选导入
class ImportFavFolderScreen extends ConsumerStatefulWidget {
  final int fid;
  final String title;
  final int total;
  const ImportFavFolderScreen({
    super.key,
    required this.fid,
    required this.title,
    required this.total,
  });

  @override
  ConsumerState<ImportFavFolderScreen> createState() => _ImportFavFolderScreenState();
}

class _ImportFavFolderScreenState extends ConsumerState<ImportFavFolderScreen> {
  List<String> _bvids = []; // B站返回的 bvid 列表
  Set<String> _existing = {}; // DB 中已有的 bvid
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
      // 确保容器存在, 拿 containerId
      await ref.read(containerListProvider.notifier).syncFavFolders();
      final db = ref.read(databaseProvider);
      final c = await db.getContainerByExternalId(widget.fid.toString());
      if (c == null) throw Exception('容器创建失败');
      _containerId = c.id;
      // 拿 B 站收藏夹 BV 列表
      final bili = ref.read(bilibiliClientProvider);
      final bvids = await bili.getAllFavBvids(widget.fid, maxVideos: 2000);
      // 拿 DB 中已有的 (从视频库)
      final allVideos = await db.getAllVideos();
      _existing = allVideos.map((v) => v.bvid).toSet();
      // 不下字幕
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
    // 不立刻 pop, 让用户看到状态变化 (已选 BV 变灰)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ 成功 $success 个, 失败 $failed 个'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '去查看',
            onPressed: () {
              // pop 退出 ImportFavFolderScreen + ImportFavoritesScreen
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              // 切换到 ⭐ 收藏夹 Tab (index=1)
              HomeShell.tabKey.currentState?.switchToTab(1);
            },
          ),
        ),
      );
    }
    ref.read(containerListProvider.notifier).load();
    ref.read(videoListProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} (${widget.total})'),
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
        // 顶部信息条
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
        // 搜索
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
