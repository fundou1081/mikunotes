import 'dart:convert';
import 'package:mikunotes/core/llm/prompt_template.dart';

enum TemplateType { summary, chat }

/// 用户保存的 prompt 模板
class PromptTemplate {
  final String id;
  final String name;
  final String content;
  final bool isBuiltIn;

  const PromptTemplate({
    required this.id,
    required this.name,
    required this.content,
    this.isBuiltIn = false,
  });

  PromptTemplate copyWith({String? name, String? content}) =>
      PromptTemplate(
        id: id,
        name: name ?? this.name,
        content: content ?? this.content,
        isBuiltIn: isBuiltIn,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'isBuiltIn': isBuiltIn,
      };

  factory PromptTemplate.fromJson(Map<String, dynamic> j) => PromptTemplate(
        id: j['id'] as String,
        name: j['name'] as String,
        content: j['content'] as String,
        isBuiltIn: j['isBuiltIn'] as bool? ?? false,
      );
}

/// 内置默认模板集（首次启动时 seed 进 provider）
List<PromptTemplate> builtInSummaryTemplates() => [
      const PromptTemplate(
        id: 'builtin-summary-default',
        name: '标准结构化',
        content: defaultSummaryTemplate,
        isBuiltIn: true,
      ),
      const PromptTemplate(
        id: 'builtin-summary-tech',
        name: '技术深度',
        content: techSummaryTemplate,
        isBuiltIn: true,
      ),
      const PromptTemplate(
        id: 'builtin-summary-edu',
        name: '教育科普',
        content: eduSummaryTemplate,
        isBuiltIn: true,
      ),
      const PromptTemplate(
        id: 'builtin-summary-marketing',
        name: '营销向',
        content: marketingSummaryTemplate,
        isBuiltIn: true,
      ),
      const PromptTemplate(
        id: 'builtin-summary-podcast',
        name: '播客分析',
        content: podcastSummaryTemplate,
        isBuiltIn: true,
      ),
    ];

List<PromptTemplate> builtInChatTemplates() => [
      const PromptTemplate(
        id: 'builtin-chat-default',
        name: '默认助手',
        content: defaultChatTemplate,
        isBuiltIn: true,
      ),
      const PromptTemplate(
        id: 'builtin-chat-concise',
        name: '简洁版',
        content: conciseChatTemplate,
        isBuiltIn: true,
      ),
      const PromptTemplate(
        id: 'builtin-chat-deep',
        name: '深度分析',
        content: deepChatTemplate,
        isBuiltIn: true,
      ),
      const PromptTemplate(
        id: 'builtin-chat-teaching',
        name: '教学式',
        content: teachingChatTemplate,
        isBuiltIn: true,
      ),
    ];

/// 模板集合状态
class PromptTemplateSet {
  final List<PromptTemplate> summaries;
  final List<PromptTemplate> chats;
  final String? activeSummaryId;
  final String? activeChatId;

  const PromptTemplateSet({
    this.summaries = const [],
    this.chats = const [],
    this.activeSummaryId,
    this.activeChatId,
  });

  PromptTemplate? get activeSummary {
    if (activeSummaryId == null) return null;
    for (final t in summaries) {
      if (t.id == activeSummaryId) return t;
    }
    return null;
  }

  PromptTemplate? get activeChat {
    if (activeChatId == null) return null;
    for (final t in chats) {
      if (t.id == activeChatId) return t;
    }
    return null;
  }

  PromptTemplateSet copyWith({
    List<PromptTemplate>? summaries,
    List<PromptTemplate>? chats,
    String? activeSummaryId,
    String? activeChatId,
  }) =>
      PromptTemplateSet(
        summaries: summaries ?? this.summaries,
        chats: chats ?? this.chats,
        activeSummaryId: activeSummaryId ?? this.activeSummaryId,
        activeChatId: activeChatId ?? this.activeChatId,
      );

  Map<String, dynamic> toJson() => {
        'summaries': summaries.map((t) => t.toJson()).toList(),
        'chats': chats.map((t) => t.toJson()).toList(),
        'activeSummaryId': activeSummaryId,
        'activeChatId': activeChatId,
      };

  factory PromptTemplateSet.fromJson(Map<String, dynamic> j) =>
      PromptTemplateSet(
        summaries: (j['summaries'] as List? ?? [])
            .map((t) => PromptTemplate.fromJson(t as Map<String, dynamic>))
            .toList(),
        chats: (j['chats'] as List? ?? [])
            .map((t) => PromptTemplate.fromJson(t as Map<String, dynamic>))
            .toList(),
        activeSummaryId: j['activeSummaryId'] as String?,
        activeChatId: j['activeChatId'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());
  factory PromptTemplateSet.fromJsonString(String s) =>
      PromptTemplateSet.fromJson(jsonDecode(s) as Map<String, dynamic>);
}