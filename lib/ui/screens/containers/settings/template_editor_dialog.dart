import 'package:flutter/material.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;

/// 通用 Prompt 模板编辑器 (供 AI 自定义 prompt + 模板编辑复用)
/// 返回编辑后的内容, 取消返回 null
Future<String?> showTemplateEditorDialog(
  BuildContext context, {
  required String title,
  required String initial,
  required String defaultTemplate,
}) async {
  final controller = TextEditingController(
    text: initial.isEmpty ? defaultTemplate : initial,
  );
  return showDialog<String>(
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
                          final cursorPos = controller.selection.baseOffset;
                          if (cursorPos < 0) return;
                          final newText = controller.text.substring(0, cursorPos) +
                              '{{${e.key}}}' +
                              controller.text.substring(cursorPos);
                          controller.text = newText;
                          controller.selection = TextSelection.collapsed(
                            offset: (cursorPos + e.key.length + 4)
                                .clamp(0, newText.length),
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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  controller.text = defaultTemplate;
                },
                child: const Text('恢复默认'),
              ),
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
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('保存'),
        ),
      ],
    ),
  );
}