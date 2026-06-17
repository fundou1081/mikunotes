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

/// 全部视频视图 + tag 过滤 chips
class _AllVideosView extends ConsumerStatefulWidget {
  const _AllVideosView();

  @override
  ConsumerState<_AllVideosView> createState() => _AllVideosViewState();
}

class _AllVideosViewState extends ConsumerState<_AllVideosView> {
  Set<String> _tagFilter = {};

  @override
  Widget build(BuildContext context) {
    final videosState = ref.watch(videoListProvider);
    final db1 = ref.watch(databaseProvider);

    return videosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
      data: (videos) {
        // 收集所有唯一 tag
        final allTags = <String>{};
        for (final v in videos) {
          allTags.addAll(v.allTags);
        }
        final tagList = allTags.toList()..sort();

        // 过滤视频
        final filtered = _tagFilter.isEmpty
            ? videos
            : videos.where((v) => v.allTags.any((t) => _tagFilter.contains(t))).toList();

        return Column(
          children: [
            // Tag 过滤 chips
            if (tagList.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    _tagChip(
                        label: '全部 ${videos.length}',
                        selected: _tagFilter.isEmpty,
                        onSelected: (_) => setState(() => _tagFilter = {})),
                    ...tagList.map((t) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: _tagChip(
                            label: t,
                            selected: _tagFilter.contains(t),
                            onSelected: (sel) => setState(() {
                              if (sel) {
                                _tagFilter.add(t);
                              } else {
                                _tagFilter.remove(t);
                              }
                            }),
                          ),
                        )),
                  ],
                ),
              ),
            if (tagList.isNotEmpty) const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('没有匹配的视频',
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(videoListProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final v = filtered[index];
                          return VideoListItem(
                            video: v,
                            database: db1,
                            onSubtitleDownloaded: () => ref
                                .read(videoListProvider.notifier)
                                .load(),
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

  Widget _tagChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
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
