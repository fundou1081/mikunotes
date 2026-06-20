import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mikunotes/core/models/prompt_template.dart';

const _kStorageKey = 'prompt_templates_v1';

final templatesProvider =
    StateNotifierProvider<TemplatesNotifier, PromptTemplateSet>(
        (ref) => TemplatesNotifier());

class TemplatesNotifier extends StateNotifier<PromptTemplateSet> {
  final _storage = const FlutterSecureStorage();
  Future<void>? _loading;

  /// ⭐ 初始化时立即用 built-in 模板填充 state (避免首次点击生成时模板为空)
  TemplatesNotifier()
      : super(PromptTemplateSet(
          summaries: builtInSummaryTemplates(),
          chats: builtInChatTemplates(),
          comments: builtInCommentTemplates(),
          danmakus: builtInDanmakuTemplates(),
          activeSummaryId: 'builtin-summary-default',
          activeChatId: 'builtin-chat-default',
          activeCommentId: 'builtin-comment-community',
          activeDanmakuId: 'builtin-danmaku-highfreq',
        )) {
    _loading = _load();
  }

  /// ⭐ 确保模板已加载完成 (用于避免 race condition)
  Future<void> ensureLoaded() async {
    await _loading;
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _kStorageKey);
      if (raw == null) {
        // 首次启动: state 已经是 built-in 模板, 只需保存
        await _save();
      } else {
        // 已有用户数据: 解析并合并缺失的 built-in 模板
        final loaded = PromptTemplateSet.fromJsonString(raw);
        final summaryIds = loaded.summaries.map((t) => t.id).toSet();
        final chatIds = loaded.chats.map((t) => t.id).toSet();
        final danmakuIds = loaded.danmakus.map((t) => t.id).toSet();
        final commentIds = loaded.comments.map((t) => t.id).toSet();
        final missingSummary = builtInSummaryTemplates()
            .where((b) => !summaryIds.contains(b.id)).toList();
        final missingChat = builtInChatTemplates()
            .where((b) => !chatIds.contains(b.id)).toList();
        final missingComments = builtInCommentTemplates()
            .where((b) => !commentIds.contains(b.id)).toList();
        final missingDanmaku = builtInDanmakuTemplates()
            .where((b) => !danmakuIds.contains(b.id)).toList();
        if (missingSummary.isNotEmpty ||
            missingChat.isNotEmpty ||
            missingComments.isNotEmpty ||
            missingDanmaku.isNotEmpty) {
          state = PromptTemplateSet(
            summaries: [...loaded.summaries, ...missingSummary],
            chats: [...loaded.chats, ...missingChat],
            comments: [...loaded.comments, ...missingComments],
            danmakus: [...loaded.danmakus, ...missingDanmaku],
            activeSummaryId: loaded.activeSummaryId ?? 'builtin-summary-default',
            activeChatId: loaded.activeChatId ?? 'builtin-chat-default',
            activeCommentId: loaded.activeCommentId ?? 'builtin-comment-community',
            activeDanmakuId: loaded.activeDanmakuId ?? 'builtin-danmaku-highfreq',
          );
          await _save();
        } else {
          state = loaded;
        }
      }
    } catch (e) {
      // 加载失败: 保持 built-in 默认
      // (state 已经是 built-in, 不需额外处理)
    }
  }

  Future<void> _save() async {
    await _storage.write(key: _kStorageKey, value: state.toJsonString());
  }

  Future<PromptTemplate> addTemplate(TemplateType type, String name, String content) async {
    final t = PromptTemplate(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      content: content,
    );
    if (type == TemplateType.summary) {
      state = state.copyWith(summaries: [...state.summaries, t]);
    } else if (type == TemplateType.comment) {
      state = state.copyWith(comments: [...state.comments, t]);
    } else {
      state = state.copyWith(chats: [...state.chats, t]);
    }
    await _save();
    return t;
  }

  Future<void> updateTemplate(TemplateType type, String id, {String? name, String? content}) async {
    List<PromptTemplate> list;
    if (type == TemplateType.summary) list = state.summaries;
    else if (type == TemplateType.comment) list = state.comments;
    else list = state.chats;
    final updated = list.map((t) => t.id == id ? t.copyWith(name: name, content: content) : t).toList();
    if (type == TemplateType.summary) {
      state = state.copyWith(summaries: updated);
    } else if (type == TemplateType.comment) {
      state = state.copyWith(comments: updated);
    } else {
      state = state.copyWith(chats: updated);
    }
    await _save();
  }

  Future<void> deleteTemplate(TemplateType type, String id) async {
    List<PromptTemplate> list;
    if (type == TemplateType.summary) list = state.summaries;
    else if (type == TemplateType.comment) list = state.comments;
    else list = state.chats;
    final target = list.firstWhere((t) => t.id == id, orElse: () => const PromptTemplate(id: '', name: '', content: ''));
    if (target.id.isEmpty || target.isBuiltIn) return;
    final filtered = list.where((t) => t.id != id).toList();
    if (type == TemplateType.summary) {
      state = state.copyWith(
        summaries: filtered,
        activeSummaryId: state.activeSummaryId == id ? null : state.activeSummaryId,
      );
    } else if (type == TemplateType.comment) {
      state = state.copyWith(
        comments: filtered,
        activeCommentId: state.activeCommentId == id ? null : state.activeCommentId,
      );
    } else {
      state = state.copyWith(
        chats: filtered,
        activeChatId: state.activeChatId == id ? null : state.activeChatId,
      );
    }
    await _save();
  }

  Future<void> setActive(TemplateType type, String id) async {
    if (type == TemplateType.summary) {
      state = state.copyWith(activeSummaryId: id);
    } else if (type == TemplateType.comment) {
      state = state.copyWith(activeCommentId: id);
    } else {
      state = state.copyWith(activeChatId: id);
    }
    await _save();
  }

  PromptTemplate? getById(TemplateType type, String id) {
    List<PromptTemplate> list;
    if (type == TemplateType.summary) list = state.summaries;
    else if (type == TemplateType.comment) list = state.comments;
    else list = state.chats;
    for (final t in list) {
      if (t.id == id) return t;
    }
    return null;
  }
}