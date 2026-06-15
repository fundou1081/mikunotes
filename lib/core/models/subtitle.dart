class SubtitleEntry {
  final int index;
  final double from;
  final double to;
  final String content;

  const SubtitleEntry({
    required this.index,
    required this.from,
    required this.to,
    required this.content,
  });
}

class VideoSubtitle {
  final String videoId;
  final String language;
  final List<SubtitleEntry> entries;

  const VideoSubtitle({
    required this.videoId,
    required this.language,
    this.entries = const [],
  });

  String get fullText => entries.map((e) => e.content).join('\n');
}
