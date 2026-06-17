import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/bilibili/bilibili_client.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;
import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/models/video.dart' as model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/storage/backup_service.dart';
import 'package:mikunotes/core/storage/database.dart';
import 'package:mikunotes/ui/screens/login/login_screen.dart';
import 'package:mikunotes/ui/screens/video_detail/video_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

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
    final db = ref.watch(databaseProvider);

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
              return _VideoCard(
                video: v,
                db: db,
                onSubtitleDownloaded: () {
                  ref.read(videoListProvider.notifier).load();
                },
              );
            },
          ),
        );
      },
    );
  }

  // _formatDuration 移到底部为全局函数

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
  bool _fetchingModels = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigProvider);
    _baseUrlController = TextEditingController(text: config.effectiveBaseUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _modelController = TextEditingController(text: config.effectiveModel);
    _customPromptController = TextEditingController(text: config.customSystemPrompt);
  }

  /// 从当前 endpoint 拉取可用模型列表
  Future<void> _fetchModels() async {
    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    if (baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写 Base URL')),
      );
      return;
    }
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写 API Key')),
      );
      return;
    }
    setState(() => _fetchingModels = true);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
        validateStatus: (s) => s != null && s < 500,
      ));

      // 尝试多个常见路径
      const paths = ['/models', '/v1/models', '/api/v1/models'];
      List<String> models = [];
      String? lastError;
      for (final path in paths) {
        try {
          final response = await dio.get(path);
          if (response.statusCode == 200 && response.data is Map) {
            final data = response.data;
            if (data['data'] is List) {
              for (final m in data['data']) {
                if (m is Map && m['id'] is String) {
                  models.add(m['id'] as String);
                }
              }
              if (models.isNotEmpty) break;
            }
          } else if (response.statusCode != 404) {
            // 401/403/etc 是认证问题，不是路径问题
            lastError = 'HTTP ${response.statusCode}';
            if (response.statusCode == 401 || response.statusCode == 403) {
              break; // 别试其他路径
            }
          }
        } on DioException catch (e) {
          lastError = e.response?.statusCode?.toString() ?? e.message;
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) break;
        }
      }
      if (models.isEmpty) {
        throw Exception(lastError ?? '未找到模型列表 (检查 baseUrl 是否正确)');
      }
      models.sort();
      if (!mounted) return;
      await _showModelPicker(models);
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      String msg;
      if (code == 401) {
        msg = '拉取失败 401: API Key 无效或格式错误';
      } else if (code == 403) {
        msg = '拉取失败 403: 权限不足或 Key 被拒绝';
      } else if (code == 404) {
        msg = '拉取失败 404: 路径不存在，请检查 Base URL';
      } else {
        msg = '拉取失败 ${code ?? ""}: ${e.message ?? ""}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拉取失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  /// 模型选择器
  Future<void> _showModelPicker(List<String> models) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.list),
                      const SizedBox(width: 8),
                      Text('可用模型 (${models.length})',
                          style: Theme.of(ctx).textTheme.titleMedium),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: models.length,
                    itemBuilder: (ctx, i) {
                      final m = models[i];
                      final isCurrent = m == _modelController.text.trim();
                      return ListTile(
                        leading: isCurrent
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.circle_outlined),
                        title: Text(m),
                        subtitle: isCurrent ? const Text('当前选择') : null,
                        onTap: () => Navigator.pop(ctx, m),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _modelController.text = selected);
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  void _showTemplateEditor(
    BuildContext context, {
    required String title,
    required String initial,
    required String defaultTemplate,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(
      text: initial.isEmpty ? defaultTemplate : initial,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('可用变量:',
                  style: Theme.of(ctx).textTheme.labelSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: llm_tpl.PromptTemplate.availableVariables.entries
                    .map((e) => ActionChip(
                          label: Text('{{${e.key}}}',
                              style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            final cursorPos = controller.selection.base.offset;
                            final newText = controller.text.substring(0, cursorPos) +
                                '{{${e.key}}}' +
                                controller.text.substring(cursorPos);
                            controller.text = newText;
                            controller.selection = TextSelection.collapsed(
                              offset: (cursorPos + e.key.length + 4).clamp(0, newText.length),
                            );
                          },
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '输入模板...',
                  ),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  controller.text = defaultTemplate;
                },
                child: const Text('恢复默认'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSave(controller.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ 模板已保存')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestoreDialog(BuildContext context, BackupService backupService) async {
    final backups = await BackupService.listBackups();
    if (!mounted) return;
    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloads/MikuNotes/ 下没有备份文件')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择备份文件恢复'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: backups.length,
            itemBuilder: (_, i) {
              final name = backups[i].split('/').last;
              return ListTile(
                title: Text(name, style: const TextStyle(fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('恢复中…')),
                  );
                  final result = await backupService.restoreFrom(backups[i]);
                  if (!context.mounted) return;
                  if (result.success) {
                    final stats = result.stats?.entries.map((e) => '${e.key}: ${e.value}').join(', ') ?? '';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✓ 恢复完成: $stats')),
                    );
                    ref.read(videoListProvider.notifier).load();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✗ 恢复失败: ${result.error}')),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aiConfigProvider);
    final isLoggedIn = ref.watch(bilibiliClientProvider).isLoggedIn;
    final backupService = ref.read(backupServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 数据管理 ──────────────────────────────
          Text('数据管理', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('导出所有数据'),
                  subtitle: const Text('备份到外部存储 MikuNotes_backups/，重装后可恢复'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(const SnackBar(content: Text('导出中…')));
                    try {
                      final path = await backupService.exportAll();
                      messenger.showSnackBar(
                        SnackBar(content: Text('✓ 已导出到: $path')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('✗ 导出失败: $e')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('从备份恢复'),
                  subtitle: const Text('从外部存储 MikuNotes_backups/ 恢复'),
                  onTap: () => _showRestoreDialog(context, backupService),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('查看备份目录'),
                  subtitle: const Text('查看外部存储 MikuNotes_backups/'),
                  onTap: () async {
                    final backups = await BackupService.listBackups();
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('备份文件'),
                        content: backups.isEmpty
                            ? const Text('暂无备份')
                            : SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: backups.length,
                                  itemBuilder: (_, i) {
                                    final name = backups[i].split('/').last;
                                    return ListTile(
                                      dense: true,
                                      title: Text(name, style: const TextStyle(fontSize: 13)),
                                    );
                                  },
                                ),
                              ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: '模型名称',
                    border: OutlineInputBorder(),
                    helperText: '点右侧按钮可拉取可用模型',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: FilledButton.tonalIcon(
                  onPressed: _fetchingModels ? null : _fetchModels,
                  icon: _fetchingModels
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('拉取'),
                ),
              ),
            ],
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
          const SizedBox(height: 16),
          // ── Prompt 模板 ──────────────────────────
          Text('Prompt 模板', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('可保存多套模板。点生成前选哪一套。变量：{{video_title}} {{bvid}} {{subtitle}} {{subtitle_truncated}} {{language}} {{uploader}} {{duration}} {{page_count}}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          _TemplatesSection(),
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
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('测试中...')),
                    );
                    final client = ref.read(llmClientProvider);
                    final config = ref.read(aiConfigProvider);
                    final result = await client.testConnection();
                    messenger.hideCurrentSnackBar();
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('连接测试'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${config.provider.label}\n${config.effectiveModel}',
                                style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 8),
                            Text(result),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
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

/// Prompt 模板管理区 — Tab 切换摘要/对话
class _TemplatesSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TemplatesSection> createState() => _TemplatesSectionState();
}

class _TemplatesSectionState extends ConsumerState<_TemplatesSection>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(icon: Icon(Icons.summarize), text: '摘要模板'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: '对话模板'),
            ],
          ),
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tab,
              children: [
                _TemplateList(type: TemplateType.summary),
                _TemplateList(type: TemplateType.chat),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 模板列表（摘要或对话）
class _TemplateList extends ConsumerWidget {
  final TemplateType type;
  const _TemplateList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    final list = type == TemplateType.summary ? templates.summaries : templates.chats;
    final activeId = type == TemplateType.summary ? templates.activeSummaryId : templates.activeChatId;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final t = list[i];
              final isActive = t.id == activeId;
              return ListTile(
                dense: true,
                leading: IconButton(
                  icon: Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isActive ? Colors.green : null,
                  ),
                  tooltip: isActive ? '当前使用中' : '设为默认',
                  onPressed: () async {
                    await ref.read(templatesProvider.notifier).setActive(type, t.id);
                  },
                ),
                title: Text(t.name),
                subtitle: Text(
                  t.content.replaceAll('\n', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: t.isBuiltIn
                    ? const Chip(label: Text('内置'), visualDensity: VisualDensity.compact)
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref.read(templatesProvider.notifier).deleteTemplate(type, t.id);
                        },
                      ),
                onTap: () => _editTemplate(ctx, ref, t),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: OutlinedButton.icon(
              onPressed: () => _editTemplate(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('新建模板'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editTemplate(BuildContext context, WidgetRef ref, PromptTemplate? t) async {
    final nameCtrl = TextEditingController(text: t?.name ?? '');
    final contentCtrl = TextEditingController(text: t?.content ?? '');
    final isNew = t == null;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isNew ? '新建模板' : '编辑模板 ${t.isBuiltIn ? "(内置)" : ""}'),
          // 用 SingleChildScrollView 包裹防止溢出
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 12,
                    minLines: 8,
                    decoration: const InputDecoration(
                      labelText: '模板内容 (可用变量见下方)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: llm_tpl.PromptTemplate.availableVariables.entries.map((e) {
                      return ActionChip(
                        label: Text('{{${e.key}}}'),
                      onPressed: () {
                        final pos = contentCtrl.selection.baseOffset;
                        final text = contentCtrl.text;
                        final insert = '{{${e.key}}}';
                        contentCtrl.text = text.substring(0, pos.clamp(0, text.length)) +
                            insert + text.substring(pos.clamp(0, text.length));
                        contentCtrl.selection = TextSelection.collapsed(
                            offset: pos.clamp(0, text.length) + insert.length);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final content = contentCtrl.text;
                if (name.isEmpty || content.isEmpty) return;
                final notifier = ref.read(templatesProvider.notifier);
                if (isNew) {
                  await notifier.addTemplate(type, name, content);
                } else if (!t.isBuiltIn) {
                  await notifier.updateTemplate(type, t.id, name: name, content: content);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isNew ? '添加' : '保存'),
            ),
          ],
        );
      },
    );
  }
}

/// 视频卡片 — 带字幕状态徽章和操作菜单
class _VideoCard extends ConsumerStatefulWidget {
  final model.Video video;
  final AppDatabase db;
  final VoidCallback onSubtitleDownloaded;

  const _VideoCard({
    required this.video,
    required this.db,
    required this.onSubtitleDownloaded,
  });

  @override
  ConsumerState<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<_VideoCard> {
  bool _downloading = false;
  bool _hasSubtitle = false;

  @override
  void initState() {
    super.initState();
    _checkSubtitle();
  }

  Future<void> _checkSubtitle() async {
    final subs = await widget.db.getSubtitlesForVideo(widget.video.bvid);
    if (mounted) setState(() => _hasSubtitle = subs.isNotEmpty);
  }

  Future<void> _downloadSubtitle() async {
    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(videoRepositoryProvider);
      final sub = await repo.downloadAndStoreSubtitle(widget.video.bvid);
      messenger.showSnackBar(
        SnackBar(content: Text('✓ 字幕下载成功: ${sub?.entries.length ?? 0} 条')),
      );
      await _checkSubtitle();
      widget.onSubtitleDownloaded();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('✗ 下载失败: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('打开视频详情'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoDetailScreen(bvid: widget.video.bvid),
                  ),
                );
              },
            ),
            ListTile(
              leading: _downloading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_hasSubtitle ? Icons.refresh : Icons.download),
              title: Text(_hasSubtitle ? '重下字幕' : '下载字幕'),
              subtitle: _hasSubtitle ? const Text('已下载，可重新获取') : null,
              onTap: _downloading
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _downloadSubtitle();
                    },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(videoListProvider.notifier)
                    .deleteVideo(widget.video.bvid);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
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
        onLongPress: _showActionMenu,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${v.uploader} · ${_formatDuration(v.duration)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 字幕状态徽章
                        if (_downloading)
                          const SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        else
                          Icon(
                            _hasSubtitle
                                ? Icons.subtitles
                                : Icons.subtitles_outlined,
                            size: 14,
                            color: _hasSubtitle
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          _hasSubtitle ? '已下载' : '无字幕',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _hasSubtitle
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showActionMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
