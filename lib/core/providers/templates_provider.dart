import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mikunotes/core/models/prompt_template.dart';

const _kStorageKey = 'prompt_templates_v1';

final templatesProvider =
    StateNotifierProvider<TemplatesNotifier, PromptTemplateSet>(
        (ref) => TemplatesNotifier());

class TemplatesNotifier extends StateNotifier<PromptTemplateSet> {
  final _storage = const FlutterSecureStorage();

  TemplatesNotifier() : super(const PromptTemplateSet()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _kStorageKey);
      if (raw == null) {
        state = PromptTemplateSet(
          summaries: builtInSummaryTemplates(),
          chats: builtInChatTemplates(),
          comments: builtInCommentTemplates(),
          activeSummaryId: 'builtin-summary-default',
          activeChatId: 'builtin-chat-default',
          activeCommentId: 'builtin-comment-community',
        );
        await _save();
      } else {
        state = PromptTemplateSet.fromJsonString(raw);
        final summaryIds = state.summaries.map((t) => t.id).toSet();
        final chatIds = state.chats.map((t) => t.id).toSet();
        final commentIds = state.comments.map((t) => t.id).toSet();
        final missingSummary = builtInSummaryTemplates()
            .where((b) => !summaryIds.contains(b.id)).toList();
        final missingChat = builtInChatTemplates()
            .where((b) => !chatIds.contains(b.id)).toList();
        final missingComments = builtInCommentTemplates()
            .where((b) => !commentIds.contains(b.id)).toList();
        if (missingSummary.isNotEmpty ||
            missingChat.isNotEmpty ||
            missingComments.isNotEmpty) {
          state = PromptTemplateSet(
            summaries: [...state.summaries, ...missingSummary],
            chats: [...state.chats, ...missingChat],
            comments: [...state.comments, ...missingComments],
            activeSummaryId: state.activeSummaryId ?? 'builtin-summary-default',
            activeChatId: state.activeChatId ?? 'builtin-chat-default',
            activeCommentId: state.activeCommentId ?? 'builtin-comment-community',
          );
          await _save();
        }
      }
    } catch (e) {
      state = PromptTemplateSet(
        summaries: builtInSummaryTemplates(),
        chats: builtInChatTemplates(),
        comments: builtInCommentTemplates(),
        activeSummaryId: 'builtin-summary-default',
        activeChatId: 'builtin-chat-default',
        activeCommentId: 'builtin-comment-community',
      );
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