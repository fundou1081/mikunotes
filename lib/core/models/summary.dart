enum SummaryType { structured, topicExpansion, compare }

class Summary {
  final String id;
  final String videoId;
  final String title;
  final SummaryType type;
  final String content;
  final String modelUsed;
  final String promptUsed;
  final DateTime createdAt;

  const Summary({
    required this.id,
    required this.videoId,
    this.title = '',
    this.type = SummaryType.structured,
    required this.content,
    this.modelUsed = '',
    this.promptUsed = '',
    required this.createdAt,
  });
}
