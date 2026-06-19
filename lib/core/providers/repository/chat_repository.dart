import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/llm/llm_client.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/models/chat_message.dart' as chat_model;
import 'package:mikunotes/core/providers/providers.dart';
import 'package:mikunotes/core/storage/database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 对话子仓库 — 从 VideoRepository 拆分
class ChatRepository {
  final AppDatabase _db;

  ChatRepository(this._db);

  /// 获取一个视频的所有会话
  Future<List<ChatSession>> getChatSessions(String bvid) =>
      _db.getChatSessionsForVideo(bvid);

  /// 创建对话会话
  Future<ChatSession> createChatSession(String bvid, {String? title}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final session = ChatSession(
      id: id,
      bvid: bvid,
      title: title ?? _autoSessionTitle(),
      createdAt: now,
      lastActiveAt: now,
    );
    await _db.saveChatSession(ChatSessionsCompanion.insert(
      id: id,
      bvid: bvid,
      title: Value(title ?? _autoSessionTitle()),
      createdAt: now,
      lastActiveAt: now,
    ));
    return session;
  }

  /// 自动生成会话标题
  String _autoSessionTitle() {
    final dt = DateTime.now();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '新对话 $h:$m';
  }

  /// 删除对话会话
  Future<void> deleteChatSession(String id) => _db.deleteChatSession(id);

  /// 更新会话标题 (保留接口兼容, 实际无对应 db 方法时直接跳过)
  Future<void> updateSessionTitle(String id, String title) async {
    // Note: db.dart 没有 updateSessionTitle, 但 VideoRepository 原本也是这个签名
    // 暂时只更新 lastActiveAt 以保持行为一致
    await _db.updateChatSessionLastActive(id);
  }

  /// 获取会话的所有消息
  Future<List<ChatMessage>> getChatMessages(String sessionId) =>
      _db.getChatMessages(sessionId);

  /// 添加消息到会话
  Future<void> addChatMessage({
    required String sessionId,
    required chat_model.ChatRole role,
    required String content,
  }) async {
    await _db.saveChatMessage(ChatMessagesCompanion.insert(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: role.name,
      content: content,
      timestamp: DateTime.now(),
    ));
    await _db.updateChatSessionLastActive(sessionId);
  }

  /// 会话字符数 (用于判断是否需要压缩)
  Future<int> sessionCharCount(String sessionId) async {
    final msgs = await _db.getChatMessages(sessionId);
    return msgs.fold<int>(0, (sum, m) => sum + m.content.length);
  }

  /// 自动压缩: 超出 maxContextChars 时，将最早的几条消息用 LLM 总结成一条
  Future<bool> compressContextIfNeeded(
    String sessionId, {
    required LLMClient llmClient,
    required AIConfig config,
  }) async {
    final msgs = await _db.getChatMessages(sessionId);
    if (msgs.length < 4) return false; // 太短不压缩

    final totalChars = msgs.fold(0, (sum, m) => sum + m.content.length);
    if (totalChars <= config.maxContextChars) return false;

    final toCompress = msgs
        .where((m) => !m.isCompressed)
        .take(msgs.length ~/ 2)
        .toList();
    if (toCompress.isEmpty) return false;

    final textToCompress = toCompress
        .map((m) => '${m.role == "user" ? "用户" : "助手"}: ${m.content}')
        .join('\n');

    try {
      final disableReasoning = config.provider == LLMProvider.minimax;

      final summary = await llmClient.chat(
        systemPrompt:
            '你是一个对话历史压缩助手。请将以下对话历史压缩为简洁的要点摘要，保留关键信息：\n1. 用户的问题/需求\n2. 助手给出的重要结论/数据\n3. 任何重要的上下文\n\n用中文输出，控制在 ${config.compressTargetChars ~/ 2} 字以内。',
        userMessage: '以下是需要压缩的对话历史：\n\n$textToCompress',
        maxTokens: 1000,
        temperature: 0.2,
        disableReasoning: disableReasoning,
      );

      // 删除最早的消息
      await _db.deleteOldestMessages(sessionId, toCompress.length);
      // 添加压缩后的系统消息
      await _db.saveChatMessage(ChatMessagesCompanion.insert(
        id: _uuid.v4(),
        sessionId: sessionId,
        role: 'system',
        content: '[历史摘要] $summary',
        timestamp: DateTime.now(),
      ));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 构造发给 LLM 的对话历史 (system: 字幕, 后面: 历史消息)
  Future<List<Map<String, String>>> buildChatMessages(
    String sessionId, {
    required String transcript,
    required String systemPrompt,
  }) async {
    final msgs = await _db.getChatMessages(sessionId);
    return [
      {'role': 'system', 'content': systemPrompt},
      ...msgs.map((m) => {
            'role': m.role,
            'content': m.content,
          }),
    ];
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(databaseProvider));
});