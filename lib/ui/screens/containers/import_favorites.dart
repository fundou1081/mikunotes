import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/containers/home_shell.dart';
import 'package:mikunotes/ui/screens/containers/batch_import.dart';

/// 从 B 站收藏夹批量导入 — 选文件夹
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
    setState(() { _loading = true; _error = null; });
    try {
      final bili = ref.read(bilibiliClientProvider);
      final folders = await bili.getFavFolders();
      final containersState = ref.read(containerListProvider);
      final dbContainers = containersState.maybeWhen(
        data: (list) => list, orElse: () => <ContainerInfo>[],
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
      folders.sort((a, b) =>
          ((b['media_count'] as num?)?.toInt() ?? 0)
              .compareTo((a['media_count'] as num?)?.toInt() ?? 0));
      setState(() { _folders = folders; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('从收藏夹导入'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('加载失败: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('重试')),
        ]),
      ),
    );
  }

  Widget _buildList() {
    if (_folders == null || _folders!.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('没有收藏夹', style: TextStyle(color: Colors.grey)),
      ));
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(children: [
            const Icon(Icons.info_outline, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('收藏夹导入的不会自动下载字幕，进视频详情后手动下载。',
                style: Theme.of(context).textTheme.bodySmall)),
          ]),
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
                  final r = ref; // capture for closure
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BatchImportScreen(config: BatchImportConfig(
                      appBarTitle: '${f['title']} ($total)',
                      hintText: '收藏夹',
                      resolveContainerId: () async {
                        final db = r.read(databaseProvider);
                        final c = await db.getContainerByExternalId(fid.toString());
                        if (c == null) throw Exception('容器创建失败');
                        return c.id;
                      },
                      loadPage: (page, ps) async {
                        final bili = r.read(bilibiliClientProvider);
                        final result = await bili.getFavVideosWithInfo(fid, pn: page, ps: ps);
                        final medias = (result['medias'] as List)
                            .map<Map<String, String>>((m) {
                              final mm = m as Map;
                              return {for (final e in mm.entries) e.key.toString(): e.value.toString()};
                            });
                        return medias.toList();
                      },
                      totalCount: total,
                      onSync: () => r.read(containerListProvider.notifier).syncFavFolders(),
                    )),
                  ));
                  _load();
                  r.read(containerListProvider.notifier).load();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
