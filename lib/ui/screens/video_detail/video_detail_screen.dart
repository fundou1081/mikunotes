import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 视频详情页 — 摘要 / 对话 / 字幕 三 Tab
class VideoDetailScreen extends ConsumerWidget {
  final String bvid;

  const VideoDetailScreen({super.key, required this.bvid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(bvid),
          bottom: const TabBar(tabs: [
            Tab(text: '摘要', icon: Icon(Icons.summarize)),
            Tab(text: '对话', icon: Icon(Icons.chat_bubble_outline)),
            Tab(text: '字幕', icon: Icon(Icons.subtitles)),
          ]),
        ),
        body: TabBarView(children: [
          _SummaryTab(bvid: bvid),
          _ChatTab(bvid: bvid),
          _SubtitleTab(bvid: bvid),
        ]),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final String bvid;
  const _SummaryTab({required this.bvid});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📝 点击生成总结'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              // TODO: 调用 LLM 总结
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI 总结'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: 主题展开
            },
            icon: const Icon(Icons.open_in_full),
            label: const Text('展开主题'),
          ),
        ],
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  final String bvid;
  const _ChatTab({required this.bvid});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('💬 对话功能开发中'));
  }
}

class _SubtitleTab extends StatelessWidget {
  final String bvid;
  const _SubtitleTab({required this.bvid});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('📄 字幕预览开发中'));
  }
}
