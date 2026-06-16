enum LLMProvider {
  deepseek('DeepSeek', 'https://api.deepseek.com', 'deepseek-v4-flash'),
  minimax('MiniMax', 'https://api.minimax.chat/v1', 'MiniMax-M2.7'),
  minimaxFree('MiniMax Free', 'https://api.minimaxi.com/v1', 'MiniMax-M2.5-Lightning'),
  ollama('Ollama Cloud', 'https://ollama.com/v1', 'gpt-oss:120b-cloud'),
  zhipu('智谱 GLM', 'https://open.bigmodel.cn/api/paas/v4', 'glm-4-flash'),
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
  final int maxContextChars;
  final int compressTargetChars;
  final String summaryTemplate;
  final String chatTemplate;

  const AIConfig({
    this.provider = LLMProvider.deepseek,
    this.baseUrl = '',
    this.apiKey = '',
    this.model = '',
    this.temperature = 0.3,
    this.maxTokens = 4096,
    this.customSystemPrompt = '',
    this.maxContextChars = 32000,
    this.compressTargetChars = 8000,
    this.summaryTemplate = '',
    this.chatTemplate = '',
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
    int? maxContextChars,
    int? compressTargetChars,
    String? summaryTemplate,
    String? chatTemplate,
  }) =>
      AIConfig(
        provider: provider ?? this.provider,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        customSystemPrompt: customSystemPrompt ?? this.customSystemPrompt,
        maxContextChars: maxContextChars ?? this.maxContextChars,
        compressTargetChars: compressTargetChars ?? this.compressTargetChars,
        summaryTemplate: summaryTemplate ?? this.summaryTemplate,
        chatTemplate: chatTemplate ?? this.chatTemplate,
      );
}
