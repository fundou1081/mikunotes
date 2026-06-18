import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/video.dart' as model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/ui/screens/containers/containers_home.dart';
import 'package:mikunotes/ui/screens/containers/upmaster_list_page.dart';
import 'package:mikunotes/ui/screens/containers/video_list.dart';

/// 👤 UP 主 Tab - 视频列表 + 顶部 chip 过滤 (全部 / 各 UP主)
class UpMastersTab extends ConsumerStatefulWidget {
  const UpMastersTab({super.key});

  @override
  ConsumerState<UpMastersTab> createState() => _UpMastersTabState();
}

class _UpMastersTabState extends ConsumerState<UpMastersTab> {
  int? _selectedUpMasterId; // null = 全部

  @override
  Widget build(BuildContext context) {
    final upMastersState = ref.watch(upMasterListProvider);

    final upMasters = upMastersState.maybeWhen(
      data: (list) => list,
      orElse: () => <UpMasterInfo>[],
    );
    final totalImported = upMasters.fold<int>(0, (a, b) => a + b.importedCount);

    if (upMastersState.isLoading && upMasters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 顶部操作栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('👤 UP 主',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Text('(关注 ${upMasters.length} / 已入库 $totalImported)',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
                onPressed: () => ref.read(upMasterListProvider.notifier).load(),
              ),
            ],
          ),
        ),
        // 顶部选择器按钮 (点击打开完整列表页)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<int?>(
                context,
                MaterialPageRoute(
                  builder: (_) => UpMasterListPage(selectedId: _selectedUpMasterId),
                ),
              );
              if (result != null || _selectedUpMasterId != null) {
                setState(() => _selectedUpMasterId = result);
              }
            },
            icon: const Icon(Icons.filter_list, size: 18),
            label: Text(_selectedUpMasterLabel(upMasters, totalImported)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const Divider(height: 1),
        // 视频列表
        Expanded(
          child: _selectedUpMasterId == null
              ? const _AllUpMasterList()
              : _UpMasterDetailView(
                  upMasterId: _selectedUpMasterId!,
                ),
        ),
      ],
    );
  }

  String _selectedUpMasterLabel(List<UpMasterInfo> upMasters, int totalImported) {
    if (_selectedUpMasterId == null) {
      return '全部 ($totalImported) · ${upMasters.length} 个 UP 主';
    }
    final um = upMasters.firstWhere(
      (u) => u.id == _selectedUpMasterId,
      orElse: () => UpMasterInfo(
        id: 0, uid: 0, name: '未知', face: '',
        lastVideoAid: null, lastSyncedAt: null,
        containerId: 0, addedAt: DateTime.now(), importedCount: 0,
      ),
    );
    return '${um.name} (${um.importedCount})';
  }
}

/// 单个 UP 主详情视图 (当选择特定 UP主时显示)
class _UpMasterDetailView extends ConsumerStatefulWidget {
  final int upMasterId;
  const _UpMasterDetailView({required this.upMasterId});

  @override
  ConsumerState<_UpMasterDetailView> createState() => _UpMasterDetailViewState();
}

class _UpMasterDetailViewState extends ConsumerState<_UpMasterDetailView> {
  @override
  void initState() {
    super.initState();
    // 进入时自动同步 (背景执行)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ums = ref.read(upMasterListProvider).value;
      if (ums != null) {
        final um = ums.where((u) => u.id == widget.upMasterId).firstOrNull;
        if (um != null) {
          ref.read(upMasterSyncProvider(um.uid).notifier).sync();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final upMasters = ref.watch(upMasterListProvider).value ?? [];
    final um = upMasters.where((u) => u.id == widget.upMasterId).firstOrNull;
    if (um == null) {
      return const Center(child: Text('UP 主不存在'));
    }
    return _UpMasterDetailContent(upMaster: um);
  }
}

class _UpMasterDetailContent extends ConsumerWidget {
  final UpMasterInfo upMaster;
  const _UpMasterDetailContent({required this.upMaster});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(upMasterSyncProvider(upMaster.uid));
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // UP 主信息 + 同步状态
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: cs.surfaceContainerHighest,
          child: Row(
            children: [
              if (upMaster.face.isNotEmpty)
                CircleAvatar(backgroundImage: NetworkImage(upMaster.face), radius: 20)
              else
                const CircleAvatar(radius: 20, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(upMaster.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('已入库 ${upMaster.importedCount} 个',
                        style: TextStyle(fontSize: 12, color: cs.outline)),
                    if (upMaster.lastSyncedAt != null)
                      Text('上次同步: ${_relTime(upMaster.lastSyncedAt!)}',
                          style: TextStyle(fontSize: 11, color: cs.outline)),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: syncState.isLoading
                    ? null
                    : () => ref.read(upMasterSyncProvider(upMaster.uid).notifier).sync(),
                icon: syncState.isLoading
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5))
                    : const Icon(Icons.refresh, size: 16),
                label: const Text('同步', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        // 新发布区域
        syncState.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('同步失败: $e', style: const TextStyle(fontSize: 12, color: Colors.red))),
            ]),
          ),
          data: (result) {
            if (result.newCount == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Icon(Icons.check_circle, color: cs.primary, size: 16),
                  const SizedBox(width: 6),
                  Text('B 站共 ${result.totalFromBili} 个, 暂无新发布',
                      style: TextStyle(fontSize: 12, color: cs.outline)),
                ]),
              );
            }
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.fiber_new, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '${result.newCount} 个新发布',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                )),
                FilledButton.tonalIcon(
                  onPressed: () => _importNew(context, ref, result.newBvids, upMaster.containerId),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('一键导入', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ]),
            );
          },
        ),
        // 已导入视频列表
        Expanded(
          child: VideosInContainerView(containerId: upMaster.containerId),
        ),
      ],
    );
  }

  String _relTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }

  Future<void> _importNew(BuildContext context, WidgetRef ref,
      List<String> bvids, int containerId) async {
    if (bvids.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('一键导入?'),
        content: Text('将导入 ${bvids.length} 个新发布视频。\n\n不会下载字幕。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('导入')),
        ],
      ),
    );
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(videoRepositoryProvider);
    final result = await repo.batchAddToContainer(bvids, containerId);
    if (!context.mounted) return;
    final s = (result['success'] as List).length;
    final f = (result['failed'] as List).length;
    messenger.showSnackBar(SnackBar(
      content: Text('✓ 成功 $s 个, 失败 $f 个'),
      duration: const Duration(seconds: 3),
    ));
    ref.read(upMasterListProvider.notifier).load();
    ref.read(allUpMasterVideosProvider.notifier).load();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

/// "全部" 视图: 跨所有 UP 主容器的视频
class _AllUpMasterList extends ConsumerWidget {
  const _AllUpMasterList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(allUpMasterVideosProvider);
    final db1 = ref.watch(databaseProvider);

    return videosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
      data: (videos) {
        if (videos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('还没有 UP 主视频', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('导入视频时会自动按 UP 主分组',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.read(allUpMasterVideosProvider.notifier).load();
            ref.read(upMasterListProvider.notifier).load();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return VideoListItem(
                video: v,
                database: db1,
                onSubtitleDownloaded: () {
                  ref.read(allUpMasterVideosProvider.notifier).load();
                  ref.read(upMasterListProvider.notifier).load();
                },
                onDeleted: () async {
                  await ref
                      .read(videoListProvider.notifier)
                      .deleteVideo(v.bvid);
                  ref.read(allUpMasterVideosProvider.notifier).load();
                  ref.read(upMasterListProvider.notifier).load();
                },
              );
            },
          ),
        );
      },
    );
  }
}
