import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/ui/screens/containers/video_list.dart';

/// 📂 视频 Tab - 只用 tag 过滤, 不需要容器 chip (底部 Tab 已区分)
class ContainersHome extends ConsumerStatefulWidget {
  const ContainersHome({super.key});

  @override
  ConsumerState<ContainersHome> createState() => _ContainersHomeState();
}

class _ContainersHomeState extends ConsumerState<ContainersHome> {
  Set<String> _tagFilter = {};

  @override
  Widget build(BuildContext context) {
    final videosState = ref.watch(videoListProvider);
    final db1 = ref.watch(databaseProvider);

    return videosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
      data: (videos) {
        final allTags = <String>{};
        for (final v in videos) {
          allTags.addAll(v.allTags);
        }
        final tagList = allTags.toList()..sort();
        final filtered = _tagFilter.isEmpty
            ? videos
            : videos.where((v) => v.allTags.any((t) => _tagFilter.contains(t))).toList();

        return Column(
          children: [
            if (tagList.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    FilterChip(
                      label: const Text('全部', style: TextStyle(fontSize: 12)),
                      selected: _tagFilter.isEmpty,
                      onSelected: (_) => setState(() => _tagFilter = {}),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    ...tagList.map((t) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: FilterChip(
                            label: Text(t, style: const TextStyle(fontSize: 12)),
                            selected: _tagFilter.contains(t),
                            onSelected: (sel) => setState(() {
                              if (sel) {
                                _tagFilter.add(t);
                              } else {
                                _tagFilter.remove(t);
                              }
                            }),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )),
                  ],
                ),
              ),
            if (tagList.isNotEmpty) const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('没有匹配的视频', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(videoListProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final v = filtered[index];
                          return VideoListItem(
                            video: v,
                            database: db1,
                            onSubtitleDownloaded: () => ref.read(videoListProvider.notifier).load(),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// 容器内视频视图 (FavoritesTab / WatchLaterTab 复用)
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('该容器暂无视频', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(videosInContainerProvider(containerId).notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return VideoListItem(video: v, database: db1, onSubtitleDownloaded: () {
                ref.read(videosInContainerProvider(containerId).notifier).load();
                ref.read(containerListProvider.notifier).load();
              }, onDeleted: () async {
                await ref.read(videoListProvider.notifier).deleteVideo(v.bvid);
                ref.read(videosInContainerProvider(containerId).notifier).load();
                ref.read(containerListProvider.notifier).load();
              }, onRemoved: () async {
                final dbLocal = ref.read(databaseProvider);
                await dbLocal.removeVideoFromContainer(containerId, v.bvid);
                ref.read(videosInContainerProvider(containerId).notifier).load();
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
