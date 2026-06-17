import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/ui/screens/containers/video_list.dart';

/// 📂 视频 Tab - 手动导入 + 所有容器混合视图
class ContainersHome extends ConsumerStatefulWidget {
  const ContainersHome({super.key});

  @override
  ConsumerState<ContainersHome> createState() => _ContainersHomeState();
}

class _ContainersHomeState extends ConsumerState<ContainersHome> {
  int? _filterContainerId; // null = 全部

  @override
  Widget build(BuildContext context) {
    final containersState = ref.watch(containerListProvider);

    return Column(
      children: [
        // 顶部过滤器 (chips)
        SizedBox(
          height: 56,
          child: containersState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (containers) {
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _filterChip(label: '全部', value: null),
                  ...containers.map((c) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _filterChip(
                          label: '${c.name} (${c.importedCount})',
                          value: c.id,
                        ),
                      )),
                ],
              );
            },
          ),
        ),
        const Divider(height: 1),
        // 视频列表
        Expanded(
          child: _filterContainerId == null
              ? const _AllVideosView()
              : VideosInContainerView(containerId: _filterContainerId!),
        ),
      ],
    );
  }

  Widget _filterChip({required String label, required int? value}) {
    final selected = _filterContainerId == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filterContainerId = value),
    );
  }
}

/// 全部视频视图 (用现有的 VideoList 组件)
class _AllVideosView extends ConsumerWidget {
  const _AllVideosView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const VideoList();
  }
}

/// 容器内视频视图
class VideosInContainerView extends ConsumerWidget {
  final int containerId;
  const VideosInContainerView({super.key, required this.containerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(videosInContainerProvider(containerId));
    final db1 = ref.watch(databaseProvider);

    return videosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
      data: (videos) {
        if (videos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('该容器暂无视频', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(videosInContainerProvider(containerId).notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return VideoListItem(video: v, database: db1, onSubtitleDownloaded: () {
                ref
                    .read(videosInContainerProvider(containerId).notifier)
                    .load();
                ref.read(containerListProvider.notifier).load();
              }, onDeleted: () async {
                // 物理删除: 同时刷新该容器 + 容器列表 (chip 数字)
                await ref
                    .read(videoListProvider.notifier)
                    .deleteVideo(v.bvid);
                ref
                    .read(videosInContainerProvider(containerId).notifier)
                    .load();
                ref.read(containerListProvider.notifier).load();
              }, onRemoved: () async {
                // 移出此容器: 刷新该容器 + 容器列表
                final db1Local = ref.read(databaseProvider);
                await db1Local.removeVideoFromContainer(containerId, v.bvid);
                ref
                    .read(videosInContainerProvider(containerId).notifier)
                    .load();
                ref.read(containerListProvider.notifier).load();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ 已移出此收藏夹')),
                  );
                }
              });
            },
          ),
        );
      },
    );
  }
}
