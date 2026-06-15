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
          receiveTimeout: const Duration(minutes: 3),
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
