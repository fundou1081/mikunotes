import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/providers/providers.dart' show llmClientProvider, aiConfigProvider;
import 'package:mikunotes/core/models/ai_config.dart';

/// 单条消息
class _ChatMessage {
    final String role;     // 'user' | 'assistant'
    final String content;
    final DateTime time;
    _ChatMessage({required this.role, required this.content, required this.time});
}

/// 💬 Wiki 多轮对话 — 简单 LLM chat
/// v0.5.1 范围: 单线程, 内存中保存 (v0.6.0 可加持久化)
class WikiChat extends ConsumerStatefulWidget {
    const WikiChat({super.key});

    @override
    ConsumerState<WikiChat> createState() => _WikiChatState();
}

class _WikiChatState extends ConsumerState<WikiChat> {
    final List<_ChatMessage> _messages = [];
    final TextEditingController _inputController = TextEditingController();
    final ScrollController _scrollController = ScrollController();
    bool _sending = false;
    String? _error;

    @override
    void dispose() {
        _inputController.dispose();
        _scrollController.dispose();
        super.dispose();
    }

    Future<void> _send() async {
        final text = _inputController.text.trim();
        if (text.isEmpty || _sending) return;

        // 检查 LLM 配置
        final config = ref.read(aiConfigProvider);
        if (config.apiKey.isEmpty) {
            setState(() => _error = '请先在设置中配置 AI API Key');
            return;
        }

        setState(() {
            _messages.add(_ChatMessage(
                role: 'user', content: text, time: DateTime.now()));
            _sending = true;
            _error = null;
            _inputController.clear();
        });
        _scrollToBottom();

        final messenger = ScaffoldMessenger.of(context);
        try {
            final client = ref.read(llmClientProvider);
            // 简单非流式调用 (v0.5.1 不做流式, 之后可加)
            final history = <Map<String, String>>[
                for (final m in _messages)
                    {'role': m.role, 'content': m.content}
            ];
            final disableReasoning = config.provider == LLMProvider.minimax;
            // 收集所有 chunks
            final buffer = StringBuffer();
            await for (final chunk in client.chatStreamWithFallback(
                systemPrompt: '你是 MikuNotes Wiki 助手, 帮助用户理解和探索他们的视频库 Wiki 内容。回答简洁。',
                messages: const [], // 历史用 messages 传
                disableReasoning: disableReasoning,
            )) {
                buffer.write(chunk);
                // 流式更新最后一条 AI 消息
                if (_messages.isNotEmpty && _messages.last.role == 'user') {
                    setState(() {
                        _messages.add(_ChatMessage(
                            role: 'assistant', content: buffer.toString(), time: DateTime.now()));
                    });
                } else if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
                    setState(() {
                        _messages[_messages.length - 1] = _ChatMessage(
                            role: 'assistant', content: buffer.toString(), time: _messages.last.time);
                    });
                }
                _scrollToBottom();
            }
        } catch (e) {
            setState(() => _error = '$e');
            messenger.showSnackBar(SnackBar(content: Text('✗ $e')));
        } finally {
            setState(() => _sending = false);
        }
    }

    void _clearChat() {
        setState(() {
            _messages.clear();
            _error = null;
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
                            Icon(Icons.lightbulb_outline,
                                color: Theme.of(context).colorScheme.onPrimaryContainer, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(
                                    'LLM Wiki 助手 · 内存中保存, 关闭 tab 后清空',
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
                                    return _buildBubble('assistant', '...', isTyping: true);
                                }
                                final m = _messages[i];
                                return _buildBubble(m.role, m.content);
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
                                            hintText: '输入问题, 与 AI 探讨 Wiki...',
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

    Widget _buildBubble(String role, String content, {bool isTyping = false}) {
        final isUser = role == 'user';
        return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                ),
                child: isTyping
                    ? const Text('...', style: TextStyle(fontSize: 16))
                    : SelectableText(content, style: const TextStyle(fontSize: 14)),
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
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('开始对话', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                            'v0.5.1 范围: 简单 LLM chat\n'
                            'v0.6.0 将加: 自动读取 wiki 文件作为 context',
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
}
