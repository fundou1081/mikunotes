import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 📊 图可视化 — 视频/标签/UP主 关联图
/// v0.5.4: 占位, 待开发
class GraphVisualization extends ConsumerWidget {
    const GraphVisualization({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.account_tree,
                            size: 80, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('图可视化', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                            '视频 ↔ 标签 ↔ UP主 关联图\n'
                            '基于 Wiki 数据自动生成',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                            ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text('计划功能:',
                                            style: Theme.of(context).textTheme.titleSmall),
                                        const SizedBox(height: 8),
                                        const Text('• 节点: 视频/标签/UP主'),
                                        const Text('• 边: 共同标签/同 UP 主'),
                                        const Text('• 交互: 点击节点跳转到对应 Wiki'),
                                        const Text('• 筛选: 按 tag / UP 主 / 时间'),
                                    ],
                                ),
                            ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                                '🚧 待开发 · v0.6.0',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
