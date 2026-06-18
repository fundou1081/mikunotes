import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/containers/containers_home.dart';
import 'package:mikunotes/ui/screens/containers/video_list.dart';

/// ⏰ 稍后观看 Tab - 视频列表 (无需 chip, 只有一个容器)
class WatchLaterTab extends ConsumerStatefulWidget {
  const WatchLaterTab({super.key});

  @override
  ConsumerState<WatchLaterTab> createState() => _WatchLaterTabState();
}

class _WatchLaterTabState extends ConsumerState<WatchLaterTab> {
  int? _containerId; // 实际 watch_later 容器 ID

  @override
  void initState() {
    super.initState();
    _loadContainer();
  }

  Future<void> _loadContainer() async {
    final db = ref.read(databaseProvider);
    final c = await (db.select(db.containers)
          ..where((c) => c.type.equals('watch_later')))
        .getSingleOrNull();
    if (c != null && mounted && c.id != _containerId) {
      setState(() => _containerId = c.id);
    } else if (c != null && mounted) {
      // 容器没变, 仍重新加载 videos
      ref.read(videosInContainerProvider(c.id).notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听容器列表变化, 同步重加载 videosInContainer
    ref.listen<AsyncValue<List<ContainerInfo>>>(containerListProvider, (prev, next) {
      if (_containerId != null) {
        ref.read(videosInContainerProvider(_containerId!).notifier).load();
      } else {
        _loadContainer();
      }
    });

    final bili = ref.watch(bilibiliClientProvider);
    final isLoggedIn = bili.isLoggedIn;
    final containersState = ref.watch(containerListProvider);

    final watchLater = containersState.maybeWhen(
      data: (list) => list
          .where((c) => c.type == ContainerType.watchLater)
          .cast<ContainerInfo?>()
          .firstWhere((c) => true, orElse: () => null),
      orElse: () => null,
    );

    return Column(
      children: [
        // 顶部操作栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('⏰ 稍后观看',
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
        // 顶部统计
        if (watchLater != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Text('B 站稍后观看 ${watchLater.totalCount}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                Text('已导入 ${watchLater.importedCount}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: !isLoggedIn
              ? _buildNotLoggedIn(context)
              : _containerId == null
                  ? _buildEmpty(context, ref)
                  : VideosInContainerView(containerId: _containerId!),
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
            const Icon(Icons.watch_later_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('请先登录 B 站',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            const Icon(Icons.watch_later_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('还没有稍后观看数据',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('点 ↻ 按钮从 B 站同步',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _sync(context, ref),
              icon: const Icon(Icons.refresh),
              label: const Text('同步 B 站稍后观看'),
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
          content: Text('正在同步稍后观看...'),
          duration: Duration(seconds: 1),
        ),
      );
      await ref.read(containerListProvider.notifier).syncWatchLater();
      await _loadContainer();
      messenger.showSnackBar(const SnackBar(content: Text('✓ 同步完成')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('✗ 同步失败: $e')));
    }
  }
}
