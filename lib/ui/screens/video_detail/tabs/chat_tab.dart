import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/llm/prompt_template.dart' as llm_tpl;
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/chat_message.dart' as chat_model;
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/providers/generation_provider.dart';
import 'package:mikunotes/core/providers/templates_provider.dart';
import 'package:mikunotes/core/storage/database.dart' as db;
import 'package:mikunotes/core/storage/database.dart' show Comment, DanmakuData;
import 'package:mikunotes/ui/screens/video_detail/data_tabs.dart' show DataSource;
import 'package:uuid/uuid.dart';
import 'package:mikunotes/ui/screens/video_detail/math_markdown.dart';

const _uuid = Uuid();

class ChatTab extends ConsumerStatefulWidget {
  final String bvid;
  final VideoSubtitle? subtitle;
  final int selectedPage;
  const ChatTab({super.key, required this.bvid, required this.subtitle, this.selectedPage = 1});

  @override
  ConsumerState<ChatTab> createState() => ChatTabState();
}

class ChatTabState extends ConsumerState<ChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  db.ChatSession? _currentSession;
  List<db.ChatMessage> _messages = [];
  String _streamingContent = '';
  bool _streaming = false;
  int _messageIndex = 0;
  int _tokensUsed = 0;
  bool _loading = true;

  // 数据源选择
  Set<DataSource> _chatSources = {DataSource.subtitle};
  List<Comment> _comments = [];
  List<DanmakuData> _danmaku = [];

  @override
  void initState() {
    super.initState();
    _initSession();
    _loadSources();
  }

  int get _page => widget.selectedPage == 0 ? 1 : widget.selectedPage;

  Future<void> _loadSources() async {
    final dbLocal = ref.read(databaseProvider);
    _comments = await dbLocal.getCommentsForVideo(widget.bvid, page: _page);
    _danmaku = await dbLocal.getDanmakuForVideo(widget.bvid, page: _page);
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 分P 切换时: 重新计算 tokens + 重新加载评论/弹幕数据
    if (oldWidget.subtitle != widget.subtitle) {
      final msgsTotal = _messages.fold(0, (sum, m) => sum + m.content.length);
      setState(() {
        _tokensUsed = LLMClient.estimateTokens(
          '${widget.subtitle?.fullText ?? ''}$msgsTotal',
        );
      });
    }
    if (oldWidget.selectedPage != widget.selectedPage) {
      _loadSources();
    }
  }

  Future<void> _initSession() async {
    final repo = ref.read(videoRepositoryProvider);
    final sessions = await repo.getChatSessions(widget.bvid);
    if (!mounted) return;
    if (sessions.isEmpty) {
      // 创建默认会话
      final s = await repo.createChatSession(widget.bvid);
      if (mounted) setState(() {
        _currentSession = s;
        _loading = false;
      });
    } else {
      _switchToSession(sessions.first);
    }
  }

  Future<void> _switchToSession(db.ChatSession s) async {
    final repo = ref.read(videoRepositoryProvider);
    final msgs = await repo.getChatMessages(s.id);
    final totalChars = msgs.fold(0, (sum, m) => sum + m.content.length);
    if (!mounted) return;
    setState(() {
      _currentSession = s;
      _messages = msgs;
      _streamingContent = '';
      _streaming = false;
      _messageIndex = msgs.length;
      _tokensUsed = LLMClient.estimateTokens(
        '${widget.subtitle?.fullText ?? ''}$totalChars',
      );
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _newSession() async {
    final repo = ref.read(videoRepositoryProvider);
    final s = await repo.createChatSession(widget.bvid);
    _switchToSession(s);
  }

  void _showSessionList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SessionListSheet(
        bvid: widget.bvid,
        currentId: _currentSession?.id,
        onSelect: (s) {
          Navigator.pop(ctx);
          _switchToSession(s);
        },
        onDelete: (s) async {
          await ref.read(videoRepositoryProvider).deleteChatSession(s.id);
        },
        onRename: (s) async {
          final newTitle = await _showRenameDialog(ctx, s.title);
          if (newTitle != null && newTitle.isNotEmpty) {
            await ref.read(videoRepositoryProvider)
                .updateSessionTitle(s.id, newTitle);
          }
        },
      ),
    );
  }

  Future<String?> _showRenameDialog(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _streaming) return;
    if (widget.subtitle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先下载字幕')),
      );
      return;
    }
    if (ref.read(aiConfigProvider).apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置 AI')),
      );
      return;
    }

    final repo = ref.read(videoRepositoryProvider);
    if (_currentSession == null) {
      final s = await repo.createChatSession(widget.bvid);
      _currentSession = s;
    }
    final session = _currentSession!;

    // 上下文压缩
    final config = ref.read(aiConfigProvider);
    final compressed = await repo.compressContextIfNeeded(
      session.id,
      llmClient: ref.read(llmClientProvider),
      config: config,
    );
    if (compressed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已自动压缩早期对话历史'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 保存用户消息
    await repo.addChatMessage(
      sessionId: session.id,
      role: chat_model.ChatRole.user,
      content: text,
    );

    final newUserMsg = db.ChatMessage(
      id: _uuid.v4(),
      sessionId: session.id,
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
      isCompressed: false,
    );

    setState(() {
      _messages = [..._messages, newUserMsg];
      _streaming = true;
      _streamingContent = '';
    });
    _messageIndex = _messages.length;
    _controller.clear();
    _scrollToBottom();

    // 构造上下文 (根据数据源 chip 选择)
    final subText = widget.subtitle?.fullText ?? '';
    final commentText = _chatSources.contains(DataSource.comment)
        ? _comments.map((c) => '【${c.likes}赞】${c.uname}: ${c.content}').join('\n')
        : '';
    final danmakuText = _chatSources.contains(DataSource.danmaku)
        ? _danmaku.take(300).map((d) => '[${_fmtTimeMs(d.progress)}] ${d.content}').join('\n')
        : '';

    final sourceContext = <String>[];
    if (subText.isNotEmpty && _chatSources.contains(DataSource.subtitle)) {
      final truncated = subText.length > 4000 ? '${subText.substring(0, 4000)}...(已截断)' : subText;
      sourceContext.add('## 字幕文本\n' + truncated);
    }
    if (commentText.isNotEmpty) {
      final truncated = commentText.length > 2000 ? '${commentText.substring(0, 2000)}...(已截断)' : commentText;
      sourceContext.add('## 评论\n' + truncated);
    }
    if (danmakuText.isNotEmpty) {
      final truncated = danmakuText.length > 2000 ? '${danmakuText.substring(0, 2000)}...(已截断)' : danmakuText;
      sourceContext.add('## 弹幕\n' + truncated);
    }

    final sessionMsgs = await repo.getChatMessages(session.id);
    final history = sessionMsgs
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    // 使用模板渲染 system prompt (但用选中的数据源替换字幕)
    final templates = ref.read(templatesProvider);
    final activeChat = templates.activeChat;
    final chatTemplate = activeChat?.content ??
        (config.chatTemplate.isNotEmpty ? config.chatTemplate : llm_tpl.defaultChatTemplate);
    // Build source text from selected chips
    final sourceText = sourceContext.join('\n\n');
    final systemPrompt = llm_tpl.PromptTemplate.render(chatTemplate, {
      'title': 'BV ${widget.bvid}',
      'bvid': widget.bvid,
      'subtitle': sourceText,
      'subtitle_truncated': sourceText,
      'language': widget.subtitle?.language ?? '',
      'uploader': '',
      'duration': '',
      'page_count': '',
    });

    try {
      final client = ref.read(llmClientProvider);
      final config = ref.read(aiConfigProvider);
      final disableReasoning = config.provider == LLMProvider.minimax;
          
      final buffer = StringBuffer();
      await for (final chunk in client.chatStreamWithFallback(
        systemPrompt: systemPrompt,
        messages: history,
        disableReasoning: disableReasoning,
      )) {
        buffer.write(chunk);
        setState(() => _streamingContent = buffer.toString());
        _scrollToBottom();
      }

      // 保存助手消息
      await repo.addChatMessage(
        sessionId: session.id,
        role: chat_model.ChatRole.assistant,
        content: buffer.toString(),
      );

      // 重新加载消息列表
      final msgs = await repo.getChatMessages(session.id);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _streamingContent = '';
          _streaming = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _streaming = false;
        _streamingContent = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('错误: $e')),
        );
      }
    }
  }

  String _fmtTimeMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '\${m.toString().padLeft(2, "0")}:\${(s % 60).toString().padLeft(2, "0")}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.subtitle == null) {
      return const Center(child: Text('请先下载字幕'));
    }

    return Column(
      children: [
        SessionBar(
          title: _currentSession?.title ?? '新对话',
          messageCount: _messages.length,
          tokensUsed: _tokensUsed,
          maxTokens: ref.read(aiConfigProvider).maxContextChars ~/ 2,
          onTap: _showSessionList,
          onNew: _newSession,
        ),
        // 数据源 chip
        Container(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(
            children: [
              const Text('数据源:', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              ...DataSource.values.map((s) {
                // 判断是否可点: subtitle 由 widget.subtitle 决定; comment/danmaku 由列表长度决定
                final available = switch (s) {
                  DataSource.subtitle => widget.subtitle != null,
                  DataSource.comment => _comments.isNotEmpty,
                  DataSource.danmaku => _danmaku.isNotEmpty,
                };
                return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilterChip(
                  label: Text(s.label, style: const TextStyle(fontSize: 10)),
                  selected: _chatSources.contains(s),
                  onSelected: available ? (sel) {
                    setState(() {
                      if (sel) {
                        _chatSources.add(s);
                      } else {
                        _chatSources.remove(s);
                      }
                    });
                  } : null,
                  visualDensity: VisualDensity.compact,
                  tooltip: available ? null : '${s.label} 未下载',
                  backgroundColor: available ? null : Colors.grey.shade200,
                ),
              );}),
            ],
          ),
        ),
        ChatSubtitleContext(subtitle: widget.subtitle, selectedPage: widget.selectedPage),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_streaming ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _messages.length && _streaming) {
                return ChatBubble(
                  content: _streamingContent,
                  isUser: false,
                  isStreaming: true,
                );
              }
              final m = _messages[i];
              return ChatBubble(
                content: m.content,
                isUser: m.role == 'user',
                isStreaming: false,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: '问点关于这个视频的问题...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(
                onPressed: _streaming ? null : _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChatSubtitleContext extends StatelessWidget {
  final VideoSubtitle? subtitle;
  final int selectedPage;
  const ChatSubtitleContext({required this.subtitle, required this.selectedPage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSub = subtitle != null;
    final pageLabel = selectedPage == 0 ? '整体' : 'P$selectedPage';
    return Material(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(
              hasSub ? Icons.subtitles_outlined : Icons.subtitles_off_outlined,
              size: 14,
              color: hasSub ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasSub
                    ? '📑 $pageLabel · ${subtitle!.language} · ${subtitle!.entries.length} 条'
                    : '未加载字幕 · $pageLabel',
                style: TextStyle(
                  fontSize: 12,
                  color: hasSub ? scheme.onSurface : scheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              hasSub ? '~${LLMClient.estimateTokens(subtitle!.fullText)} tokens' : '',
              style: TextStyle(fontSize: 11, color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class SessionBar extends StatelessWidget {
  final String title;
  final int messageCount;
  final int tokensUsed;
  final int maxTokens;
  final VoidCallback onTap;
  final VoidCallback onNew;

  const SessionBar({
    required this.title,
    required this.messageCount,
    required this.tokensUsed,
    required this.maxTokens,
    required this.onTap,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final usage = maxTokens > 0 ? (tokensUsed / maxTokens).clamp(0.0, 1.0) : 0.0;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble, size: 16),
                    const SizedBox(width: 4),
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 16),
                  ],
                ),
              ),
            ),
            Text('~$tokensUsed tokens',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                value: usage,
                backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              tooltip: '新对话',
              onPressed: onNew,
            ),
          ],
        ),
      ),
    );
  }
}

class SessionListSheet extends ConsumerWidget {
  final String bvid;
  final String? currentId;
  final Function(db.ChatSession) onSelect;
  final Function(db.ChatSession) onDelete;
  final Function(db.ChatSession) onRename;
  const SessionListSheet({
    required this.bvid,
    required this.currentId,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, scrollController) {
        return FutureBuilder<List<db.ChatSession>>(
          future: ref.read(videoRepositoryProvider).getChatSessions(bvid),
          builder: (ctx, snap) {
            final items = snap.data ?? [];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.chat),
                      const SizedBox(width: 8),
                      const Text('对话会话',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('共 ${items.length} 条',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('暂无对话会话')),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final s = items[i];
                        final isCurrent = s.id == currentId;
                        return ListTile(
                          leading: Icon(
                            isCurrent
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          title: Text(s.title),
                          subtitle: Text(_formatDate(s.lastActiveAt),
                              style: Theme.of(context).textTheme.bodySmall),
                          onTap: () => onSelect(s),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => onRename(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () => onDelete(s),
                              ),
                            ],
                          ),
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
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isStreaming;
  const ChatBubble({
    required this.content,
    required this.isUser,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MathMarkdownBody(
              data: content.isEmpty ? (isStreaming ? '...' : ' ') : content,
              selectable: !isStreaming,
            ),
            if (isStreaming)
              const SizedBox(
                height: 3,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
