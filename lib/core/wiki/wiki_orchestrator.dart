import 'dart:async';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/wiki/wiki_context.dart';

/// 聊天消息
class ChatMsg {
    final String role;     // 'user' | 'assistant'
    final String content;
    final DateTime time;
    final List<String> loadedBvids;  // 这一轮加载了哪些视频 (assistant only)
    ChatMsg({
        required this.role,
        required this.content,
        required this.time,
        this.loadedBvids = const [],
    });
}

/// Wiki 聊天协调器
/// 实现 skill 风格的渐进性披露:
///   第 1 轮: 给 LLM manifest, 让它说要加载哪些视频
///   第 2 轮: 加载这些视频, 再让 LLM 基于内容回答
class WikiChatOrchestrator {
    final LLMClient client;
    final WikiContextLoader contextLoader;
    final AIConfig config;
    final List<ChatMsg> history = [];

    WikiChatOrchestrator({
        required this.client,
        required this.contextLoader,
        required this.config,
    });

    /// 处理用户消息
    /// 返回 (完整响应, 加载的 bvids 列表)
    Future<({String content, List<String> loadedBvids})> handleUserMessage(String userText) async {
        history.add(ChatMsg(role: 'user', content: userText, time: DateTime.now()));

        // 第 1 轮: 给 LLM manifest
        final manifest = await contextLoader.buildManifestPrompt();
        final systemPrompt = _buildSystemPrompt(manifest);

        final firstResponse = await _callLLM(systemPrompt, [
            for (final m in history.take(history.length - 1))
                {'role': m.role, 'content': m.content},
            {'role': 'user', 'content': userText},
        ]);

        // 解析 LLM 想加载的 BV 号
        final bvidsToLoad = _extractBvidRequests(firstResponse);
        if (bvidsToLoad.isEmpty) {
            // LLM 认为 manifest 够用, 不需要加载
            final cleaned = _stripNeedToReadTags(firstResponse);
            history.add(ChatMsg(role: 'assistant', content: cleaned, time: DateTime.now()));
            return (content: cleaned, loadedBvids: <String>[]);
        }

        // 第 2 轮: 加载视频内容, 再问 LLM
        final loaded = await contextLoader.loadVideoContents(bvidsToLoad);
        final loadedSection = _buildLoadedSection(loaded);

        final secondUserMsg = '$userText\n\n---\n\n我已经加载了以下视频的完整内容:\n\n$loadedSection\n\n请基于这些内容回答。';

        final secondResponse = await _callLLM(systemPrompt, [
            for (final m in history.take(history.length - 1))
                {'role': m.role, 'content': m.content},
            {'role': 'user', 'content': secondUserMsg},
        ]);

        history.add(ChatMsg(
            role: 'assistant', content: secondResponse,
            time: DateTime.now(), loadedBvids: bvidsToLoad));
        return (content: secondResponse, loadedBvids: bvidsToLoad);
    }

    /// 单轮 LLM 调用 (非流式, 因为协调器需要完整结果)
    Future<String> _callLLM(String systemPrompt, List<Map<String, String>> messages) async {
        final disableReasoning = config.provider == LLMProvider.minimax;
        final buffer = StringBuffer();
        await for (final chunk in client.chatStreamWithFallback(
            systemPrompt: systemPrompt,
            messages: messages,
            disableReasoning: disableReasoning,
        )) {
            buffer.write(chunk);
        }
        return buffer.toString();
    }

    /// 解析 LLM 输出的 <need_to_read>BV1,BV2</need_to_read>
    List<String> _extractBvidRequests(String llmResponse) {
        final regex = RegExp(r'<need_to_read>([^<]+)</need_to_read>');
        final match = regex.firstMatch(llmResponse);
        if (match == null) return [];
        final content = match.group(1) ?? '';
        return content
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.startsWith('BV') || s.startsWith('bv'))
            .toList();
    }

    /// 移除 need_to_read 标签 (用户最终看到的回答里不该有这标签)
    String _stripNeedToReadTags(String text) {
        return text
            .replaceAll(RegExp(r'<need_to_read>[^<]+</need_to_read>'), '')
            .replaceAll(RegExp(r'\n{3,}'), '\n\n')
            .trim();
    }

    String _buildSystemPrompt(String manifest) {
        return '''你是 MikuNotes Wiki 助手。你能访问用户的视频库 Wiki 知识库。

$manifest

---

## 🎯 你的工作方式

1. 收到用户问题时, 先看 manifest 是否能直接回答 (如"我有多少个视频")
2. 如果需要看具体内容, 输出 `<need_to_read>BVxxx,BVxxx</need_to_read>` 标记你要加载的视频
3. 不要凭 manifest 编造细节 (摘要内容、对话内容等)
4. 如果 manifest 信息够用 (tag/UP主/标题), 直接回答

## 📝 回答风格

- 用中文回答
- 结构化 (用 markdown 标题/列表)
- 引用具体视频时用 `[标题](BVxxx)` 格式
- 简洁但信息密度高
''';
    }

    String _buildLoadedSection(Map<String, String> loaded) {
        final buf = StringBuffer();
        for (final entry in loaded.entries) {
            buf.writeln('### ${entry.key}');
            buf.writeln();
            buf.writeln('```markdown');
            buf.writeln(entry.value);
            buf.writeln('```');
            buf.writeln();
        }
        return buf.toString();
    }
}
