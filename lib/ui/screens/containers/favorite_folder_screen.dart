import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/ui/screens/containers/video_list.dart';

/// 进入某个收藏夹文件夹 — 显示已导入的视频
class FavoriteFolderScreen extends ConsumerWidget {
  final int containerId;
  final String containerName;
  final int totalCount;

  const FavoriteFolderScreen({
    super.key,
    required this.containerId,
    required this.containerName,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(videosInContainerProvider(containerId));
    final containers = ref.watch(containerListProvider);
    final db1 = ref.watch(databaseProvider);

    final currentContainer = containers.maybeWhen(
      data: (list) => list.firstWhere(
        (c) => c.id == containerId,
        orElse: () => ContainerInfo(
          id: containerId,
          type: ContainerType.favorite,
          externalId: null,
          name: containerName,
          totalCount: totalCount,
          importedCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      orElse: () => ContainerInfo(
        id: containerId,
        type: ContainerType.favorite,
        externalId: null,
        name: containerName,
        totalCount: totalCount,
        importedCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(containerName),
        actions: [
          // 顶部"下载全部字幕"按钮 (Phase C 加)
          // 现在先留空
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'remove_all') {
                await _removeAll(context, ref);
              }
            },
            itemBuilder: (c) => [
              const PopupMenuItem(
                value: 'remove_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('移出此收藏夹所有视频',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: videosState.when(
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
                    const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('已导入 0 / $totalCount', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('Phase B 会加导入入口',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              // 顶部统计
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Text(
                      '已导入 ${videos.length} / $totalCount',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalCount == 0 ? 0 : videos.length / totalCount,
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(videosInContainerProvider(containerId).notifier)
                      .load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final v = videos[index];
                      return VideoListItem(
                        video: v,
                        database: db1,
                        onSubtitleDownloaded: () => ref
                            .read(videosInContainerProvider(containerId)
                                .notifier)
                            .load(),
                        onRemoved: () => _removeFromContainer(
                            context, ref, v.bvid),
                        onDeleted: () => _deleteVideo(context, ref, v.bvid),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _removeFromContainer(
      BuildContext context, WidgetRef ref, String bvid) async {
    final db1 = ref.read(databaseProvider);
    final messenger = ScaffoldMessenger.of(context);
    await db1.removeVideoFromContainer(containerId, bvid);
    ref.read(videosInContainerProvider(containerId).notifier).load();
    ref.read(containerListProvider.notifier).load();
    messenger.showSnackBar(const SnackBar(content: Text('✓ 已移出此收藏夹')));
  }

  Future<void> _deleteVideo(
      BuildContext context, WidgetRef ref, String bvid) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('彻底删除?'),
        content: const Text('将从所有容器中删除,并删除其总结/字幕/对话。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(videoListProvider.notifier).deleteVideo(bvid);
    ref.read(videosInContainerProvider(containerId).notifier).load();
    ref.read(containerListProvider.notifier).load();
    messenger.showSnackBar(const SnackBar(content: Text('✓ 已删除')));
  }

  Future<void> _removeAll(BuildContext context, WidgetRef ref) async {
    final db1 = ref.read(databaseProvider);
    final bvids = await db1.getBvidsInContainer(containerId);
    if (bvids.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('该收藏夹无视频')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('移出所有视频?'),
        content: Text('将从此收藏夹移除 ${bvids.length} 个视频 (不会删除视频本身)。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('移出'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final bvid in bvids) {
      await db1.removeVideoFromContainer(containerId, bvid);
    }
    ref.read(videosInContainerProvider(containerId).notifier).load();
    ref.read(containerListProvider.notifier).load();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('✓ 已移出 ${bvids.length} 个视频')));
    }
  }
}
