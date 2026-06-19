import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/containers/settings/templates_screen.dart';
import 'package:dio/dio.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
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

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  Future<void> _fetchModels() async {
    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    if (baseUrl.isEmpty || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写 Base URL 和 API Key')),
      );
      return;
    }
    setState(() => _fetchingModels = true);
    try {
      final dio = Dio();
      final resp = await dio.get(
        '$baseUrl/models',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
          validateStatus: (s) => s != null && s < 500,
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        final models = <String>[];
        if (data is Map && data['data'] is List) {
          for (final m in data['data']) {
            if (m is Map && m['id'] is String) {
              models.add(m['id'] as String);
            }
          }
        } else if (data is List) {
          for (final m in data) {
            if (m is Map && m['id'] is String) {
              models.add(m['id'] as String);
            }
          }
        }
        if (models.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未发现可用模型')),
          );
        } else {
          await _showModelPicker(models);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拉取失败: HTTP ${resp.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拉取失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  Future<void> _showModelPicker(List<String> models) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.list),
                const SizedBox(width: 8),
                Text('选模型 (${models.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
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
                    onTap: () => Navigator.pop(ctx, m),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() => _modelController.text = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aiConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AI 配置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
      // ── Prompt 模板 ──────────────────────────
      ListTile(
        leading: const Icon(Icons.description_outlined),
        title: const Text('Prompt 模板管理'),
        subtitle: const Text('管理摘要 / 对话 / 评论模板'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TemplatesScreen()),
          );
        },
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
