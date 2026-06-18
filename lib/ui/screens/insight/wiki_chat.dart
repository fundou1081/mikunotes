import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/wiki/wiki_orchestrator.dart';
import 'package:mikunotes/core/wiki/wiki_context.dart';
import 'package:mikunotes/core/providers/providers.dart' show llmClientProvider, aiConfigProvider, databaseProvider;

/// 💬 Wiki 多轮对话 — Skill 风格渐进性披露
/// LLM 看到 manifest, 决定要加载哪些视频, 我们加载后再问
class WikiChat extends ConsumerStatefulWidget {
    const WikiChat({super.key});

    @override
    ConsumerState<WikiChat> createState() => _WikiChatState();
}

class _WikiChatState extends ConsumerState<WikiChat> {
    WikiChatOrchestrator? _orchestrator;
    final List<ChatMsg> _messages = [];
    final TextEditingController _inputController = TextEditingController();
    final ScrollController _scrollController = ScrollController();
    bool _sending = false;
    String? _error;
    String? _loadingStatus;  // "加载 manifest..." | "加载视频..." | null

    @override
    void dispose() {
        _inputController.dispose();
        _scrollController.dispose();
        super.dispose();
    }

    WikiChatOrchestrator _getOrchestrator() {
        _orchestrator ??= WikiChatOrchestrator(
            client: ref.read(llmClientProvider),
            contextLoader: ref.read(wikiContextLoaderProvider),
            config: ref.read(aiConfigProvider),
        );
        return _orchestrator!;
    }

    Future<void> _send() async {
        final text = _inputController.text.trim();
        if (text.isEmpty || _sending) return;

        final config = ref.read(aiConfigProvider);
        if (config.apiKey.isEmpty) {
            setState(() => _error = '请先在设置中配置 AI API Key');
            return;
        }

        setState(() {
            _messages.add(ChatMsg(role: 'user', content: text, time: DateTime.now()));
            _sending = true;
            _error = null;
            _inputController.clear();
            _loadingStatus = '正在思考 (加载 manifest)...';
        });
        _scrollToBottom();

        final messenger = ScaffoldMessenger.of(context);
        try {
            final orch = _getOrchestrator();
            // 同步显示 manifest 加载状态
            setState(() => _loadingStatus = 'LLM 选择加载哪些视频...');
            _scrollToBottom();

            final result = await orch.handleUserMessage(text);

            setState(() {
                _messages.add(ChatMsg(
                    role: 'assistant',
                    content: result.content,
                    time: DateTime.now(),
                    loadedBvids: result.loadedBvids,
                ));
                _loadingStatus = null;
            });
            _scrollToBottom();
        } catch (e) {
            setState(() {
                _error = '$e';
                _loadingStatus = null;
            });
            messenger.showSnackBar(SnackBar(content: Text('✗ $e')));
        } finally {
            setState(() => _sending = false);
        }
    }

    void _clearChat() {
        setState(() {
            _messages.clear();
            _error = null;
            _orchestrator?.history.clear();
        });
    }

    void _scrollToBottom() {
        Future.microtask(() {
            if (_scrollController.hasClients) {
                _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                );
            }
        });
    }

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                // 顶部信息条
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Row(
                        children: [
                            Icon(Icons.psychology_outlined,
                                color: Theme.of(context).colorScheme.onPrimaryContainer, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(
                                    'Skill 渐进性披露 · LLM 看到 manifest, 按需加载',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                ),
                            ),
                            if (_messages.isNotEmpty)
                                TextButton.icon(
                                    onPressed: _clearChat,
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    label: const Text('清空'),
                                ),
                        ],
                    ),
                ),

                // 消息列表
                Expanded(
                    child: _messages.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length + (_sending ? 1 : 0),
                            itemBuilder: (ctx, i) {
                                if (i == _messages.length && _sending) {
                                    return _buildStatusBubble(_loadingStatus ?? '...');
                                }
                                return _buildMessage(_messages[i]);
                            },
                        ),
                ),

                // 错误提示
                if (_error != null)
                    Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        padding: const EdgeInsets.all(8),
                        child: Row(
                            children: [
                                Icon(Icons.error, color: Theme.of(context).colorScheme.onErrorContainer, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        _error!,
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.onErrorContainer,
                                            fontSize: 12,
                                        ),
                                    ),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => setState(() => _error = null),
                                ),
                            ],
                        ),
                    ),

                // 输入区
                SafeArea(
                    top: false,
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(
                                top: BorderSide(
                                    color: Theme.of(context).colorScheme.outlineVariant,
                                ),
                            ),
                        ),
                        child: Row(
                            children: [
                                Expanded(
                                    child: TextField(
                                        controller: _inputController,
                                        decoration: const InputDecoration(
                                            hintText: '问点啥, 比如: 我有哪几个 RISC-V 视频?',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                        ),
                                        maxLines: 4,
                                        minLines: 1,
                                        textInputAction: TextInputAction.send,
                                        onSubmitted: (_) => _send(),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                    onPressed: _sending ? null : _send,
                                    icon: _sending
                                        ? const SizedBox(
                                            width: 16, height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.send),
                                    label: const Text('发送'),
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        );
    }

    Widget _buildMessage(ChatMsg m) {
        final isUser = m.role == 'user';
        return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // 加载了哪些视频的提示
                        if (m.loadedBvids.isNotEmpty)
                            Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        const Icon(Icons.menu_book, size: 12, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                            '加载了 ${m.loadedBvids.length} 个视频: ${m.loadedBvids.join(", ")}',
                                            style: const TextStyle(fontSize: 10, color: Colors.green),
                                        ),
                                    ],
                                ),
                            ),
                        SelectableText(
                            m.content,
                            style: const TextStyle(fontSize: 14),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _buildStatusBubble(String text) {
        return Align(
            alignment: Alignment.centerLeft,
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        const SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(text, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                ),
            ),
        );
    }

    Widget _emptyState() {
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.psychology,
                            size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('开始对话', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                            'Skill 渐进性披露模式:\n'
                            '· LLM 看到所有视频的 manifest (标题/标签/UP主)\n'
                            '· 需要细节时 LLM 主动要求加载\n'
                            '· 加载的内容只在该轮使用, 不污染主 context',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 12,
                            ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                            spacing: 8,
                            children: [
                                _suggestChip('我有几个 RISC-V 视频?'),
                                _suggestChip('最近看的视频主题是什么?'),
                                _suggestChip('帮我对比两个视频'),
                            ],
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _suggestChip(String text) {
        return ActionChip(
            label: Text(text, style: const TextStyle(fontSize: 12)),
            onPressed: () {
                _inputController.text = text;
            },
        );
    }
}
