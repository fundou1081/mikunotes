import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 💬 多轮对话 — LLM Wiki 功能的 chat 入口
/// (这次只是简单 chat, 之后可加 "读取 wiki 文件作为 context" 功能)
class WikiChat extends ConsumerStatefulWidget {
  const WikiChat({super.key});

  @override
  ConsumerState<WikiChat> createState() => _WikiChatState();
}

class _WikiChatState extends ConsumerState<WikiChat> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('多轮对话', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '基于 LLM Wiki 的多轮对话\n(之后可让 LLM 读取 wiki 文件作为 context)',
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
