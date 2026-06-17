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
        // 首次启动: seed 内置模板
        state = PromptTemplateSet(
          summaries: builtInSummaryTemplates(),
          chats: builtInChatTemplates(),
          activeSummaryId: 'builtin-summary-default',
          activeChatId: 'builtin-chat-default',
        );
        await _save();
      } else {
        state = PromptTemplateSet.fromJsonString(raw);
        // 兼容: 补充缺失的内置模板
        final summaryIds = state.summaries.map((t) => t.id).toSet();
        final chatIds = state.chats.map((t) => t.id).toSet();
        final missingSummary = builtInSummaryTemplates()
            .where((b) => !summaryIds.contains(b.id)).toList();
        final missingChat = builtInChatTemplates()
            .where((b) => !chatIds.contains(b.id)).toList();
        if (missingSummary.isNotEmpty || missingChat.isNotEmpty) {
          state = PromptTemplateSet(
            summaries: [...state.summaries, ...missingSummary],
            chats: [...state.chats, ...missingChat],
            activeSummaryId: state.activeSummaryId ?? 'builtin-summary-default',
            activeChatId: state.activeChatId ?? 'builtin-chat-default',
          );
          await _save();
        }
      }
    } catch (e) {
      state = PromptTemplateSet(
        summaries: builtInSummaryTemplates(),
        chats: builtInChatTemplates(),
        activeSummaryId: 'builtin-summary-default',
        activeChatId: 'builtin-chat-default',
      );
    }
  }

  Future<void> _save() async {
    await _storage.write(key: _kStorageKey, value: state.toJsonString());
  }

  /// 添加模板（用户自定义）
  Future<PromptTemplate> addTemplate(TemplateType type, String name, String content) async {
    final t = PromptTemplate(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      content: content,
    );
    if (type == TemplateType.summary) {
      state = state.copyWith(summaries: [...state.summaries, t]);
    } else {
      state = state.copyWith(chats: [...state.chats, t]);
    }
    await _save();
    return t;
  }

  /// 更新模板（不能改 isBuiltIn）
  Future<void> updateTemplate(TemplateType type, String id, {String? name, String? content}) async {
    final list = type == TemplateType.summary ? state.summaries : state.chats;
    final updated = list.map((t) => t.id == id ? t.copyWith(name: name, content: content) : t).toList();
    if (type == TemplateType.summary) {
      state = state.copyWith(summaries: updated);
    } else {
      state = state.copyWith(chats: updated);
    }
    await _save();
  }

  /// 删除模板（不能删内置）
  Future<void> deleteTemplate(TemplateType type, String id) async {
    final list = type == TemplateType.summary ? state.summaries : state.chats;
    final target = list.firstWhere((t) => t.id == id, orElse: () => const PromptTemplate(id: '', name: '', content: ''));
    if (target.id.isEmpty || target.isBuiltIn) return;
    final filtered = list.where((t) => t.id != id).toList();
    if (type == TemplateType.summary) {
      state = state.copyWith(
        summaries: filtered,
        activeSummaryId:
            state.activeSummaryId == id ? null : state.activeSummaryId,
      );
    } else {
      state = state.copyWith(
        chats: filtered,
        activeChatId: state.activeChatId == id ? null : state.activeChatId,
      );
    }
    await _save();
  }

  /// 设置激活模板
  Future<void> setActive(TemplateType type, String id) async {
    if (type == TemplateType.summary) {
      state = state.copyWith(activeSummaryId: id);
    } else {
      state = state.copyWith(activeChatId: id);
    }
    await _save();
  }

  /// 按 ID 获取模板
  PromptTemplate? getById(TemplateType type, String id) {
    final list = type == TemplateType.summary ? state.summaries : state.chats;
    for (final t in list) {
      if (t.id == id) return t;
    }
    return null;
  }
}