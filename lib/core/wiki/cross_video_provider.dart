import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mikunotes/core/models/ai_config.dart';
import 'package:mikunotes/core/providers/providers.dart' show llmClientProvider, aiConfigProvider, databaseProvider;
import 'package:mikunotes/core/wiki/insight_storage.dart';
import 'package:mikunotes/core/storage/database.dart';

/// 跨视频洞察生成状态
class CrossVideoState {
    final bool isGenerating;
    final String content;  // 流式累积的内容
    final String? error;
    final String? insightId;  // 保存后的 ID

    const CrossVideoState({
        this.isGenerating = false,
        this.content = '',
        this.error,
        this.insightId,
    });

    CrossVideoState copyWith({
        bool? isGenerating,
        String? content,
        String? error,
        String? insightId,
        bool clearError = false,
    }) =>
        CrossVideoState(
            isGenerating: isGenerating ?? this.isGenerating,
            content: content ?? this.content,
            error: clearError ? null : (error ?? this.error),
            insightId: insightId ?? this.insightId,
        );
}

/// 跨视频洞察生成器 — 收集数据 + 调 LLM + 保存
class CrossVideoNotifier extends StateNotifier<CrossVideoState> {
    final Ref _ref;

    CrossVideoNotifier(this._ref) : super(const CrossVideoState());

    /// 收集每个视频的最新总结 + 元数据
    Future<List<({VideoGroup group, List<Summary> summaries, String uploader, String cover})>>
        _collectVideoData(List<String> bvids) async {
        final db = _ref.read(databaseProvider);
        final result = <({VideoGroup group, List<Summary> summaries, String uploader, String cover})>[];
        for (final bvid in bvids) {
            final group = await db.getVideoGroup(bvid);
            if (group == null) continue;
            final summaries = await db.getSummariesForVideo(bvid);
            result.add((
                group: group,
                summaries: summaries,
                uploader: group.uploader,
                cover: group.cover,
            ));
        }
        return result;
    }

    /// 生成跨视频洞察
    /// bvids: 选中的视频 (2+)
    /// title: 洞察标题
    /// onChunk: 实时流式回调 (用于 UI 显示进度)
    Future<String?> generate({
        required List<String> bvids,
        required String title,
        required void Function(String chunk) onChunk,
    }) async {
        if (bvids.length < 2) {
            state = state.copyWith(error: '至少选择 2 个视频', clearError: false);
            return null;
        }

        state = state.copyWith(isGenerating: true, content: '', error: null, clearError: true);

        try {
            // 1. 收集数据
            final data = await _collectVideoData(bvids);
            if (data.length < 2) {
                state = state.copyWith(isGenerating: false, error: '视频数据收集失败');
                return null;
            }

            // 2. 构造 prompt
            final prompt = _buildPrompt(data, title);

            // 3. 调 LLM (流式)
            final config = _ref.read(aiConfigProvider);
            final client = _ref.read(llmClientProvider);
            final disableReasoning = config.provider == LLMProvider.minimax;

            final buffer = StringBuffer();
            await for (final chunk in client.chatStreamWithFallback(
                systemPrompt: prompt,
                messages: const [],
                disableReasoning: disableReasoning,
            )) {
                buffer.write(chunk);
                onChunk(buffer.toString());
            }

            // 4. 保存到 insights/
            final id = _generateId(title);
            final content = _wrapAsMarkdown(
                id: id,
                title: title,
                bvids: bvids,
                body: buffer.toString(),
            );
            await _ref.read(insightStorageProvider).save(id, content);

            state = state.copyWith(
                isGenerating: false,
                content: buffer.toString(),
                insightId: id,
            );
            return id;
        } catch (e) {
            state = state.copyWith(isGenerating: false, error: '$e');
            return null;
        }
    }

    String _buildPrompt(
        List<({VideoGroup group, List<Summary> summaries, String uploader, String cover})> data,
        String title,
    ) {
        final buf = StringBuffer();
        buf.writeln('你是 MikuNotes Wiki 跨视频洞察助手。');
        buf.writeln('用户希望基于以下 ${data.length} 个视频生成深度分析。');
        buf.writeln();
        buf.writeln('## 分析主题');
        buf.writeln(title);
        buf.writeln();
        buf.writeln('## 视频材料');
        for (var i = 0; i < data.length; i++) {
            final d = data[i];
            buf.writeln('### 视频 ${i + 1}: ${d.group.title}');
            buf.writeln('- BVID: ${d.group.bvid}');
            buf.writeln('- UP 主: ${d.uploader}');
            buf.writeln('- 时长: ${d.group.totalDuration}秒');
            buf.writeln('- 标签: ${d.group.tags}');
            buf.writeln('- AI 标签: ${d.group.aiTags}');
            if (d.summaries.isNotEmpty) {
                buf.writeln();
                buf.writeln('**总结**:');
                for (final s in d.summaries) {
                    // 去掉 frontmatter
                    var content = s.content;
                    final m = RegExp(r'^---\n.*?\n---\n', dotAll: true).firstMatch(content);
                    if (m != null) content = content.substring(m.end);
                    buf.writeln(content.trim());
                    buf.writeln();
                }
            } else {
                buf.writeln();
                buf.writeln('_(暂无总结)_');
            }
            buf.writeln('---');
            buf.writeln();
        }

        buf.writeln('## 输出要求');
        buf.writeln('请按以下结构生成 Markdown 报告:');
        buf.writeln();
        buf.writeln('### 🎯 共同主题');
        buf.writeln('这些视频共同涉及的核心话题/概念是什么?');
        buf.writeln();
        buf.writeln('### 🧩 互补信息');
        buf.writeln('哪些视频讲解了不同侧面, 组合起来能形成更完整的图景?');
        buf.writeln();
        buf.writeln('### 🔄 观点演变');
        buf.writeln('如果不同视频对同一话题有不同观点, 说明差异/演进');
        buf.writeln();
        buf.writeln('### 💡 跨视频洞察');
        buf.writeln('最关键的 1-3 个 insight — 用户单独看任何一个视频都看不到的');
        buf.writeln();
        buf.writeln('### 📚 推荐学习路径');
        buf.writeln('按什么顺序看这些视频, 效率最高?');
        buf.writeln();
        buf.writeln('## 风格');
        buf.writeln('- 中文回答');
        buf.writeln('- 用 markdown 标题/列表');
        buf.writeln('- 引用具体视频时用 `[[BVxxx]]` 格式, 用户可以点击跳转');
        buf.writeln('- 简洁但信息密度高');
        buf.writeln('- 不要凭视频标题编造内容, 基于上面给的总结');
        return buf.toString();
    }

    String _wrapAsMarkdown({
        required String id,
        required String title,
        required List<String> bvids,
        required String body,
    }) {
        final buf = StringBuffer();
        buf.writeln('---');
        buf.writeln('type: insight');
        buf.writeln('id: $id');
        buf.writeln('title: "$title"');
        buf.writeln('bvids: [${bvids.join(', ')}]');
        buf.writeln('created_at: ${DateTime.now().toIso8601String()}');
        buf.writeln('---');
        buf.writeln();
        buf.writeln('# $title');
        buf.writeln();
        buf.writeln('> 涉及 ${bvids.length} 个视频: ${bvids.map((b) => '`$b`').join(', ')}');
        buf.writeln();
        buf.writeln('---');
        buf.writeln();
        buf.writeln(body);
        return buf.toString();
    }

    String _generateId(String title) {
        final ts = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '-').replaceAll('T', '_');
        final slug = title.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]+'), '_').substring(0, title.length > 30 ? 30 : title.length);
        return '${ts}_$slug';
    }

    void clear() {
        state = const CrossVideoState();
    }
}

final crossVideoProvider = StateNotifierProvider<CrossVideoNotifier, CrossVideoState>((ref) {
    return CrossVideoNotifier(ref);
});
