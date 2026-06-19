import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/wiki/cross_video_provider.dart';
import 'package:mikunotes/core/wiki/insight_storage.dart';
import 'package:mikunotes/core/providers/providers.dart' show aiConfigProvider;
import 'package:mikunotes/ui/screens/insight/video_multi_select_screen.dart';
import 'package:mikunotes/ui/screens/insight/wiki_viewer.dart' show WikiFileViewer;
import 'package:mikunotes/ui/screens/video_detail/math_markdown.dart';

/// 跨视频洞察主屏
/// 流程: 选视频 → 选 LLM 模板 → 生成 → 显示 + 保存
class CrossVideoScreen extends ConsumerStatefulWidget {
    const CrossVideoScreen({super.key});

    @override
    ConsumerState<CrossVideoScreen> createState() => _CrossVideoScreenState();
}

class _CrossVideoScreenState extends ConsumerState<CrossVideoScreen> {
    Set<String> _selectedBvids = {};
    String _title = '跨视频洞察';
    bool _titleEdited = false;

    @override
    void initState() {
        super.initState();
        // 状态进入时重置
        Future.microtask(() {
            ref.read(crossVideoProvider.notifier).clear();
        });
    }

    Future<void> _pickVideos() async {
        final result = await Navigator.of(context).push<Set<String>>(
            MaterialPageRoute(
                builder: (_) => VideoMultiSelectScreen(
                    initiallySelected: _selectedBvids,
                    title: '选视频生成洞察',
                ),
            ),
        );
        if (result == null) return;
        setState(() {
            _selectedBvids = result;
            if (!_titleEdited) {
                _title = '跨视频洞察: ${result.length} 视频';
            }
        });
    }

    Future<void> _generate() async {
        if (_selectedBvids.length < 2) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请先选至少 2 个视频')),
            );
            return;
        }
        final config = ref.read(aiConfigProvider);
        if (config.apiKey.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请先在设置中配置 AI API Key')),
            );
            return;
        }
        await ref.read(crossVideoProvider.notifier).generate(
            bvids: _selectedBvids.toList(),
            title: _title,
            onChunk: (chunk) {
                if (mounted) {
                    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                    ref.read(crossVideoProvider.notifier).state =
                        ref.read(crossVideoProvider).copyWith(content: chunk);
                }
            },
        );
    }

    void _viewSavedInsight(String id) {
        ref.read(insightStorageProvider).read(id).then((content) {
            if (!mounted) return;
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => WikiFileViewer(
                        title: '跨视频洞察',
                        content: content,
                    ),
                ),
            );
        });
    }

    @override
    Widget build(BuildContext context) {
        final state = ref.watch(crossVideoProvider);

        return Scaffold(
            appBar: AppBar(
                title: const Text('跨视频洞察'),
                actions: [
                    if (state.insightId != null)
                        IconButton(
                            icon: const Icon(Icons.open_in_new),
                            tooltip: '查看已保存的洞察',
                            onPressed: () => _viewSavedInsight(state.insightId!),
                        ),
                ],
            ),
            body: Column(
                children: [
                    // 顶部配置区
                    _buildConfigCard(state),
                    // 结果区
                    Expanded(child: _buildResultArea(state)),
                ],
            ),
        );
    }

    Widget _buildConfigCard(CrossVideoState state) {
        return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        // 视频选择
                        Row(
                            children: [
                                const Icon(Icons.video_library),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        _selectedBvids.isEmpty
                                            ? '未选视频'
                                            : '已选 ${_selectedBvids.length} 个视频',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                ),
                                OutlinedButton.icon(
                                    onPressed: state.isGenerating ? null : _pickVideos,
                                    icon: const Icon(Icons.checklist, size: 18),
                                    label: const Text('选视频'),
                                ),
                            ],
                        ),
                        if (_selectedBvids.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                                spacing: 4, runSpacing: 4,
                                children: _selectedBvids.map((b) => Chip(
                                    label: Text(b, style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                )).toList(),
                            ),
                        ],
                        const SizedBox(height: 12),
                        // 标题
                        TextField(
                            decoration: const InputDecoration(
                                labelText: '洞察主题',
                                border: OutlineInputBorder(),
                                isDense: true,
                                hintText: '例如: 对比两个 UP 主讲 RISC-V 的视角',
                            ),
                            controller: TextEditingController(text: _title)
                                ..selection = TextSelection.collapsed(offset: _title.length),
                            onChanged: (v) {
                                _title = v;
                                _titleEdited = true;
                            },
                        ),
                        const SizedBox(height: 12),
                        // 生成按钮
                        FilledButton.icon(
                            onPressed: state.isGenerating || _selectedBvids.length < 2
                                ? null
                                : _generate,
                            icon: state.isGenerating
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.auto_awesome),
                            label: Text(state.isGenerating ? '生成中...' : '生成洞察'),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _buildResultArea(CrossVideoState state) {
        if (state.isGenerating) {
            return Column(
                children: [
                    const LinearProgressIndicator(),
                    Expanded(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                                state.content.isEmpty ? '正在思考...' : state.content,
                                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                            ),
                        ),
                    ),
                ],
            );
        }
        if (state.error != null) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.error_outline, size: 48,
                                color: Theme.of(context).colorScheme.error),
                            const SizedBox(height: 12),
                            Text('生成失败: ${state.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red)),
                        ],
                    ),
                ),
            );
        }
        if (state.content.isEmpty) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.compare_arrows, size: 80,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            Text('跨视频洞察', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                                '1. 选 2-N 个视频\n'
                                '2. 给个主题 (可选)\n'
                                '3. 点 "生成洞察"\n\n'
                                'LLM 会基于视频总结, 生成:\n'
                                '· 共同主题\n· 互补信息\n· 观点演变\n· 跨视频洞察\n· 推荐学习路径',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.outline,
                                    fontSize: 12,
                                ),
                            ),
                        ],
                    ),
                ),
            );
        }
        // 显示生成的洞察
        return Column(
            children: [
                // 顶部: 已保存提示
                Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.green.withValues(alpha: 0.15),
                    child: Row(
                        children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(
                                    '已保存到 insights/${state.insightId ?? ""}',
                                    style: const TextStyle(fontSize: 12),
                                ),
                            ),
                            TextButton.icon(
                                onPressed: () => _viewSavedInsight(state.insightId!),
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: const Text('全屏'),
                            ),
                        ],
                    ),
                ),
                Expanded(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: MathMarkdownBody(
                            data: state.content,
                            selectable: true,
                        ),
                    ),
                ),
            ],
        );
    }
}
