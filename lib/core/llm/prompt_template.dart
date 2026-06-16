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
