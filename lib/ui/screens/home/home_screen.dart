import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 首页 — 视频列表 + 添加视频入口
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MikuNotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: _VideoList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVideoDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('导入视频'),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _SettingsScreen()),
    );
  }

  void _showAddVideoDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入B站视频'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '粘贴 B站链接 / BV号 / b23.tv',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                ref.read(videoListProvider.notifier).addVideo(url);
                Navigator.pop(ctx);
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }
}

class _VideoList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(videoListProvider);

    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library_outlined,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              '还没有视频',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮导入 B站视频',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.play_circle_outline, size: 40),
            title: Text(videos[index], maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: const Text('等待下载...'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 跳转到视频详情页
            },
          ),
        );
      },
    );
  }
}

/// 设置页面 — AI 配置
class _SettingsScreen extends ConsumerStatefulWidget {
  const _SettingsScreen();

  @override
  ConsumerState<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<_SettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aiConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Provider 选择
          Text('AI 服务商', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...LLMProvider.values.map((p) => RadioListTile<LLMProvider>(
                title: Text(p.label),
                subtitle: Text(p.defaultBaseUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                value: p,
                groupValue: config.provider,
                onChanged: (v) {
                  if (v != null) {
                    ref.read(aiConfigProvider.notifier).setProvider(v);
                    _baseUrlController.text = v.defaultBaseUrl;
                    _modelController.text = v.defaultModel;
                  }
                },
                dense: true,
              )),
          const Divider(height: 32),

          // 自定义配置
          Text('自定义配置', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.deepseek.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: '模型名称',
              hintText: 'deepseek-chat',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Temperature: ${config.temperature.toStringAsFixed(1)}'),
              ),
              Expanded(
                child: Slider(
                  value: config.temperature,
                  min: 0,
                  max: 2,
                  divisions: 20,
                  onChanged: (v) {
                    ref.read(aiConfigProvider.notifier).updateConfig(temperature: v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final baseUrl = _baseUrlController.text.trim();
              final apiKey = _apiKeyController.text.trim();
              final model = _modelController.text.trim();
              ref.read(aiConfigProvider.notifier).updateConfig(
                    baseUrl: baseUrl,
                    apiKey: apiKey,
                    model: model,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('配置已保存')),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('保存配置'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final client = ref.read(llmClientProvider);
              final ok = await client.testConnection();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? '✅ 连接成功' : '❌ 连接失败'),
                ),
              );
            },
            icon: const Icon(Icons.wifi_find),
            label: const Text('测试连接'),
          ),
        ],
      ),
    );
  }
}
