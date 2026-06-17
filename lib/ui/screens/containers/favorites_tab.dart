import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/containers/favorite_folder_screen.dart';

/// ⭐ 收藏夹 Tab
class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containersState = ref.watch(containerListProvider);
    final bili = ref.watch(bilibiliClientProvider);
    final isLoggedIn = bili.isLoggedIn;

    return Column(
      children: [
        // 顶部操作栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text('我的收藏夹',
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
        const Divider(height: 1),
        Expanded(
          child: !isLoggedIn
              ? _buildNotLoggedIn(context)
              : containersState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('加载失败: $e'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _sync(context, ref),
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试同步'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (containers) {
                    final favs = containers
                        .where((c) => c.type == ContainerType.favorite)
                        .toList();
                    if (favs.isEmpty) {
                      return _buildEmpty(context, ref);
                    }
                    return RefreshIndicator(
                      onRefresh: () => _sync(context, ref),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: favs.length,
                        itemBuilder: (context, index) {
                          final c = favs[index];
                          return _FavFolderTile(container: c);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
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

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('还没有收藏夹数据',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('点 ↻ 按钮从 B 站同步',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _sync(context, ref),
              icon: const Icon(Icons.refresh),
              label: const Text('同步 B 站收藏夹'),
            ),
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
      messenger.showSnackBar(
        const SnackBar(content: Text('✓ 同步完成')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('✗ 同步失败: $e')),
      );
    }
  }
}

class _FavFolderTile extends StatelessWidget {
  final ContainerInfo container;
  const _FavFolderTile({required this.container});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.folder, color: cs.onPrimaryContainer),
      ),
      title: Text(container.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Text(
            '已导入 ${container.importedCount} / ${container.totalCount}',
            style: TextStyle(
              color: cs.outline,
              fontSize: 12,
            ),
          ),
          if (container.totalCount > 0) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: container.progress,
                  minHeight: 4,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FavoriteFolderScreen(
              containerId: container.id,
              containerName: container.name,
              totalCount: container.totalCount,
            ),
          ),
        );
      },
    );
  }
}
