import 'package:flutter/material.dart';

/// 聚类图页面 (Phase 3)
class ClusterScreen extends StatelessWidget {
  const ClusterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('内容聚类')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hub_outlined,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('内容聚类图',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('多视频知识图谱 — Phase 3',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
