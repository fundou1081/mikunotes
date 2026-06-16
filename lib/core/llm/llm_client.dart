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
  }) async {
    final allMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final response = await _dio.post('/chat/completions', data: {
      'model': _config.effectiveModel,
      'messages': allMessages,
      'temperature': _config.temperature,
      'max_tokens': _config.maxTokens,
      if (disableReasoning) 'chat_template_kwargs': {'thinking': false},
    });

    return _extractContent(response.data);
  }

  /// 从响应中提取内容 - 兼容推理模型（content 为空时 fallback 到 reasoning_content）
  String _extractContent(dynamic data) {
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) return '';
    final message = choices[0]['message'] as Map?;
    if (message == null) return '';
    final content = (message['content'] as String?) ?? '';
    if (content.isNotEmpty) return content;
    // 推理模型 fallback: content 为空时用 reasoning_content
    final reasoning = (message['reasoning_content'] as String?) ?? '';
    return reasoning;
  }

  /// 流式聊天 — 返回内容块的 Stream
  /// 智能检测: 如果响应不是 SSE 格式, 自动 fallback 到普通 chat
  /// disableReasoning: 如果为 true, 送 chat_template_kwargs.thinking=false
  ///   同时流式过程跳过 reasoning_content 字段
  Stream<String> chatStream({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    bool disableReasoning = false,
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
    );

    final stream = response.data.stream as Stream<dynamic>;
    String buffer = '';
    bool sseFormatDetected = false;
    int sseLineCount = 0;

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
                yield content;
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
  }) async* {
    final allChunks = <String>[];
    var hasError = false;
    try {
      await for (final chunk in chatStream(
        systemPrompt: systemPrompt,
        messages: messages,
        disableReasoning: disableReasoning,
      )) {
        allChunks.add(chunk);
        yield chunk;
      }
    } catch (e) {
      hasError = true;
    }

    // 如果流式没产出任何 chunk 或出错, fallback 到普通 chat
    if (hasError || allChunks.isEmpty) {
      final full = await chatMultiTurn(
        systemPrompt: systemPrompt,
        messages: messages,
        disableReasoning: disableReasoning,
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
