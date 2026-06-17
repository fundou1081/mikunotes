class Video {
  final String bvid;
  final int page; // 分P (1-based, 整体时为 0, 单 P 为 1)
  final String title;
  final String coverUrl;
  final String uploader;
  final int duration;
  final int pageCount;
  final DateTime addedAt;
  final List<String> tags;
  final List<String> aiTags;

  const Video({
    required this.bvid,
    this.page = 1,
    required this.title,
    this.coverUrl = '',
    this.uploader = '',
    this.duration = 0,
    this.pageCount = 1,
    required this.addedAt,
    this.tags = const [],
    this.aiTags = const [],
  });

  /// Merged: 原始 + AI tag (去重)
  List<String> get allTags {
    final merged = <String>[...tags];
    for (final t in aiTags) {
      if (!merged.contains(t)) merged.add(t);
    }
    return merged;
  }

  /// 是否为多 P 视频
  bool get isMultiPart => pageCount > 1;

  Video copyWith({
    String? bvid,
    int? page,
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
        bvid: bvid ?? this.bvid,
        page: page ?? this.page,
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
