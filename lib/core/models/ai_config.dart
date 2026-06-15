part of 'models.dart';

/// 内置 LLM Provider 预设
enum LLMProvider {
  deepseek('DeepSeek', 'https://api.deepseek.com', 'deepseek-chat'),
  minimax('MiniMax', 'https://api.minimax.chat/v1', 'MiniMax-M2.7'),
  minimaxFree('MiniMax Free', 'https://api.minimaxi.com/v1', 'MiniMax-M2.5-Lightning'),
  zhipu('智谱 GLM', 'https://open.bigmodel.cn/api/paas/v4', 'glm-4-flash'),
  ollama('Ollama', 'http://localhost:11434/v1', ''),
  custom('自定义', '', '');

  final String label;
  final String defaultBaseUrl;
  final String defaultModel;

  const LLMProvider(this.label, this.defaultBaseUrl, this.defaultModel);
}

class AIConfig {
  final LLMProvider provider;
  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final String customSystemPrompt;

  const AIConfig({
    this.provider = LLMProvider.deepseek,
    this.baseUrl = '',
    this.apiKey = '',
    this.model = '',
    this.temperature = 0.3,
    this.maxTokens = 4096,
    this.customSystemPrompt = '',
  });

  String get effectiveBaseUrl => baseUrl.isNotEmpty ? baseUrl : provider.defaultBaseUrl;

  String get effectiveModel => model.isNotEmpty ? model : provider.defaultModel;

  AIConfig copyWith({
    LLMProvider? provider,
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    String? customSystemPrompt,
  }) =>
      AIConfig(
        provider: provider ?? this.provider,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        customSystemPrompt: customSystemPrompt ?? this.customSystemPrompt,
      );
}
