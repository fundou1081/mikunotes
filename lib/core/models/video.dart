class Video {
  final String id;
  final String bvid;
  final String title;
  final String coverUrl;
  final String uploader;
  final int duration;
  final int pageCount;
  final DateTime addedAt;
  final List<String> tags;
  final List<String> aiTags;

  const Video({
    required this.id,
    required this.bvid,
    required this.title,
    this.coverUrl = '',
    this.uploader = '',
    this.duration = 0,
    this.pageCount = 1,
    required this.addedAt,
    this.tags = const [],
    this.aiTags = const [],
  });

  /// Merged: original + AI tags (deduped)
  List<String> get allTags {
    final merged = <String>[...tags];
    for (final t in aiTags) {
      if (!merged.contains(t)) merged.add(t);
    }
    return merged;
  }

  Video copyWith({
    String? id,
    String? bvid,
    String? title,
    String? coverUrl,
    String? uploader,
    int? duration,
    int? pageCount,
    DateTime? addedAt,
    List<String>? tags,
    List<String>? aiTags,
  }) =>
      Video(
        id: id ?? this.id,
        bvid: bvid ?? this.bvid,
        title: title ?? this.title,
        coverUrl: coverUrl ?? this.coverUrl,
        uploader: uploader ?? this.uploader,
        duration: duration ?? this.duration,
        pageCount: pageCount ?? this.pageCount,
        addedAt: addedAt ?? this.addedAt,
        tags: tags ?? this.tags,
        aiTags: aiTags ?? this.aiTags,
      );
}
