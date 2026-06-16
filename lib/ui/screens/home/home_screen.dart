import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/login/login_screen.dart';
import 'package:mikunotes/ui/screens/video_detail/video_detail_screen.dart';

/// 首页 — 视频库 + 导入入口 + 设置
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bili = ref.watch(bilibiliClientProvider);
    final isLoggedIn = bili.isLoggedIn;
    final user = bili.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MikuNotes'),
        actions: [
          if (!isLoggedIn)
            TextButton.icon(
              onPressed: () => _login(context),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('登录'),
            )
          else
            _UserBadge(user: user, onTap: () => _showUserMenu(context, ref)),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: const _VideoList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVideoDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('导入视频'),
      ),
    );
  }

  void _login(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showAddVideoDialog(BuildContext context, WidgetRef ref) {
    if (!ref.read(bilibiliClientProvider).isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录 B站')),
      );
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入B站视频'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '粘贴链接 / BV号 / b23.tv',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLines: 2,
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
              messenger.showSnackBar(
                SnackBar(content: Text('导入中: $url')),
              );
              try {
                await ref.read(videoListProvider.notifier).addVideo(url);
                messenger.showSnackBar(
                  const SnackBar(content: Text('✓ 导入完成')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('✗ 失败: $e')),
                );
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _showUserMenu(BuildContext context, WidgetRef ref) {
    final bili = ref.read(bilibiliClientProvider);
    final user = bili.user;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user != null) ...[
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.face.isNotEmpty ? NetworkImage(user.face) : null,
                  child: user.face.isEmpty
                      ? Text(user.uname.isNotEmpty ? user.uname[0] : '?')
                      : null,
                ),
                title: Text(user.uname, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('UID: ${user.mid} · Lv${user.level}'),
              ),
              const Divider(height: 1),
            ],
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('设置'),
              onTap: () {
                Navigator.pop(ctx);
                _openSettings(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('退出登录', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(bilibiliClientProvider.notifier).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已退出登录')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 用户头像徽章 (AppBar 右侧)
class _UserBadge extends StatelessWidget {
  final BiliUser? user;
  final VoidCallback onTap;

  const _UserBadge({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: (user?.face.isNotEmpty ?? false)
                    ? NetworkImage(user!.face)
                    : null,
                child: (user?.face.isEmpty ?? true)
                    ? Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                user?.uname ?? '已登录',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).appBarTheme.foregroundColor ??
                      Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (user?.isVip ?? false)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.workspace_premium,
                    size: 14,
                    color: Colors.amber.shade700,
                  ),
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoList extends ConsumerWidget {
  const _VideoList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(videoListProvider);

    return videosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
      data: (videos) {
        if (videos.isEmpty) {
          return _EmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(videoListProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoDetailScreen(bvid: v.bvid),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (v.coverUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              v.coverUrl,
                              width: 80,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.video_library, size: 40),
                            ),
                          )
                        else
                          const Icon(Icons.video_library, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${v.uploader} · ${_formatDuration(v.duration)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref
                                .read(videoListProvider.notifier)
                                .deleteVideo(v.bvid);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final mm = m % 60;
      return '$h:$mm:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library_outlined,
                size: 80, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('还没有视频',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '粘贴 B站链接即可导入',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置页 — AI 配置 + 账号
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _customPromptController;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigProvider);
    _baseUrlController = TextEditingController(text: config.effectiveBaseUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _modelController = TextEditingController(text: config.effectiveModel);
    _customPromptController = TextEditingController(text: config.customSystemPrompt);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aiConfigProvider);
    final isLoggedIn = ref.watch(bilibiliClientProvider).isLoggedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 账号 ──────────────────────────────────
          Text('账号', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                isLoggedIn ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isLoggedIn ? Colors.green : Theme.of(context).colorScheme.outline,
              ),
              title: Text(isLoggedIn ? '已登录 B站' : '未登录'),
              trailing: isLoggedIn
                  ? TextButton(
                      onPressed: () async {
                        await ref.read(bilibiliClientProvider.notifier).logout();
                      },
                      child: const Text('退出'),
                    )
                  : FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('登录'),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // ── AI Provider ──────────────────────────
          Text('AI 服务商', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: LLMProvider.values
                  .map((p) => RadioListTile<LLMProvider>(
                        title: Text(p.label),
                        subtitle: Text(
                          '${p.defaultBaseUrl}\n默认模型: ${p.defaultModel}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: p,
                        groupValue: config.provider,
                        onChanged: (v) async {
                          if (v != null) {
                            await ref.read(aiConfigProvider.notifier).setProvider(v);
                            _baseUrlController.text = v.defaultBaseUrl;
                            _modelController.text = v.defaultModel;
                          }
                        },
                        dense: true,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ── 自定义 ──────────────────────────────
          Text('自定义配置', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: '模型名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
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
          const SizedBox(height: 16),
          TextField(
            controller: _customPromptController,
            decoration: const InputDecoration(
              labelText: '自定义 System Prompt (可选)',
              border: OutlineInputBorder(),
              helperText: '留空使用默认 prompt',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref.read(aiConfigProvider.notifier).updateConfig(
                          baseUrl: _baseUrlController.text.trim(),
                          apiKey: _apiKeyController.text.trim(),
                          model: _modelController.text.trim(),
                          customSystemPrompt: _customPromptController.text,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ 配置已保存')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final client = ref.read(llmClientProvider);
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('测试中...')),
                    );
                    final ok = await client.testConnection();
                    messenger.showSnackBar(
                      SnackBar(content: Text(ok ? '✓ 连接成功' : '✗ 连接失败')),
                    );
                  },
                  icon: const Icon(Icons.wifi_find),
                  label: const Text('测试'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
