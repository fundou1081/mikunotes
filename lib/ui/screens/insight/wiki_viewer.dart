import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 📚 Wiki 浏览 — 列出所有 .md 文件, 点击查看
/// (LLM Wiki 数据通过 Event Bus 自动写入, 这里只读)
class WikiViewer extends ConsumerStatefulWidget {
  const WikiViewer({super.key});

  @override
  ConsumerState<WikiViewer> createState() => _WikiViewerState();
}

class _WikiViewerState extends ConsumerState<WikiViewer> {
  @override
  Widget build(BuildContext context) {
    return _placeholder(
      icon: Icons.description_outlined,
      title: 'Wiki 浏览',
      subtitle: '查看所有视频的 LLM Wiki 记录\n(自动从视频管理同步)',
    );
  }

  Widget _placeholder({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 24),
            Text(
              '开发中 · v0.5.0',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
