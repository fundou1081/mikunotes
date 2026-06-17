import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';

/// ⏰ 稍后观看 Tab
class WatchLaterTab extends ConsumerWidget {
  const WatchLaterTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bili = ref.watch(bilibiliClientProvider);
    final isLoggedIn = bili.isLoggedIn;
    final containersState = ref.watch(containerListProvider);
    final cs = Theme.of(context).colorScheme;

    final watchLater = containersState.maybeWhen(
      data: (list) => list
          .where((c) => c.type == ContainerType.watchLater)
          .cast<ContainerInfo?>()
          .firstWhere((c) => true, orElse: () => null),
      orElse: () => null,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text('稍后观看', style: Theme.of(context).textTheme.titleMedium),
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
              : watchLater == null
                  ? _buildEmpty(context, ref)
                  : _buildLoaded(context, ref, watchLater),
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

  Widget _buildLoaded(
      BuildContext context, WidgetRef ref, ContainerInfo c) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: cs.surfaceContainerHighest,
          child: Row(
            children: [
              const Icon(Icons.watch_later, size: 40, color: Colors.pink),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('稍后观看',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('B 站稍后观看: ${c.totalCount} 个',
                        style: TextStyle(color: cs.outline, fontSize: 12)),
                    Text('已导入: ${c.importedCount}',
                        style: TextStyle(color: cs.outline, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.engineering, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('Phase B 会加导入入口',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 4),
              Text('Phase C 会加下载全部字幕',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const Spacer(),
      ],
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
      messenger.showSnackBar(const SnackBar(content: Text('✓ 同步完成')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('✗ 同步失败: $e')));
    }
  }
}
