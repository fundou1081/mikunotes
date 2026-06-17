import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/providers/providers.dart';

/// 弹出导入视频对话框 (从 HomeShell 等地方复用)
Future<void> showAddVideoDialog(BuildContext context, WidgetRef ref) async {
  if (!ref.read(bilibiliClientProvider).isLoggedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请先登录 B站')),
    );
    return;
  }

  final controller = TextEditingController();
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('导入B站视频'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '粘贴链接 / BV号 / b23.tv',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null && data!.text!.isNotEmpty) {
                  controller.text = data.text!;
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: data.text!.length),
                  );
                }
              },
              icon: const Icon(Icons.paste),
              label: const Text('粘贴剪贴板'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final url = controller.text.trim();
            if (url.isEmpty) return;
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(SnackBar(content: Text('导入中: $url')));
            try {
              await ref.read(videoListProvider.notifier).addVideo(url);
              messenger.showSnackBar(const SnackBar(content: Text('✓ 导入完成')));
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text('✗ 失败: $e')));
            }
          },
          child: const Text('导入'),
        ),
      ],
    ),
  );
}
