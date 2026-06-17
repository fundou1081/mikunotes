import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/video.dart' as model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/ui/screens/containers/containers_home.dart';
import 'package:mikunotes/ui/screens/containers/video_list.dart';

/// ⭐ 收藏夹 Tab - 视频列表 + 顶部 chip 过滤 (全部/各收藏夹)
class FavoritesTab extends ConsumerStatefulWidget {
  const FavoritesTab({super.key});

  @override
  ConsumerState<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends ConsumerState<FavoritesTab> {
  int? _selectedFolderId; // null = 全部

  @override
  Widget build(BuildContext context) {
    final bili = ref.watch(bilibiliClientProvider);
    final isLoggedIn = bili.isLoggedIn;
    final containersState = ref.watch(containerListProvider);

    final favoriteFolders = containersState.maybeWhen(
      data: (list) =>
          list.where((c) => c.type == ContainerType.favorite).toList(),
      orElse: () => <ContainerInfo>[],
    );

    return Column(
      children: [
        // 顶部操作栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('⭐ 收藏夹',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '从 B 站同步',
                  onPressed: () => _sync(context, ref),
                ),
            ],
          ),
        ),
        // 顶部 chip 过滤
        if (isLoggedIn)
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildChip(
                  context,
                  label: '全部 ${_allImported(favoriteFolders)}',
                  value: null,
                ),
                ...favoriteFolders.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildChip(
                      context,
                      label:
                          '${c.name} (${c.importedCount}/${c.totalCount})',
                      value: c.id,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        // 视频列表
        Expanded(
          child: !isLoggedIn
              ? _buildNotLoggedIn(context)
              : _selectedFolderId == null
                  ? _AllFavoriteList(onRefresh: () {
                      ref
                          .read(allFavoriteVideosProvider.notifier)
                          .load();
                      ref.read(containerListProvider.notifier).load();
                    })
                  : VideosInContainerView(containerId: _selectedFolderId!),
        ),
      ],
    );
  }

  String _allImported(List<ContainerInfo> folders) {
    if (folders.isEmpty) return '0';
    // 总去重后的视频数
    return folders
        .map((c) => c.importedCount)
        .fold<int>(0, (a, b) => a + b)
        .toString();
  }

  Widget _buildChip(BuildContext context,
      {required String label, required int? value}) {
    final selected = _selectedFolderId == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedFolderId = value),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('请先登录 B 站',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('登录后可查看你的收藏夹',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('正在同步收藏夹...'),
          duration: Duration(seconds: 1),
        ),
      );
      await ref.read(containerListProvider.notifier).syncFavFolders();
      ref.read(allFavoriteVideosProvider.notifier).load();
      messenger.showSnackBar(const SnackBar(content: Text('✓ 同步完成')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('✗ 同步失败: $e')));
    }
  }
}

/// "全部" 视图: 跨所有收藏夹容器的视频
class _AllFavoriteList extends ConsumerWidget {
  final VoidCallback? onRefresh;
  const _AllFavoriteList({this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(allFavoriteVideosProvider);
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
                  const Text('还没有收藏夹视频', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('点 ↻ 同步 B 站收藏夹, 然后用 FAB 导入',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh?.call(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return VideoListItem(
                video: v,
                database: db1,
                onSubtitleDownloaded: () {
                  ref.read(allFavoriteVideosProvider.notifier).load();
                  ref.read(containerListProvider.notifier).load();
                },
                onDeleted: () async {
                  // 跨容器删除: 从 videos 表物理删除 (同时清所有容器)
                  await ref
                      .read(videoListProvider.notifier)
                      .deleteVideo(v.bvid);
                  ref.read(allFavoriteVideosProvider.notifier).load();
                  ref.read(containerListProvider.notifier).load();
                },
              );
            },
          ),
        );
      },
    );
  }
}
