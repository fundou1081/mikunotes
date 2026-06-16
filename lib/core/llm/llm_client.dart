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
  }) async {
    final response = await _dio.post('/chat/completions', data: {
      'model': _config.effectiveModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': temperature ?? _config.temperature,
      'max_tokens': maxTokens ?? _config.maxTokens,
    });

    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<String> chatMultiTurn({
    required String systemPrompt,
    required List<Map<String, String>> messages,
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
    });

    return response.data['choices'][0]['message']['content'] as String;
  }

  /// 流式聊天 — 返回内容块的 Stream
  /// 智能检测: 如果响应不是 SSE 格式, 自动 fallback 到普通 chat
  Stream<String> chatStream({
    required String systemPrompt,
    required List<Map<String, String>> messages,
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
  }) async* {
    final allChunks = <String>[];
    var hasError = false;
    try {
      await for (final chunk in chatStream(
        systemPrompt: systemPrompt,
        messages: messages,
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
      );
      yield full;
    }
  }

  /// 估算字符数对应的 token 数 (粗估)
  static int estimateTokens(String text) {
    return (text.length / 2).ceil();
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': _config.effectiveModel,
          'messages': [
            {'role': 'user', 'content': 'ping'},
          ],
          'max_tokens': 5,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
