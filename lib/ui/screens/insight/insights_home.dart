import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 💡 洞察首页 — 进入洞察模式的第一个 tab
class InsightsHome extends ConsumerStatefulWidget {
  const InsightsHome({super.key});

  @override
  ConsumerState<InsightsHome> createState() => _InsightsHomeState();
}

class _InsightsHomeState extends ConsumerState<InsightsHome> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部: 欢迎卡片
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lightbulb,
                        color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      '洞察模式',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    '基于你视频库的 LLM Wiki 系统。\n'
                    '所有视频的总结、对话、标签已自动存储为 .md 文件。',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3 个入口
          _EntryCard(
            icon: Icons.description,
            title: '浏览 Wiki',
            subtitle: '查看所有视频的 LLM Wiki 记录',
            onTap: () {
              // 切换到 Wiki tab (index 1)
            },
          ),
          const SizedBox(height: 8),
          _EntryCard(
            icon: Icons.chat,
            title: '多轮对话',
            subtitle: '基于 Wiki 的智能对话',
            onTap: () {
              // 切换到 Chat tab (index 2)
            },
          ),
          const SizedBox(height: 8),
          _EntryCard(
            icon: Icons.compare_arrows,
            title: '跨视频洞察',
            subtitle: '多视频对比, 发现隐藏关联 (开发中)',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('跨视频洞察将在 v0.7.0 上线')),
              );
            },
            disabled: true,
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool disabled;

  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32,
            color: disabled ? Theme.of(context).colorScheme.outline : null),
        title: Text(title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: disabled ? Theme.of(context).colorScheme.outline : null,
            )),
        subtitle: Text(subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            )),
        trailing: disabled
            ? Chip(
                label: const Text('开发中', style: TextStyle(fontSize: 10)),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                visualDensity: VisualDensity.compact,
              )
            : const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: disabled ? null : onTap,
      ),
    );
  }
}
