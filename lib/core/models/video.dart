part of 'models.dart';

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
  });

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
      );
}
