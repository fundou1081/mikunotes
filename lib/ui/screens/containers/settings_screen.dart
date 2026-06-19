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
import "package:mikunotes/ui/screens/containers/settings/templates_screen.dart";
import "package:mikunotes/ui/screens/containers/settings/ai_settings_screen.dart";

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigProvider);
  }

  /// 从当前 endpoint 拉取可用模型列表
/// 模型选择器
@override
  void dispose() {
    super.dispose();
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
    final dlBackups = await BackupService.listBackupsInDownloads();
    final allBackups = [...backups, ...dlBackups];
    if (!mounted) return;
    if (allBackups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份目录和下载目录都没有备份文件')),
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
            itemCount: allBackups.length,
            itemBuilder: (_, i) {
              final path = allBackups[i];
              final name = path.split('/').last;
              final isDL = path.contains('/Download/');
              return ListTile(
                leading: Icon(isDL ? Icons.download : Icons.folder, size: 18),
                title: Text(name, style: const TextStyle(fontSize: 13)),
                subtitle: Text(isDL ? '下载目录' : '备份目录',
                    style: const TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('恢复中…')),
                  );
                  final result = await backupService.restoreFrom(path);
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
                  subtitle: const Text('备份目录 + 下载目录'),
                  onTap: () async {
                    final backups = await BackupService.listBackups();
                    final dlBackups = await BackupService.listBackupsInDownloads();
                    final allBackups = [...backups, ...dlBackups];
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('备份文件'),
                        content: allBackups.isEmpty
                            ? const Text('暂无备份')
                            : SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: allBackups.length,
                                  itemBuilder: (_, i) {
                                    final path = allBackups[i];
                                    final name = path.split('/').last;
                                    final isDL = path.contains('/Download/');
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(isDL ? Icons.download : Icons.folder, size: 16),
                                      title: Text(name, style: const TextStyle(fontSize: 13)),
                                      subtitle: Text(isDL ? '下载目录' : '备份目录',
                                          style: const TextStyle(fontSize: 11)),
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

          // ── AI 配置 ──────────────────────────────
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('AI 配置'),
            subtitle: const Text('配置 LLM Provider / API Key / 模型 / Prompt'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Prompt 模板管理区 — Tab 切换摘要/对话
