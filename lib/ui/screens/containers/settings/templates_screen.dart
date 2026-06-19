import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;
import 'package:mikunotes/core/models/prompt_template.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/ui/screens/containers/settings/template_editor_dialog.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => TemplatesScreenState();
}

class TemplatesScreenState extends ConsumerState<TemplatesScreen>
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
                TemplateList(type: TemplateType.summary),
                TemplateList(type: TemplateType.chat),
                TemplateList(type: TemplateType.comment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 模板列表（摘要或对话）
class TemplateList extends ConsumerWidget {
  final TemplateType type;
  const TemplateList({required this.type});

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

