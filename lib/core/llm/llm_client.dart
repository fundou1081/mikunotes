import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mikunotes/core/models/ai_config.dart';

/// 统一的 LLM 客户端，支持 OpenAI 兼容 API
class LLMClient {
  final Dio _dio;
  final AIConfig _config;

  LLMClient({required AIConfig config})
      : _config = config,
        _dio = Dio(BaseOptions(
          baseUrl: config.effectiveBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
        ));

  Future<String> chat({
    required String systemPrompt,
    required String userMessage,
    double? temperature,
    int? maxTokens,
    bool disableReasoning = false,
  }) async {
    final response = await _dio.post('/chat/completions', data: {
      'model': _config.effectiveModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': temperature ?? _config.temperature,
      'max_tokens': maxTokens ?? _config.maxTokens,
      if (disableReasoning) 'chat_template_kwargs': {'thinking': false},
    });

    return _extractContent(response.data);
  }

  Future<String> chatMultiTurn({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    bool disableReasoning = false,
    CancelToken? cancelToken,
  }) async {
    final allMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': _config.effectiveModel,
        'messages': allMessages,
        'temperature': _config.temperature,
        'max_tokens': _config.maxTokens,
        if (disableReasoning) 'chat_template_kwargs': {'thinking': false},
      },
      cancelToken: cancelToken,
    );

    return _extractContent(response.data);
  }

  /// 从响应中提取内容 - 兼容推理模型（content 为空时 fallback 到 reasoning_content）
  /// 过滤 `` 块
  String _extractContent(dynamic data) {
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) return '';
    final message = choices[0]['message'] as Map?;
    if (message == null) return '';
    var content = (message['content'] as String?) ?? '';
    if (content.isEmpty) {
      // 推理模型 fallback: content 为空时用 reasoning_content
      content = (message['reasoning_content'] as String?) ?? '';
    }
    return _stripThinkTags(content);
  }

  /// 过滤 `` 块 (用于非流式的最终结果)
  String _stripThinkTags(String text) {
    if (text.isEmpty) return text;
    // 移除 ``...`` 块
    final result = StringBuffer();
    int i = 0;
    while (i < text.length) {
      final start = text.indexOf('<think>', i);
      if (start == -1) {
        result.write(text.substring(i));
        break;
      }
      result.write(text.substring(i, start));
      final end = text.indexOf('</think>', start);
      if (end == -1) {
        // 未闭合的 ``, 丢弃后续
        break;
      }
      i = end + '</think>'.length;
    }
    return result.toString().trim();
  }

  /// 流式聊天 — 返回内容块的 Stream
  /// 智能检测: 如果响应不是 SSE 格式, 自动 fallback 到普通 chat
  /// disableReasoning: 如果为 true, 送 chat_template_kwargs.thinking=false
  ///   同时流式过程跳过 reasoning_content 字段
  Stream<String> chatStream({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    bool disableReasoning = false,
    CancelToken? cancelToken,
  }) async* {
    final allMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final headers = <String, String>{
      'Accept': 'text/event-stream',
    };
    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': _config.effectiveModel,
        'messages': allMessages,
        'temperature': _config.temperature,
        'max_tokens': _config.maxTokens,
        'stream': true,
        if (disableReasoning) 'chat_template_kwargs': {'thinking': false},
      },
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 5),
        headers: headers,
      ),
      cancelToken: cancelToken,
    );

    final stream = response.data.stream as Stream<dynamic>;
    String buffer = '';
    bool sseFormatDetected = false;
    int sseLineCount = 0;
    // 用于过滤 <think>...</think> 跨 chunk 的状态机
    final thinkFilter = _ThinkStripper();

    await for (final chunk in stream) {
      final str = utf8.decode(chunk as List<int>, allowMalformed: true);
      buffer += str;

      // 处理 SSE: 逐行解析 "data: {...}"
      while (true) {
        final newlineIdx = buffer.indexOf('\n');
        if (newlineIdx == -1) break;
        final line = buffer.substring(0, newlineIdx).trim();
        buffer = buffer.substring(newlineIdx + 1);

        if (line.isEmpty) continue;
        if (!line.startsWith('data:')) {
          // 不是 SSE 格式 (可能是普通 JSON 一次性返回)
          // 等 stream 结束后再处理
          break;
        }
        sseLineCount++;
        final data = line.substring(5).trim();
        if (data == '[DONE]') {
          sseFormatDetected = true;
          return;
        }

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          sseFormatDetected = true;
          final choices = json['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map?;
            if (delta != null) {
              final content = delta['content'] as String?;
              if (content != null && content.isNotEmpty) {
                // 过滤 <think>...</think> 块
                final filtered = thinkFilter.feed(content);
                if (filtered.isNotEmpty) yield filtered;
              }
            }
          }
        } catch (_) {
          // 忽略解析失败的行 (有些 server 会发 heartbeat)
        }
      }
    }

    // 走到这里说明 stream 结束了但没收到 [DONE]
    if (!sseFormatDetected) {
      // 不是 SSE 格式 — 整个 buffer 是普通 JSON
      try {
        final json = jsonDecode(buffer) as Map<String, dynamic>;
        final choices = json['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map?;
          if (message != null) {
            final content = message['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          }
        }
      } catch (_) {
        // 真解析不出来
      }
    }
  }

  /// 流式但带 fallback — 优先用 stream，失败用普通 chat
  Stream<String> chatStreamWithFallback({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    bool disableReasoning = false,
    CancelToken? cancelToken,
  }) async* {
    final allChunks = <String>[];
    var hasError = false;
    try {
      await for (final chunk in chatStream(
        systemPrompt: systemPrompt,
        messages: messages,
        disableReasoning: disableReasoning,
        cancelToken: cancelToken,
      )) {
        allChunks.add(chunk);
        yield chunk;
      }
    } catch (e) {
      hasError = true;
    }

    // 如果流式没产出任何 chunk 或出错, fallback 到普通 chat
    if (hasError || allChunks.isEmpty) {
      if (cancelToken?.isCancelled == true) return; // 取消后不 fallback
      final full = await chatMultiTurn(
        systemPrompt: systemPrompt,
        messages: messages,
        disableReasoning: disableReasoning,
        cancelToken: cancelToken,
      );
      yield full;
    }
  }

  /// 估算字符数对应的 token 数 (粗估)
  static int estimateTokens(String text) {
    return (text.length / 2).ceil();
  }

  /// 测试连接 - 返回详细诊断信息
  Future<String> testConnection() async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': _config.effectiveModel,
          'messages': [
            {'role': 'user', 'content': 'Reply OK only'},
          ],
          'max_tokens': 10,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data as Map?;
        final choices = data?['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final msg = choices[0]['message'] as Map?;
          final content = msg?['content'] as String? ?? '';
          final model = data?['model'] as String? ?? '?';
          if (content.trim().isNotEmpty) {
            return '✅ 连接成功\n模型: $model\n响应: ${content.trim().substring(0, content.trim().length < 40 ? content.trim().length : 40)}';
          }
          // content 为空，检查是否是推理模型
          final reasoning = msg?['reasoning_content'] as String? ?? '';
          if (reasoning.isNotEmpty) {
            return '⚠️ 推理模型 ($model)\ncontent 为空，reasoning 有内容\n建议开启 disableReasoning';
          }
        }
        return '✅ HTTP 200\n但响应内容为空（model: ${data?['model'] ?? '?'})';
      }
      return '⚠️ HTTP ${response.statusCode}';
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) {
        return '❌ 401: API Key 无效';
      } else if (code == 403) {
        return '❌ 403: 权限不足';
      } else if (code == 404) {
        return '❌ 404: 模型不存在 (${_config.effectiveModel})';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        return '❌ 连接超时: 检查 Base URL';
      } else {
        return '❌ 失败: ${code ?? ""} ${e.message ?? ""}';
      }
    }
  }
}

/// 流式 `` 块过滤器
/// - 状态机: NORMAL ↔ IN_THINK
/// - 处理跨 chunk 的部分标签 (`` 分成两半到达)
class _ThinkStripper {
  bool _inThink = false;
  String _carry = '';  // 保存尾部可能是标签前缀的内容

  static const String _openTag = '<think>';
  static const String _closeTag = '</think>';

  /// 喂入一段 chunk, 返回过滤后的可输出文本
  String feed(String chunk) {
    final text = _carry + chunk;
    _carry = '';
    final out = StringBuffer();
    int i = 0;
    final n = text.length;

    while (i < n) {
      if (!_inThink) {
        // 找 ``
        final tagIdx = _findComplete(text, _openTag, i);
        if (tagIdx == -1) {
          // 没找到完整 ``. 检查尾部是不是 `` 的部分前缀
          final partialLen = _partialPrefixLen(text, _openTag, i);
          if (partialLen > 0) {
            out.write(text.substring(i, n - partialLen));
            _carry = text.substring(n - partialLen);
          } else {
            out.write(text.substring(i));
          }
          return out.toString();
        }
        out.write(text.substring(i, tagIdx));
        i = tagIdx + _openTag.length;
        _inThink = true;
      } else {
        // 找 ``
        final tagIdx = _findComplete(text, _closeTag, i);
        if (tagIdx == -1) {
          // 保留尾部可能是 `` 部分前缀的内容
          final partialLen = _partialPrefixLen(text, _closeTag, i);
          if (partialLen > 0) {
            _carry = text.substring(n - partialLen);
          }
          // 其余全部丢弃 (think 内容)
          return out.toString();
        }
        i = tagIdx + _closeTag.length;
        _inThink = false;
      }
    }
    return out.toString();
  }

  /// 找 `tag` 在 text 中从 from 开始的位置 (完整匹配)
  int _findComplete(String text, String tag, int from) {
    final start = from;
    final end = text.length - tag.length + 1;
    for (int i = start; i < end; i++) {
      bool match = true;
      for (int j = 0; j < tag.length; j++) {
        if (text.codeUnitAt(i + j) != tag.codeUnitAt(j)) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  /// 检查 text 末尾是不是 `tag` 的部分前缀, 返回匹配的长度
  int _partialPrefixLen(String text, String tag, int from) {
    final n = text.length;
    if (n <= from) return 0;
    final maxCheck = tag.length - 1;
    for (int len = maxCheck; len >= 1; len--) {
      if (n - len < from) continue;
      bool match = true;
      for (int j = 0; j < len; j++) {
        if (text.codeUnitAt(n - len + j) != tag.codeUnitAt(j)) {
          match = false;
          break;
        }
      }
      if (match) return len;
    }
    return 0;
  }

  /// 流结束时的 flush (处理最后可能没闭合的 think)
  String flush() {
    if (_inThink) {
      _inThink = false;
    }
    final rem = _carry;
    _carry = '';
    return rem;
  }
}
