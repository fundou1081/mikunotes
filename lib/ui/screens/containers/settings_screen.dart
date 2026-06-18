import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:share_plus/share_plus.dart";
import "package:mikunotes/core/bilibili/bilibili_client.dart";
import "package:mikunotes/core/models/ai_config.dart";
import "package:mikunotes/core/llm/prompt_template.dart" as llm_tpl;
import "package:mikunotes/core/models/prompt_template.dart";
import "package:mikunotes/core/models/video.dart" as model;
import "package:mikunotes/core/providers/providers.dart";
import "package:mikunotes/core/providers/templates_provider.dart";
import "package:mikunotes/core/storage/backup_service.dart";
import "package:mikunotes/core/storage/database.dart" as db hide Container;
import "package:mikunotes/ui/screens/login/login_screen.dart";
import "package:mikunotes/ui/screens/video_detail/video_detail_screen.dart";
import "package:dio/dio.dart";

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

  /// 导出选项弹窗 (3 选项)
  Future<void> _showExportOptions(BuildContext context, BackupService backupService) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('导出方式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('MikuNotes 备份目录'),
              subtitle: const Text('导出到外部存储 MikuNotes_backups/'),
              onTap: () async {
                Navigator.pop(ctx);
                await _doExport(context, backupService.exportAll, 'MikuNotes 备份目录');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('系统下载目录'),
              subtitle: const Text('导出到 Download/MikuNotes_backups/'),
              onTap: () async {
                Navigator.pop(ctx);
                await _doExport(context, () async {
                  final path = await backupService.exportToDownloads();
                  if (path == null) throw Exception('无法访问系统下载目录');
                  return path;
                }, '系统下载目录');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('通过系统分享'),
              subtitle: const Text('选择任意位置或发送到其他 app'),
              onTap: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(const SnackBar(content: Text('导出中…')));
                try {
                  final path = await backupService.exportAll();
                  await Share.shareXFiles(
                    [XFile(path)],
                    text: 'MikuNotes 数据备份',
                  );
                  messenger.showSnackBar(const SnackBar(content: Text('✓ 已发送分享')));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('✗ 失败: $e')));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _doExport(BuildContext context, Future<String> Function() exporter, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text('导出到 $label...')));
    try {
      final path = await exporter();
      messenger.showSnackBar(SnackBar(
        content: Text('✓ 已导出到: $path'),
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('✗ 导出失败: $e')));
    }
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
                  subtitle: const Text('备份/分享，重装后可恢复'),
                  onTap: () => _showExportOptions(context, backupService),
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
    _tab = TabController(length: 3, vsync: this);
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
              Tab(icon: Icon(Icons.summarize), text: '摘要'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: '对话'),
              Tab(icon: Icon(Icons.comment), text: '评论'),
            ],
          ),
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tab,
              children: [
                _TemplateList(type: TemplateType.summary),
                _TemplateList(type: TemplateType.chat),
                _TemplateList(type: TemplateType.comment),
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

