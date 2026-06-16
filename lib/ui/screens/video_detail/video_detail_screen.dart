import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/chat_message.dart';
import 'package:mikunotes/core/models/subtitle.dart';
import 'package:mikunotes/core/models/summary.dart';
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class VideoDetailScreen extends ConsumerStatefulWidget {
  final String bvid;
  const VideoDetailScreen({super.key, required this.bvid});

  @override
  ConsumerState<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends ConsumerState<VideoDetailScreen> {
  VideoSubtitle? _subtitle;
  bool _loadingSubtitle = true;

  @override
  void initState() {
    super.initState();
    _loadSubtitle();
  }

  Future<void> _loadSubtitle() async {
    final repo = ref.read(videoRepositoryProvider);
    final sub = await repo.getSubtitle(widget.bvid);
    setState(() {
      _subtitle = sub;
      _loadingSubtitle = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('视频 ${widget.bvid}', maxLines: 1, overflow: TextOverflow.ellipsis),
          bottom: const TabBar(tabs: [
            Tab(text: '摘要', icon: Icon(Icons.summarize)),
            Tab(text: '对话', icon: Icon(Icons.chat_bubble_outline)),
            Tab(text: '字幕', icon: Icon(Icons.subtitles)),
          ]),
        ),
        body: TabBarView(children: [
          _SummaryTab(bvid: widget.bvid, subtitle: _subtitle, loading: _loadingSubtitle),
          _ChatTab(bvid: widget.bvid, subtitle: _subtitle),
          _SubtitleTab(bvid: widget.bvid, subtitle: _subtitle, loading: _loadingSubtitle),
        ]),
      ),
    );
  }
}

class _SummaryTab extends ConsumerStatefulWidget {
  final String bvid;
  final VideoSubtitle? subtitle;
  final bool loading;

  const _SummaryTab({
    required this.bvid,
    required this.subtitle,
    required this.loading,
  });

  @override
  ConsumerState<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends ConsumerState<_SummaryTab> {
  String? _summary;
  bool _generating = false;
  String? _error;

  static const _defaultPrompt = """你是B站视频内容总结助手。请严格按照以下格式输出结构化总结：

## 📺 视频概述
一句话概括视频主题。

## 🧠 核心概念/名词解释
用表格列出视频中出现的核心概念、术语、专有名词，并给出简洁解释。

## 💡 有价值的观点
列举视频中独特、有启发性的观点（3-5条），每条引用视频中的具体论据。

## 🔑 最重要的观点
提炼视频最核心的1-2个论点，说明为什么这是关键。

## 📐 行文逻辑
用流程图或层级结构展示视频的论证逻辑。

## ❓ 提问-回答
针对视频核心议题，设计3-5个关键问答（Q&A格式）。

要求:
- 使用 Markdown 格式
- 概念解释简洁准确
- 观点引用视频原话
- 板块间用 --- 分隔""";

  Future<void> _downloadSubtitle() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final repo = ref.read(videoRepositoryProvider);
      final sub = await repo.downloadAndStoreSubtitle(widget.bvid);
      if (!mounted) return;
      if (sub != null) {
        setState(() {
          _generating = false;
          _error = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ 字幕下载成功: ${sub.entries.length} 条')),
        );
        // 替换当前页面以刷新
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoDetailScreen(bvid: widget.bvid),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = '字幕下载失败: $e';
        _generating = false;
      });
    }
  }

  Future<void> _generateSummary({String? customPrompt}) async {
    if (widget.subtitle == null || widget.subtitle!.entries.isEmpty) {
      setState(() => _error = '请先下载字幕');
      return;
    }

    final apiKey = ref.read(aiConfigProvider).apiKey;
    if (apiKey.isEmpty) {
      setState(() => _error = '请先在设置中配置 AI API Key');
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final client = ref.read(llmClientProvider);
      final config = ref.read(aiConfigProvider);
      final prompt = customPrompt ?? config.customSystemPrompt;
      final systemPrompt = prompt.isNotEmpty ? prompt : _defaultPrompt;

      final transcript = widget.subtitle!.fullText;
      final maxChars = 12000;
      final truncated = transcript.length > maxChars
          ? '${transcript.substring(0, maxChars)}\n\n... (已截断)'
          : transcript;

      final summary = await client.chat(
        systemPrompt: systemPrompt,
        userMessage: '视频 BV号: ${widget.bvid}\n\n字幕内容:\n$truncated',
      );

      // 保存到数据库
      final db = ref.read(databaseProvider);
      await db.saveSummary(SummariesCompanion(
        id: Value(_uuid.v4()),
        bvid: Value(widget.bvid),
        type: const Value('structured'),
        content: Value(summary),
        modelUsed: Value(config.effectiveModel),
        promptUsed: Value(systemPrompt),
        createdAt: Value(DateTime.now()),
      ));

      setState(() {
        _summary = summary;
        _generating = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _generating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_summary != null) {
      return Markdown(
        data: _summary!,
        padding: const EdgeInsets.all(16),
        selectable: true,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
            ),
          const Spacer(),
          // 字幕缺失时显示下载按钮
          if (_error == '请先下载字幕')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: _generating ? null : _downloadSubtitle,
                icon: _generating
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download),
                label: Text(_generating ? '下载中...' : '下载字幕'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            ),
          if (_generating)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                FilledButton.icon(
                  onPressed: _generateSummary,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('生成 AI 总结', style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showTopicExpansionDialog(),
                  icon: const Icon(Icons.open_in_full),
                  label: const Text('主题展开'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
              ],
            ),
          const Spacer(),
        ],
      ),
    );
  }

  void _showTopicExpansionDialog() {
    final topicController = TextEditingController();
    final promptController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('主题展开'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicController,
                decoration: const InputDecoration(
                  labelText: '主题/角度',
                  hintText: '例如: 这个视频的核心方法论',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: promptController,
                decoration: const InputDecoration(
                  labelText: '自定义 Prompt (可选)',
                  hintText: '留空使用默认',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final topic = topicController.text.trim();
              final userPrompt = promptController.text.trim();
              final fullPrompt = userPrompt.isEmpty
                  ? '针对视频主题 "$topic" 进行深入分析。\n\n$_defaultPrompt'
                  : userPrompt;
              _generateSummary(customPrompt: fullPrompt);
            },
            child: const Text('生成'),
          ),
        ],
      ),
    );
  }
}

class _ChatTab extends ConsumerStatefulWidget {
  final String bvid;
  final VideoSubtitle? subtitle;
  const _ChatTab({required this.bvid, required this.subtitle});

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessageModel> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
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

    final db = ref.read(databaseProvider);
    final userMsg = ChatMessageModel(
      id: _uuid.v4(),
      videoId: widget.bvid,
      role: ChatRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages = [..._messages, userMsg];
      _sending = true;
    });
    _controller.clear();
    await db.saveChatMessage(ChatMessagesCompanion(
      id: Value(userMsg.id),
      bvid: Value(userMsg.videoId),
      role: Value(userMsg.role.name),
      content: Value(userMsg.content),
      timestamp: Value(userMsg.timestamp),
    ));

    try {
      final client = ref.read(llmClientProvider);
      final context = widget.subtitle!.fullText.length > 8000
          ? '${widget.subtitle!.fullText.substring(0, 8000)}\n\n... (已截断)'
          : widget.subtitle!.fullText;

      final history = _messages
          .map((m) => {
                'role': m.role == ChatRole.user ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final reply = await client.chatMultiTurn(
        systemPrompt:
            '你是视频内容问答助手。基于以下字幕内容回答用户问题。如果问题超出字幕范围，明确告知用户。\n\n字幕内容:\n$context',
        messages: history,
      );

      final assistantMsg = ChatMessageModel(
        id: _uuid.v4(),
        videoId: widget.bvid,
        role: ChatRole.assistant,
        content: reply,
        timestamp: DateTime.now(),
      );

      await db.saveChatMessage(ChatMessagesCompanion(
        id: Value(assistantMsg.id),
        bvid: Value(assistantMsg.videoId),
        role: Value(assistantMsg.role.name),
        content: Value(assistantMsg.content),
        timestamp: Value(assistantMsg.timestamp),
      ));

      setState(() {
        _messages = [..._messages, assistantMsg];
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('错误: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Text('开始对话吧'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, idx) {
                    final m = _messages[idx];
                    return _ChatBubble(message: m);
                  },
                ),
        ),
        if (_sending)
          const LinearProgressIndicator(),
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
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
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
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: MarkdownBody(
          data: message.content,
          selectable: true,
        ),
      ),
    );
  }
}

class _SubtitleTab extends ConsumerStatefulWidget {
  final String bvid;
  final VideoSubtitle? subtitle;
  final bool loading;
  const _SubtitleTab({required this.bvid, required this.subtitle, required this.loading});

  @override
  ConsumerState<_SubtitleTab> createState() => _SubtitleTabState();
}

class _SubtitleTabState extends ConsumerState<_SubtitleTab> {
  bool _retrying = false;
  String? _error;

  Future<void> _retry() async {
    setState(() {
      _retrying = true;
      _error = null;
    });
    try {
      final repo = ref.read(videoRepositoryProvider);
      final sub = await repo.downloadAndStoreSubtitle(widget.bvid);
      if (mounted && sub != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ 字幕下载成功: ${sub.entries.length} 条')),
        );
        // 重新进入该视频详情页，触发父组件 _loadSubtitle
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoDetailScreen(bvid: widget.bvid),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.subtitle == null || widget.subtitle!.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.subtitles_off, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              const Text('暂无字幕'),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _retrying ? null : _retry,
                icon: _retrying
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: Text(_retrying ? '下载中...' : '重试下载字幕'),
              ),
            ],
          ),
        ),
      );
    }
    final subtitle = widget.subtitle!;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: subtitle.entries.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, idx) {
        final e = subtitle.entries[idx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${e.from.toStringAsFixed(1)}s - ${e.to.toStringAsFixed(1)}s',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(e.content),
          ],
        );
      },
    );
  }
}
