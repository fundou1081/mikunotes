/// Prompt 模板引擎 — 支持 {{变量名}} 占位符
class PromptTemplate {
  /// 可用变量
  static const availableVariables = {
    'video_title': '视频标题',
    'bvid': 'B站 BV号',
    'subtitle': '字幕原文',
    'subtitle_truncated': '字幕原文（超过 12000 字自动截断）',
    'language': '字幕语言（如 "中文"）',
    'uploader': 'UP主名称',
    'duration': '视频时长（秒）',
    'page_count': '分P数',
  };

  /// 渲染模板：将 {{变量名}} 替换为实际值
  static String render(String template, Map<String, String> vars) {
    String result = template;
    for (final entry in vars.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  /// 检查模板中使用了哪些变量
  static Set<String> usedVariables(String template) {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    return regex.allMatches(template).map((m) => m.group(1)!).toSet();
  }

  /// 验证模板：返回未知变量列表
  static List<String> validate(String template) {
    final used = usedVariables(template);
    return used.where((v) => !availableVariables.containsKey(v)).toList();
  }
}

// ─── 预设模板 ──────────────────────────────────────────────────

/// 默认总结模板
const defaultSummaryTemplate = '''你是B站视频内容总结助手。请严格按照以下格式输出结构化总结：

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
- 板块间用 --- 分隔

视频标题: {{video_title}}
字幕语言: {{language}}
UP主: {{uploader}}

{{subtitle_truncated}}''';

/// 默认对话模板
const defaultChatTemplate = '''你是视频内容问答助手。基于以下字幕内容回答用户问题。
如果问题超出字幕范围，明确告知用户。

视频标题: {{video_title}}
视频链接: https://www.bilibili.com/video/{{bvid}}

字幕内容:
{{subtitle}}''';

/// 摘要模板：技术深度
const techSummaryTemplate = '''你是资深技术分析师。请从技术角度对以下B站视频内容进行深度总结：

## 🔬 技术主题
本视频涉及的主要技术领域、原理与实现路径。

## 🛠️ 关键技术点
列举 3-5 个技术细节、架构决策或算法，并说明它们解决了什么问题。

## 💻 代码/配置片段
如果有代码、配置、API 调用示例，提取并简要说明作用。

## ⚖️ 权衡与限制
作者在设计/实现中做的权衡，存在哪些限制。

## 🚀 进阶建议
基于视频内容给出延伸学习方向或实践建议。

视频标题: {{video_title}}
{{subtitle_truncated}}''';

/// 摘要模板：教育科普
const eduSummaryTemplate = '''你是一位善于科普的老师。请将以下B站视频内容用通俗易懂的方式总结给初学者：

## 📚 这是什么？
用三句话解释视频主题是什么。

## 🎯 为什么重要？
这个主题能解决什么问题、为什么值得关注。

## 🧩 拆解步骤
把视频中的核心论述拆成 3-5 个递进步骤讲解。

## 🌰 例子
用日常生活中的例子类比视频中的抽象概念。

## 📖 补充阅读
推荐 1-2 个入门资源。

视频标题: {{video_title}}
{{subtitle_truncated}}''';

/// 摘要模板：营销向
const marketingSummaryTemplate = '''你是内容运营专家。请为以下B站视频写一份“适合转发”的总结：

## 🎬 一句话卖点
15 字以内，说明视频为什么值得看。

## ✨ 三个亮点
列出 3 个最抓人、最有传播力的亮点。

## 🗣️ 金句
提取 3-5 句值得转发的原话。

## 🏷️ 推荐标签
#标签1 #标签2 #标签3 ...

视频标题: {{video_title}}
{{subtitle_truncated}}''';

/// 对话模板：简洁版
const conciseChatTemplate = '''你是视频助手。基于以下字幕，用 1-2 句话简洁回答用户问题。不超过 100 字。

字幕：{{subtitle_truncated}}

问题：{{video_title}} - 用户询问''';

/// 对话模板：深度分析
const deepChatTemplate = '''你是资深分析师。基于以下字幕对用户问题做深度分析。

请从以下角度展开：
- 事实/原理（是什么）
- 原因/机制（为什么）
- 启示/应用（怎么做）
- 反例/限制（什么场景不适用）

字幕：
{{subtitle}}

视频：{{video_title}} - 用户询问''';

/// 对话模板：教学式
const teachingChatTemplate = '''你是一位耐心的老师。请用以下结构回答用户关于视频内容的问题：

1. 先确认理解了用户的问题
2. 给出基础解释（从字幕中提取）
3. 用类比帮助理解
4. 如果字幕中没提到，明确告知

字幕：
{{subtitle}}''';
