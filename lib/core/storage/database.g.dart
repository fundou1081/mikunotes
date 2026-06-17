// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $VideoGroupsTable extends VideoGroups
    with TableInfo<$VideoGroupsTable, VideoGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideoGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
      'bvid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
      'cover', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _uploaderMeta =
      const VerificationMeta('uploader');
  @override
  late final GeneratedColumn<String> uploader = GeneratedColumn<String>(
      'uploader', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _upMidMeta = const VerificationMeta('upMid');
  @override
  late final GeneratedColumn<int> upMid = GeneratedColumn<int>(
      'up_mid', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _upFaceMeta = const VerificationMeta('upFace');
  @override
  late final GeneratedColumn<String> upFace = GeneratedColumn<String>(
      'up_face', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _totalDurationMeta =
      const VerificationMeta('totalDuration');
  @override
  late final GeneratedColumn<int> totalDuration = GeneratedColumn<int>(
      'total_duration', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _pageCountMeta =
      const VerificationMeta('pageCount');
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
      'page_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _pageNamesJsonMeta =
      const VerificationMeta('pageNamesJson');
  @override
  late final GeneratedColumn<String> pageNamesJson = GeneratedColumn<String>(
      'page_names_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _aiTagsMeta = const VerificationMeta('aiTags');
  @override
  late final GeneratedColumn<String> aiTags = GeneratedColumn<String>(
      'ai_tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        bvid,
        title,
        cover,
        uploader,
        upMid,
        upFace,
        totalDuration,
        pageCount,
        pageNamesJson,
        addedAt,
        tags,
        aiTags
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'video_groups';
  @override
  VerificationContext validateIntegrity(Insertable<VideoGroup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bvid')) {
      context.handle(
          _bvidMeta, bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta));
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover')) {
      context.handle(
          _coverMeta, cover.isAcceptableOrUnknown(data['cover']!, _coverMeta));
    }
    if (data.containsKey('uploader')) {
      context.handle(_uploaderMeta,
          uploader.isAcceptableOrUnknown(data['uploader']!, _uploaderMeta));
    }
    if (data.containsKey('up_mid')) {
      context.handle(
          _upMidMeta, upMid.isAcceptableOrUnknown(data['up_mid']!, _upMidMeta));
    }
    if (data.containsKey('up_face')) {
      context.handle(_upFaceMeta,
          upFace.isAcceptableOrUnknown(data['up_face']!, _upFaceMeta));
    }
    if (data.containsKey('total_duration')) {
      context.handle(
          _totalDurationMeta,
          totalDuration.isAcceptableOrUnknown(
              data['total_duration']!, _totalDurationMeta));
    }
    if (data.containsKey('page_count')) {
      context.handle(_pageCountMeta,
          pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta));
    }
    if (data.containsKey('page_names_json')) {
      context.handle(
          _pageNamesJsonMeta,
          pageNamesJson.isAcceptableOrUnknown(
              data['page_names_json']!, _pageNamesJsonMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('ai_tags')) {
      context.handle(_aiTagsMeta,
          aiTags.isAcceptableOrUnknown(data['ai_tags']!, _aiTagsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bvid};
  @override
  VideoGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VideoGroup(
      bvid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bvid'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      cover: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover'])!,
      uploader: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uploader'])!,
      upMid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}up_mid'])!,
      upFace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}up_face'])!,
      totalDuration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_duration'])!,
      pageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_count'])!,
      pageNamesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}page_names_json'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      aiTags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_tags'])!,
    );
  }

  @override
  $VideoGroupsTable createAlias(String alias) {
    return $VideoGroupsTable(attachedDatabase, alias);
  }
}

class VideoGroup extends DataClass implements Insertable<VideoGroup> {
  final String bvid;
  final String title;
  final String cover;
  final String uploader;
  final int upMid;
  final String upFace;
  final int totalDuration;
  final int pageCount;
  final String pageNamesJson;
  final DateTime addedAt;
  final String tags;
  final String aiTags;
  const VideoGroup(
      {required this.bvid,
      required this.title,
      required this.cover,
      required this.uploader,
      required this.upMid,
      required this.upFace,
      required this.totalDuration,
      required this.pageCount,
      required this.pageNamesJson,
      required this.addedAt,
      required this.tags,
      required this.aiTags});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bvid'] = Variable<String>(bvid);
    map['title'] = Variable<String>(title);
    map['cover'] = Variable<String>(cover);
    map['uploader'] = Variable<String>(uploader);
    map['up_mid'] = Variable<int>(upMid);
    map['up_face'] = Variable<String>(upFace);
    map['total_duration'] = Variable<int>(totalDuration);
    map['page_count'] = Variable<int>(pageCount);
    map['page_names_json'] = Variable<String>(pageNamesJson);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['tags'] = Variable<String>(tags);
    map['ai_tags'] = Variable<String>(aiTags);
    return map;
  }

  VideoGroupsCompanion toCompanion(bool nullToAbsent) {
    return VideoGroupsCompanion(
      bvid: Value(bvid),
      title: Value(title),
      cover: Value(cover),
      uploader: Value(uploader),
      upMid: Value(upMid),
      upFace: Value(upFace),
      totalDuration: Value(totalDuration),
      pageCount: Value(pageCount),
      pageNamesJson: Value(pageNamesJson),
      addedAt: Value(addedAt),
      tags: Value(tags),
      aiTags: Value(aiTags),
    );
  }

  factory VideoGroup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VideoGroup(
      bvid: serializer.fromJson<String>(json['bvid']),
      title: serializer.fromJson<String>(json['title']),
      cover: serializer.fromJson<String>(json['cover']),
      uploader: serializer.fromJson<String>(json['uploader']),
      upMid: serializer.fromJson<int>(json['upMid']),
      upFace: serializer.fromJson<String>(json['upFace']),
      totalDuration: serializer.fromJson<int>(json['totalDuration']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      pageNamesJson: serializer.fromJson<String>(json['pageNamesJson']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      tags: serializer.fromJson<String>(json['tags']),
      aiTags: serializer.fromJson<String>(json['aiTags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bvid': serializer.toJson<String>(bvid),
      'title': serializer.toJson<String>(title),
      'cover': serializer.toJson<String>(cover),
      'uploader': serializer.toJson<String>(uploader),
      'upMid': serializer.toJson<int>(upMid),
      'upFace': serializer.toJson<String>(upFace),
      'totalDuration': serializer.toJson<int>(totalDuration),
      'pageCount': serializer.toJson<int>(pageCount),
      'pageNamesJson': serializer.toJson<String>(pageNamesJson),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'tags': serializer.toJson<String>(tags),
      'aiTags': serializer.toJson<String>(aiTags),
    };
  }

  VideoGroup copyWith(
          {String? bvid,
          String? title,
          String? cover,
          String? uploader,
          int? upMid,
          String? upFace,
          int? totalDuration,
          int? pageCount,
          String? pageNamesJson,
          DateTime? addedAt,
          String? tags,
          String? aiTags}) =>
      VideoGroup(
        bvid: bvid ?? this.bvid,
        title: title ?? this.title,
        cover: cover ?? this.cover,
        uploader: uploader ?? this.uploader,
        upMid: upMid ?? this.upMid,
        upFace: upFace ?? this.upFace,
        totalDuration: totalDuration ?? this.totalDuration,
        pageCount: pageCount ?? this.pageCount,
        pageNamesJson: pageNamesJson ?? this.pageNamesJson,
        addedAt: addedAt ?? this.addedAt,
        tags: tags ?? this.tags,
        aiTags: aiTags ?? this.aiTags,
      );
  VideoGroup copyWithCompanion(VideoGroupsCompanion data) {
    return VideoGroup(
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      title: data.title.present ? data.title.value : this.title,
      cover: data.cover.present ? data.cover.value : this.cover,
      uploader: data.uploader.present ? data.uploader.value : this.uploader,
      upMid: data.upMid.present ? data.upMid.value : this.upMid,
      upFace: data.upFace.present ? data.upFace.value : this.upFace,
      totalDuration: data.totalDuration.present
          ? data.totalDuration.value
          : this.totalDuration,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      pageNamesJson: data.pageNamesJson.present
          ? data.pageNamesJson.value
          : this.pageNamesJson,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      tags: data.tags.present ? data.tags.value : this.tags,
      aiTags: data.aiTags.present ? data.aiTags.value : this.aiTags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VideoGroup(')
          ..write('bvid: $bvid, ')
          ..write('title: $title, ')
          ..write('cover: $cover, ')
          ..write('uploader: $uploader, ')
          ..write('upMid: $upMid, ')
          ..write('upFace: $upFace, ')
          ..write('totalDuration: $totalDuration, ')
          ..write('pageCount: $pageCount, ')
          ..write('pageNamesJson: $pageNamesJson, ')
          ..write('addedAt: $addedAt, ')
          ..write('tags: $tags, ')
          ..write('aiTags: $aiTags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bvid, title, cover, uploader, upMid, upFace,
      totalDuration, pageCount, pageNamesJson, addedAt, tags, aiTags);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoGroup &&
          other.bvid == this.bvid &&
          other.title == this.title &&
          other.cover == this.cover &&
          other.uploader == this.uploader &&
          other.upMid == this.upMid &&
          other.upFace == this.upFace &&
          other.totalDuration == this.totalDuration &&
          other.pageCount == this.pageCount &&
          other.pageNamesJson == this.pageNamesJson &&
          other.addedAt == this.addedAt &&
          other.tags == this.tags &&
          other.aiTags == this.aiTags);
}

class VideoGroupsCompanion extends UpdateCompanion<VideoGroup> {
  final Value<String> bvid;
  final Value<String> title;
  final Value<String> cover;
  final Value<String> uploader;
  final Value<int> upMid;
  final Value<String> upFace;
  final Value<int> totalDuration;
  final Value<int> pageCount;
  final Value<String> pageNamesJson;
  final Value<DateTime> addedAt;
  final Value<String> tags;
  final Value<String> aiTags;
  final Value<int> rowid;
  const VideoGroupsCompanion({
    this.bvid = const Value.absent(),
    this.title = const Value.absent(),
    this.cover = const Value.absent(),
    this.uploader = const Value.absent(),
    this.upMid = const Value.absent(),
    this.upFace = const Value.absent(),
    this.totalDuration = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.pageNamesJson = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.aiTags = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VideoGroupsCompanion.insert({
    required String bvid,
    required String title,
    this.cover = const Value.absent(),
    this.uploader = const Value.absent(),
    this.upMid = const Value.absent(),
    this.upFace = const Value.absent(),
    this.totalDuration = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.pageNamesJson = const Value.absent(),
    required DateTime addedAt,
    this.tags = const Value.absent(),
    this.aiTags = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : bvid = Value(bvid),
        title = Value(title),
        addedAt = Value(addedAt);
  static Insertable<VideoGroup> custom({
    Expression<String>? bvid,
    Expression<String>? title,
    Expression<String>? cover,
    Expression<String>? uploader,
    Expression<int>? upMid,
    Expression<String>? upFace,
    Expression<int>? totalDuration,
    Expression<int>? pageCount,
    Expression<String>? pageNamesJson,
    Expression<DateTime>? addedAt,
    Expression<String>? tags,
    Expression<String>? aiTags,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bvid != null) 'bvid': bvid,
      if (title != null) 'title': title,
      if (cover != null) 'cover': cover,
      if (uploader != null) 'uploader': uploader,
      if (upMid != null) 'up_mid': upMid,
      if (upFace != null) 'up_face': upFace,
      if (totalDuration != null) 'total_duration': totalDuration,
      if (pageCount != null) 'page_count': pageCount,
      if (pageNamesJson != null) 'page_names_json': pageNamesJson,
      if (addedAt != null) 'added_at': addedAt,
      if (tags != null) 'tags': tags,
      if (aiTags != null) 'ai_tags': aiTags,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VideoGroupsCompanion copyWith(
      {Value<String>? bvid,
      Value<String>? title,
      Value<String>? cover,
      Value<String>? uploader,
      Value<int>? upMid,
      Value<String>? upFace,
      Value<int>? totalDuration,
      Value<int>? pageCount,
      Value<String>? pageNamesJson,
      Value<DateTime>? addedAt,
      Value<String>? tags,
      Value<String>? aiTags,
      Value<int>? rowid}) {
    return VideoGroupsCompanion(
      bvid: bvid ?? this.bvid,
      title: title ?? this.title,
      cover: cover ?? this.cover,
      uploader: uploader ?? this.uploader,
      upMid: upMid ?? this.upMid,
      upFace: upFace ?? this.upFace,
      totalDuration: totalDuration ?? this.totalDuration,
      pageCount: pageCount ?? this.pageCount,
      pageNamesJson: pageNamesJson ?? this.pageNamesJson,
      addedAt: addedAt ?? this.addedAt,
      tags: tags ?? this.tags,
      aiTags: aiTags ?? this.aiTags,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (uploader.present) {
      map['uploader'] = Variable<String>(uploader.value);
    }
    if (upMid.present) {
      map['up_mid'] = Variable<int>(upMid.value);
    }
    if (upFace.present) {
      map['up_face'] = Variable<String>(upFace.value);
    }
    if (totalDuration.present) {
      map['total_duration'] = Variable<int>(totalDuration.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (pageNamesJson.present) {
      map['page_names_json'] = Variable<String>(pageNamesJson.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (aiTags.present) {
      map['ai_tags'] = Variable<String>(aiTags.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideoGroupsCompanion(')
          ..write('bvid: $bvid, ')
          ..write('title: $title, ')
          ..write('cover: $cover, ')
          ..write('uploader: $uploader, ')
          ..write('upMid: $upMid, ')
          ..write('upFace: $upFace, ')
          ..write('totalDuration: $totalDuration, ')
          ..write('pageCount: $pageCount, ')
          ..write('pageNamesJson: $pageNamesJson, ')
          ..write('addedAt: $addedAt, ')
          ..write('tags: $tags, ')
          ..write('aiTags: $aiTags, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VideosTable extends Videos with TableInfo<$VideosTable, Video> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
      'bvid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
      'page', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _aidMeta = const VerificationMeta('aid');
  @override
  late final GeneratedColumn<int> aid = GeneratedColumn<int>(
      'aid', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _cidMeta = const VerificationMeta('cid');
  @override
  late final GeneratedColumn<int> cid = GeneratedColumn<int>(
      'cid', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _partNameMeta =
      const VerificationMeta('partName');
  @override
  late final GeneratedColumn<String> partName = GeneratedColumn<String>(
      'part_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _partTitleMeta =
      const VerificationMeta('partTitle');
  @override
  late final GeneratedColumn<String> partTitle = GeneratedColumn<String>(
      'part_title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _partCoverMeta =
      const VerificationMeta('partCover');
  @override
  late final GeneratedColumn<String> partCover = GeneratedColumn<String>(
      'part_cover', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [bvid, page, aid, cid, partName, partTitle, partCover, duration, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'videos';
  @override
  VerificationContext validateIntegrity(Insertable<Video> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bvid')) {
      context.handle(
          _bvidMeta, bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta));
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
          _pageMeta, page.isAcceptableOrUnknown(data['page']!, _pageMeta));
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('aid')) {
      context.handle(
          _aidMeta, aid.isAcceptableOrUnknown(data['aid']!, _aidMeta));
    } else if (isInserting) {
      context.missing(_aidMeta);
    }
    if (data.containsKey('cid')) {
      context.handle(
          _cidMeta, cid.isAcceptableOrUnknown(data['cid']!, _cidMeta));
    }
    if (data.containsKey('part_name')) {
      context.handle(_partNameMeta,
          partName.isAcceptableOrUnknown(data['part_name']!, _partNameMeta));
    }
    if (data.containsKey('part_title')) {
      context.handle(_partTitleMeta,
          partTitle.isAcceptableOrUnknown(data['part_title']!, _partTitleMeta));
    }
    if (data.containsKey('part_cover')) {
      context.handle(_partCoverMeta,
          partCover.isAcceptableOrUnknown(data['part_cover']!, _partCoverMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bvid, page};
  @override
  Video map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Video(
      bvid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bvid'])!,
      page: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page'])!,
      aid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}aid'])!,
      cid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cid'])!,
      partName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}part_name'])!,
      partTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}part_title'])!,
      partCover: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}part_cover'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $VideosTable createAlias(String alias) {
    return $VideosTable(attachedDatabase, alias);
  }
}

class Video extends DataClass implements Insertable<Video> {
  final String bvid;
  final int page;
  final int aid;
  final int cid;
  final String partName;
  final String partTitle;
  final String partCover;
  final int duration;
  final DateTime addedAt;
  const Video(
      {required this.bvid,
      required this.page,
      required this.aid,
      required this.cid,
      required this.partName,
      required this.partTitle,
      required this.partCover,
      required this.duration,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bvid'] = Variable<String>(bvid);
    map['page'] = Variable<int>(page);
    map['aid'] = Variable<int>(aid);
    map['cid'] = Variable<int>(cid);
    map['part_name'] = Variable<String>(partName);
    map['part_title'] = Variable<String>(partTitle);
    map['part_cover'] = Variable<String>(partCover);
    map['duration'] = Variable<int>(duration);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  VideosCompanion toCompanion(bool nullToAbsent) {
    return VideosCompanion(
      bvid: Value(bvid),
      page: Value(page),
      aid: Value(aid),
      cid: Value(cid),
      partName: Value(partName),
      partTitle: Value(partTitle),
      partCover: Value(partCover),
      duration: Value(duration),
      addedAt: Value(addedAt),
    );
  }

  factory Video.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Video(
      bvid: serializer.fromJson<String>(json['bvid']),
      page: serializer.fromJson<int>(json['page']),
      aid: serializer.fromJson<int>(json['aid']),
      cid: serializer.fromJson<int>(json['cid']),
      partName: serializer.fromJson<String>(json['partName']),
      partTitle: serializer.fromJson<String>(json['partTitle']),
      partCover: serializer.fromJson<String>(json['partCover']),
      duration: serializer.fromJson<int>(json['duration']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bvid': serializer.toJson<String>(bvid),
      'page': serializer.toJson<int>(page),
      'aid': serializer.toJson<int>(aid),
      'cid': serializer.toJson<int>(cid),
      'partName': serializer.toJson<String>(partName),
      'partTitle': serializer.toJson<String>(partTitle),
      'partCover': serializer.toJson<String>(partCover),
      'duration': serializer.toJson<int>(duration),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Video copyWith(
          {String? bvid,
          int? page,
          int? aid,
          int? cid,
          String? partName,
          String? partTitle,
          String? partCover,
          int? duration,
          DateTime? addedAt}) =>
      Video(
        bvid: bvid ?? this.bvid,
        page: page ?? this.page,
        aid: aid ?? this.aid,
        cid: cid ?? this.cid,
        partName: partName ?? this.partName,
        partTitle: partTitle ?? this.partTitle,
        partCover: partCover ?? this.partCover,
        duration: duration ?? this.duration,
        addedAt: addedAt ?? this.addedAt,
      );
  Video copyWithCompanion(VideosCompanion data) {
    return Video(
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      page: data.page.present ? data.page.value : this.page,
      aid: data.aid.present ? data.aid.value : this.aid,
      cid: data.cid.present ? data.cid.value : this.cid,
      partName: data.partName.present ? data.partName.value : this.partName,
      partTitle: data.partTitle.present ? data.partTitle.value : this.partTitle,
      partCover: data.partCover.present ? data.partCover.value : this.partCover,
      duration: data.duration.present ? data.duration.value : this.duration,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Video(')
          ..write('bvid: $bvid, ')
          ..write('page: $page, ')
          ..write('aid: $aid, ')
          ..write('cid: $cid, ')
          ..write('partName: $partName, ')
          ..write('partTitle: $partTitle, ')
          ..write('partCover: $partCover, ')
          ..write('duration: $duration, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      bvid, page, aid, cid, partName, partTitle, partCover, duration, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Video &&
          other.bvid == this.bvid &&
          other.page == this.page &&
          other.aid == this.aid &&
          other.cid == this.cid &&
          other.partName == this.partName &&
          other.partTitle == this.partTitle &&
          other.partCover == this.partCover &&
          other.duration == this.duration &&
          other.addedAt == this.addedAt);
}

class VideosCompanion extends UpdateCompanion<Video> {
  final Value<String> bvid;
  final Value<int> page;
  final Value<int> aid;
  final Value<int> cid;
  final Value<String> partName;
  final Value<String> partTitle;
  final Value<String> partCover;
  final Value<int> duration;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const VideosCompanion({
    this.bvid = const Value.absent(),
    this.page = const Value.absent(),
    this.aid = const Value.absent(),
    this.cid = const Value.absent(),
    this.partName = const Value.absent(),
    this.partTitle = const Value.absent(),
    this.partCover = const Value.absent(),
    this.duration = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VideosCompanion.insert({
    required String bvid,
    required int page,
    required int aid,
    this.cid = const Value.absent(),
    this.partName = const Value.absent(),
    this.partTitle = const Value.absent(),
    this.partCover = const Value.absent(),
    this.duration = const Value.absent(),
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  })  : bvid = Value(bvid),
        page = Value(page),
        aid = Value(aid),
        addedAt = Value(addedAt);
  static Insertable<Video> custom({
    Expression<String>? bvid,
    Expression<int>? page,
    Expression<int>? aid,
    Expression<int>? cid,
    Expression<String>? partName,
    Expression<String>? partTitle,
    Expression<String>? partCover,
    Expression<int>? duration,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bvid != null) 'bvid': bvid,
      if (page != null) 'page': page,
      if (aid != null) 'aid': aid,
      if (cid != null) 'cid': cid,
      if (partName != null) 'part_name': partName,
      if (partTitle != null) 'part_title': partTitle,
      if (partCover != null) 'part_cover': partCover,
      if (duration != null) 'duration': duration,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VideosCompanion copyWith(
      {Value<String>? bvid,
      Value<int>? page,
      Value<int>? aid,
      Value<int>? cid,
      Value<String>? partName,
      Value<String>? partTitle,
      Value<String>? partCover,
      Value<int>? duration,
      Value<DateTime>? addedAt,
      Value<int>? rowid}) {
    return VideosCompanion(
      bvid: bvid ?? this.bvid,
      page: page ?? this.page,
      aid: aid ?? this.aid,
      cid: cid ?? this.cid,
      partName: partName ?? this.partName,
      partTitle: partTitle ?? this.partTitle,
      partCover: partCover ?? this.partCover,
      duration: duration ?? this.duration,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (aid.present) {
      map['aid'] = Variable<int>(aid.value);
    }
    if (cid.present) {
      map['cid'] = Variable<int>(cid.value);
    }
    if (partName.present) {
      map['part_name'] = Variable<String>(partName.value);
    }
    if (partTitle.present) {
      map['part_title'] = Variable<String>(partTitle.value);
    }
    if (partCover.present) {
      map['part_cover'] = Variable<String>(partCover.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideosCompanion(')
          ..write('bvid: $bvid, ')
          ..write('page: $page, ')
          ..write('aid: $aid, ')
          ..write('cid: $cid, ')
          ..write('partName: $partName, ')
          ..write('partTitle: $partTitle, ')
          ..write('partCover: $partCover, ')
          ..write('duration: $duration, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UpMastersTable extends UpMasters
    with TableInfo<$UpMastersTable, UpMaster> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UpMastersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
      'uid', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _faceMeta = const VerificationMeta('face');
  @override
  late final GeneratedColumn<String> face = GeneratedColumn<String>(
      'face', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _lastVideoAidMeta =
      const VerificationMeta('lastVideoAid');
  @override
  late final GeneratedColumn<int> lastVideoAid = GeneratedColumn<int>(
      'last_video_aid', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _containerIdMeta =
      const VerificationMeta('containerId');
  @override
  late final GeneratedColumn<int> containerId = GeneratedColumn<int>(
      'container_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, uid, name, face, lastVideoAid, lastSyncedAt, containerId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'up_masters';
  @override
  VerificationContext validateIntegrity(Insertable<UpMaster> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('face')) {
      context.handle(
          _faceMeta, face.isAcceptableOrUnknown(data['face']!, _faceMeta));
    }
    if (data.containsKey('last_video_aid')) {
      context.handle(
          _lastVideoAidMeta,
          lastVideoAid.isAcceptableOrUnknown(
              data['last_video_aid']!, _lastVideoAidMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('container_id')) {
      context.handle(
          _containerIdMeta,
          containerId.isAcceptableOrUnknown(
              data['container_id']!, _containerIdMeta));
    } else if (isInserting) {
      context.missing(_containerIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UpMaster map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UpMaster(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      face: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}face'])!,
      lastVideoAid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_video_aid']),
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      containerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}container_id'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $UpMastersTable createAlias(String alias) {
    return $UpMastersTable(attachedDatabase, alias);
  }
}

class UpMaster extends DataClass implements Insertable<UpMaster> {
  final int id;
  final int uid;
  final String name;
  final String face;
  final int? lastVideoAid;
  final DateTime? lastSyncedAt;
  final int containerId;
  final DateTime addedAt;
  const UpMaster(
      {required this.id,
      required this.uid,
      required this.name,
      required this.face,
      this.lastVideoAid,
      this.lastSyncedAt,
      required this.containerId,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<int>(uid);
    map['name'] = Variable<String>(name);
    map['face'] = Variable<String>(face);
    if (!nullToAbsent || lastVideoAid != null) {
      map['last_video_aid'] = Variable<int>(lastVideoAid);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['container_id'] = Variable<int>(containerId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  UpMastersCompanion toCompanion(bool nullToAbsent) {
    return UpMastersCompanion(
      id: Value(id),
      uid: Value(uid),
      name: Value(name),
      face: Value(face),
      lastVideoAid: lastVideoAid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVideoAid),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      containerId: Value(containerId),
      addedAt: Value(addedAt),
    );
  }

  factory UpMaster.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UpMaster(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<int>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      face: serializer.fromJson<String>(json['face']),
      lastVideoAid: serializer.fromJson<int?>(json['lastVideoAid']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      containerId: serializer.fromJson<int>(json['containerId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<int>(uid),
      'name': serializer.toJson<String>(name),
      'face': serializer.toJson<String>(face),
      'lastVideoAid': serializer.toJson<int?>(lastVideoAid),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'containerId': serializer.toJson<int>(containerId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  UpMaster copyWith(
          {int? id,
          int? uid,
          String? name,
          String? face,
          Value<int?> lastVideoAid = const Value.absent(),
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          int? containerId,
          DateTime? addedAt}) =>
      UpMaster(
        id: id ?? this.id,
        uid: uid ?? this.uid,
        name: name ?? this.name,
        face: face ?? this.face,
        lastVideoAid:
            lastVideoAid.present ? lastVideoAid.value : this.lastVideoAid,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        containerId: containerId ?? this.containerId,
        addedAt: addedAt ?? this.addedAt,
      );
  UpMaster copyWithCompanion(UpMastersCompanion data) {
    return UpMaster(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      face: data.face.present ? data.face.value : this.face,
      lastVideoAid: data.lastVideoAid.present
          ? data.lastVideoAid.value
          : this.lastVideoAid,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      containerId:
          data.containerId.present ? data.containerId.value : this.containerId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UpMaster(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('face: $face, ')
          ..write('lastVideoAid: $lastVideoAid, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('containerId: $containerId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, uid, name, face, lastVideoAid, lastSyncedAt, containerId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UpMaster &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.face == this.face &&
          other.lastVideoAid == this.lastVideoAid &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.containerId == this.containerId &&
          other.addedAt == this.addedAt);
}

class UpMastersCompanion extends UpdateCompanion<UpMaster> {
  final Value<int> id;
  final Value<int> uid;
  final Value<String> name;
  final Value<String> face;
  final Value<int?> lastVideoAid;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> containerId;
  final Value<DateTime> addedAt;
  const UpMastersCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.face = const Value.absent(),
    this.lastVideoAid = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.containerId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  UpMastersCompanion.insert({
    this.id = const Value.absent(),
    required int uid,
    required String name,
    this.face = const Value.absent(),
    this.lastVideoAid = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required int containerId,
    required DateTime addedAt,
  })  : uid = Value(uid),
        name = Value(name),
        containerId = Value(containerId),
        addedAt = Value(addedAt);
  static Insertable<UpMaster> custom({
    Expression<int>? id,
    Expression<int>? uid,
    Expression<String>? name,
    Expression<String>? face,
    Expression<int>? lastVideoAid,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? containerId,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (face != null) 'face': face,
      if (lastVideoAid != null) 'last_video_aid': lastVideoAid,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (containerId != null) 'container_id': containerId,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  UpMastersCompanion copyWith(
      {Value<int>? id,
      Value<int>? uid,
      Value<String>? name,
      Value<String>? face,
      Value<int?>? lastVideoAid,
      Value<DateTime?>? lastSyncedAt,
      Value<int>? containerId,
      Value<DateTime>? addedAt}) {
    return UpMastersCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      face: face ?? this.face,
      lastVideoAid: lastVideoAid ?? this.lastVideoAid,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      containerId: containerId ?? this.containerId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (face.present) {
      map['face'] = Variable<String>(face.value);
    }
    if (lastVideoAid.present) {
      map['last_video_aid'] = Variable<int>(lastVideoAid.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (containerId.present) {
      map['container_id'] = Variable<int>(containerId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UpMastersCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('face: $face, ')
          ..write('lastVideoAid: $lastVideoAid, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('containerId: $containerId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $SubtitlesTable extends Subtitles
    with TableInfo<$SubtitlesTable, Subtitle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtitlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
      'bvid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
      'page', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rawJsonMeta =
      const VerificationMeta('rawJson');
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
      'raw_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _plainTextMeta =
      const VerificationMeta('plainText');
  @override
  late final GeneratedColumn<String> plainText = GeneratedColumn<String>(
      'plain_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _charCountMeta =
      const VerificationMeta('charCount');
  @override
  late final GeneratedColumn<int> charCount = GeneratedColumn<int>(
      'char_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _entryCountMeta =
      const VerificationMeta('entryCount');
  @override
  late final GeneratedColumn<int> entryCount = GeneratedColumn<int>(
      'entry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        bvid,
        page,
        language,
        rawJson,
        plainText,
        charCount,
        entryCount,
        downloadedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtitles';
  @override
  VerificationContext validateIntegrity(Insertable<Subtitle> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bvid')) {
      context.handle(
          _bvidMeta, bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta));
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
          _pageMeta, page.isAcceptableOrUnknown(data['page']!, _pageMeta));
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('raw_json')) {
      context.handle(_rawJsonMeta,
          rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta));
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('plain_text')) {
      context.handle(_plainTextMeta,
          plainText.isAcceptableOrUnknown(data['plain_text']!, _plainTextMeta));
    } else if (isInserting) {
      context.missing(_plainTextMeta);
    }
    if (data.containsKey('char_count')) {
      context.handle(_charCountMeta,
          charCount.isAcceptableOrUnknown(data['char_count']!, _charCountMeta));
    }
    if (data.containsKey('entry_count')) {
      context.handle(
          _entryCountMeta,
          entryCount.isAcceptableOrUnknown(
              data['entry_count']!, _entryCountMeta));
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {bvid, page, language},
      ];
  @override
  Subtitle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subtitle(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      bvid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bvid'])!,
      page: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      rawJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_json'])!,
      plainText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plain_text'])!,
      charCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}char_count'])!,
      entryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entry_count'])!,
      downloadedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}downloaded_at'])!,
    );
  }

  @override
  $SubtitlesTable createAlias(String alias) {
    return $SubtitlesTable(attachedDatabase, alias);
  }
}

class Subtitle extends DataClass implements Insertable<Subtitle> {
  final int id;
  final String bvid;
  final int page;
  final String language;
  final String rawJson;
  final String plainText;
  final int charCount;
  final int entryCount;
  final DateTime downloadedAt;
  const Subtitle(
      {required this.id,
      required this.bvid,
      required this.page,
      required this.language,
      required this.rawJson,
      required this.plainText,
      required this.charCount,
      required this.entryCount,
      required this.downloadedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bvid'] = Variable<String>(bvid);
    map['page'] = Variable<int>(page);
    map['language'] = Variable<String>(language);
    map['raw_json'] = Variable<String>(rawJson);
    map['plain_text'] = Variable<String>(plainText);
    map['char_count'] = Variable<int>(charCount);
    map['entry_count'] = Variable<int>(entryCount);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  SubtitlesCompanion toCompanion(bool nullToAbsent) {
    return SubtitlesCompanion(
      id: Value(id),
      bvid: Value(bvid),
      page: Value(page),
      language: Value(language),
      rawJson: Value(rawJson),
      plainText: Value(plainText),
      charCount: Value(charCount),
      entryCount: Value(entryCount),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory Subtitle.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subtitle(
      id: serializer.fromJson<int>(json['id']),
      bvid: serializer.fromJson<String>(json['bvid']),
      page: serializer.fromJson<int>(json['page']),
      language: serializer.fromJson<String>(json['language']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      plainText: serializer.fromJson<String>(json['plainText']),
      charCount: serializer.fromJson<int>(json['charCount']),
      entryCount: serializer.fromJson<int>(json['entryCount']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bvid': serializer.toJson<String>(bvid),
      'page': serializer.toJson<int>(page),
      'language': serializer.toJson<String>(language),
      'rawJson': serializer.toJson<String>(rawJson),
      'plainText': serializer.toJson<String>(plainText),
      'charCount': serializer.toJson<int>(charCount),
      'entryCount': serializer.toJson<int>(entryCount),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  Subtitle copyWith(
          {int? id,
          String? bvid,
          int? page,
          String? language,
          String? rawJson,
          String? plainText,
          int? charCount,
          int? entryCount,
          DateTime? downloadedAt}) =>
      Subtitle(
        id: id ?? this.id,
        bvid: bvid ?? this.bvid,
        page: page ?? this.page,
        language: language ?? this.language,
        rawJson: rawJson ?? this.rawJson,
        plainText: plainText ?? this.plainText,
        charCount: charCount ?? this.charCount,
        entryCount: entryCount ?? this.entryCount,
        downloadedAt: downloadedAt ?? this.downloadedAt,
      );
  Subtitle copyWithCompanion(SubtitlesCompanion data) {
    return Subtitle(
      id: data.id.present ? data.id.value : this.id,
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      page: data.page.present ? data.page.value : this.page,
      language: data.language.present ? data.language.value : this.language,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
      charCount: data.charCount.present ? data.charCount.value : this.charCount,
      entryCount:
          data.entryCount.present ? data.entryCount.value : this.entryCount,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subtitle(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('page: $page, ')
          ..write('language: $language, ')
          ..write('rawJson: $rawJson, ')
          ..write('plainText: $plainText, ')
          ..write('charCount: $charCount, ')
          ..write('entryCount: $entryCount, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bvid, page, language, rawJson, plainText,
      charCount, entryCount, downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subtitle &&
          other.id == this.id &&
          other.bvid == this.bvid &&
          other.page == this.page &&
          other.language == this.language &&
          other.rawJson == this.rawJson &&
          other.plainText == this.plainText &&
          other.charCount == this.charCount &&
          other.entryCount == this.entryCount &&
          other.downloadedAt == this.downloadedAt);
}

class SubtitlesCompanion extends UpdateCompanion<Subtitle> {
  final Value<int> id;
  final Value<String> bvid;
  final Value<int> page;
  final Value<String> language;
  final Value<String> rawJson;
  final Value<String> plainText;
  final Value<int> charCount;
  final Value<int> entryCount;
  final Value<DateTime> downloadedAt;
  const SubtitlesCompanion({
    this.id = const Value.absent(),
    this.bvid = const Value.absent(),
    this.page = const Value.absent(),
    this.language = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.plainText = const Value.absent(),
    this.charCount = const Value.absent(),
    this.entryCount = const Value.absent(),
    this.downloadedAt = const Value.absent(),
  });
  SubtitlesCompanion.insert({
    this.id = const Value.absent(),
    required String bvid,
    this.page = const Value.absent(),
    required String language,
    required String rawJson,
    required String plainText,
    this.charCount = const Value.absent(),
    this.entryCount = const Value.absent(),
    required DateTime downloadedAt,
  })  : bvid = Value(bvid),
        language = Value(language),
        rawJson = Value(rawJson),
        plainText = Value(plainText),
        downloadedAt = Value(downloadedAt);
  static Insertable<Subtitle> custom({
    Expression<int>? id,
    Expression<String>? bvid,
    Expression<int>? page,
    Expression<String>? language,
    Expression<String>? rawJson,
    Expression<String>? plainText,
    Expression<int>? charCount,
    Expression<int>? entryCount,
    Expression<DateTime>? downloadedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bvid != null) 'bvid': bvid,
      if (page != null) 'page': page,
      if (language != null) 'language': language,
      if (rawJson != null) 'raw_json': rawJson,
      if (plainText != null) 'plain_text': plainText,
      if (charCount != null) 'char_count': charCount,
      if (entryCount != null) 'entry_count': entryCount,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
    });
  }

  SubtitlesCompanion copyWith(
      {Value<int>? id,
      Value<String>? bvid,
      Value<int>? page,
      Value<String>? language,
      Value<String>? rawJson,
      Value<String>? plainText,
      Value<int>? charCount,
      Value<int>? entryCount,
      Value<DateTime>? downloadedAt}) {
    return SubtitlesCompanion(
      id: id ?? this.id,
      bvid: bvid ?? this.bvid,
      page: page ?? this.page,
      language: language ?? this.language,
      rawJson: rawJson ?? this.rawJson,
      plainText: plainText ?? this.plainText,
      charCount: charCount ?? this.charCount,
      entryCount: entryCount ?? this.entryCount,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (plainText.present) {
      map['plain_text'] = Variable<String>(plainText.value);
    }
    if (charCount.present) {
      map['char_count'] = Variable<int>(charCount.value);
    }
    if (entryCount.present) {
      map['entry_count'] = Variable<int>(entryCount.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubtitlesCompanion(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('page: $page, ')
          ..write('language: $language, ')
          ..write('rawJson: $rawJson, ')
          ..write('plainText: $plainText, ')
          ..write('charCount: $charCount, ')
          ..write('entryCount: $entryCount, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }
}

class $SummariesTable extends Summaries
    with TableInfo<$SummariesTable, Summary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
      'bvid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
      'page', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelUsedMeta =
      const VerificationMeta('modelUsed');
  @override
  late final GeneratedColumn<String> modelUsed = GeneratedColumn<String>(
      'model_used', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _promptUsedMeta =
      const VerificationMeta('promptUsed');
  @override
  late final GeneratedColumn<String> promptUsed = GeneratedColumn<String>(
      'prompt_used', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _targetTopicMeta =
      const VerificationMeta('targetTopic');
  @override
  late final GeneratedColumn<String> targetTopic = GeneratedColumn<String>(
      'target_topic', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        bvid,
        page,
        title,
        type,
        content,
        modelUsed,
        promptUsed,
        targetTopic,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'summaries';
  @override
  VerificationContext validateIntegrity(Insertable<Summary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bvid')) {
      context.handle(
          _bvidMeta, bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta));
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
          _pageMeta, page.isAcceptableOrUnknown(data['page']!, _pageMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('model_used')) {
      context.handle(_modelUsedMeta,
          modelUsed.isAcceptableOrUnknown(data['model_used']!, _modelUsedMeta));
    }
    if (data.containsKey('prompt_used')) {
      context.handle(
          _promptUsedMeta,
          promptUsed.isAcceptableOrUnknown(
              data['prompt_used']!, _promptUsedMeta));
    }
    if (data.containsKey('target_topic')) {
      context.handle(
          _targetTopicMeta,
          targetTopic.isAcceptableOrUnknown(
              data['target_topic']!, _targetTopicMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Summary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Summary(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bvid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bvid'])!,
      page: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      modelUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_used'])!,
      promptUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt_used'])!,
      targetTopic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_topic'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SummariesTable createAlias(String alias) {
    return $SummariesTable(attachedDatabase, alias);
  }
}

class Summary extends DataClass implements Insertable<Summary> {
  final String id;
  final String bvid;
  final int page;
  final String title;
  final String type;
  final String content;
  final String modelUsed;
  final String promptUsed;
  final String targetTopic;
  final DateTime createdAt;
  const Summary(
      {required this.id,
      required this.bvid,
      required this.page,
      required this.title,
      required this.type,
      required this.content,
      required this.modelUsed,
      required this.promptUsed,
      required this.targetTopic,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bvid'] = Variable<String>(bvid);
    map['page'] = Variable<int>(page);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['content'] = Variable<String>(content);
    map['model_used'] = Variable<String>(modelUsed);
    map['prompt_used'] = Variable<String>(promptUsed);
    map['target_topic'] = Variable<String>(targetTopic);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SummariesCompanion toCompanion(bool nullToAbsent) {
    return SummariesCompanion(
      id: Value(id),
      bvid: Value(bvid),
      page: Value(page),
      title: Value(title),
      type: Value(type),
      content: Value(content),
      modelUsed: Value(modelUsed),
      promptUsed: Value(promptUsed),
      targetTopic: Value(targetTopic),
      createdAt: Value(createdAt),
    );
  }

  factory Summary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Summary(
      id: serializer.fromJson<String>(json['id']),
      bvid: serializer.fromJson<String>(json['bvid']),
      page: serializer.fromJson<int>(json['page']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String>(json['content']),
      modelUsed: serializer.fromJson<String>(json['modelUsed']),
      promptUsed: serializer.fromJson<String>(json['promptUsed']),
      targetTopic: serializer.fromJson<String>(json['targetTopic']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bvid': serializer.toJson<String>(bvid),
      'page': serializer.toJson<int>(page),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String>(content),
      'modelUsed': serializer.toJson<String>(modelUsed),
      'promptUsed': serializer.toJson<String>(promptUsed),
      'targetTopic': serializer.toJson<String>(targetTopic),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Summary copyWith(
          {String? id,
          String? bvid,
          int? page,
          String? title,
          String? type,
          String? content,
          String? modelUsed,
          String? promptUsed,
          String? targetTopic,
          DateTime? createdAt}) =>
      Summary(
        id: id ?? this.id,
        bvid: bvid ?? this.bvid,
        page: page ?? this.page,
        title: title ?? this.title,
        type: type ?? this.type,
        content: content ?? this.content,
        modelUsed: modelUsed ?? this.modelUsed,
        promptUsed: promptUsed ?? this.promptUsed,
        targetTopic: targetTopic ?? this.targetTopic,
        createdAt: createdAt ?? this.createdAt,
      );
  Summary copyWithCompanion(SummariesCompanion data) {
    return Summary(
      id: data.id.present ? data.id.value : this.id,
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      page: data.page.present ? data.page.value : this.page,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      modelUsed: data.modelUsed.present ? data.modelUsed.value : this.modelUsed,
      promptUsed:
          data.promptUsed.present ? data.promptUsed.value : this.promptUsed,
      targetTopic:
          data.targetTopic.present ? data.targetTopic.value : this.targetTopic,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Summary(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('page: $page, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('modelUsed: $modelUsed, ')
          ..write('promptUsed: $promptUsed, ')
          ..write('targetTopic: $targetTopic, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bvid, page, title, type, content,
      modelUsed, promptUsed, targetTopic, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Summary &&
          other.id == this.id &&
          other.bvid == this.bvid &&
          other.page == this.page &&
          other.title == this.title &&
          other.type == this.type &&
          other.content == this.content &&
          other.modelUsed == this.modelUsed &&
          other.promptUsed == this.promptUsed &&
          other.targetTopic == this.targetTopic &&
          other.createdAt == this.createdAt);
}

class SummariesCompanion extends UpdateCompanion<Summary> {
  final Value<String> id;
  final Value<String> bvid;
  final Value<int> page;
  final Value<String> title;
  final Value<String> type;
  final Value<String> content;
  final Value<String> modelUsed;
  final Value<String> promptUsed;
  final Value<String> targetTopic;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SummariesCompanion({
    this.id = const Value.absent(),
    this.bvid = const Value.absent(),
    this.page = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.modelUsed = const Value.absent(),
    this.promptUsed = const Value.absent(),
    this.targetTopic = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SummariesCompanion.insert({
    required String id,
    required String bvid,
    this.page = const Value.absent(),
    this.title = const Value.absent(),
    required String type,
    required String content,
    this.modelUsed = const Value.absent(),
    this.promptUsed = const Value.absent(),
    this.targetTopic = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bvid = Value(bvid),
        type = Value(type),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<Summary> custom({
    Expression<String>? id,
    Expression<String>? bvid,
    Expression<int>? page,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? content,
    Expression<String>? modelUsed,
    Expression<String>? promptUsed,
    Expression<String>? targetTopic,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bvid != null) 'bvid': bvid,
      if (page != null) 'page': page,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (modelUsed != null) 'model_used': modelUsed,
      if (promptUsed != null) 'prompt_used': promptUsed,
      if (targetTopic != null) 'target_topic': targetTopic,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SummariesCompanion copyWith(
      {Value<String>? id,
      Value<String>? bvid,
      Value<int>? page,
      Value<String>? title,
      Value<String>? type,
      Value<String>? content,
      Value<String>? modelUsed,
      Value<String>? promptUsed,
      Value<String>? targetTopic,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SummariesCompanion(
      id: id ?? this.id,
      bvid: bvid ?? this.bvid,
      page: page ?? this.page,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      modelUsed: modelUsed ?? this.modelUsed,
      promptUsed: promptUsed ?? this.promptUsed,
      targetTopic: targetTopic ?? this.targetTopic,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (modelUsed.present) {
      map['model_used'] = Variable<String>(modelUsed.value);
    }
    if (promptUsed.present) {
      map['prompt_used'] = Variable<String>(promptUsed.value);
    }
    if (targetTopic.present) {
      map['target_topic'] = Variable<String>(targetTopic.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SummariesCompanion(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('page: $page, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('modelUsed: $modelUsed, ')
          ..write('promptUsed: $promptUsed, ')
          ..write('targetTopic: $targetTopic, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatSessionsTable extends ChatSessions
    with TableInfo<$ChatSessionsTable, ChatSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
      'bvid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('新对话'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastActiveAtMeta =
      const VerificationMeta('lastActiveAt');
  @override
  late final GeneratedColumn<DateTime> lastActiveAt = GeneratedColumn<DateTime>(
      'last_active_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, bvid, title, createdAt, lastActiveAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<ChatSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bvid')) {
      context.handle(
          _bvidMeta, bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta));
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_active_at')) {
      context.handle(
          _lastActiveAtMeta,
          lastActiveAt.isAcceptableOrUnknown(
              data['last_active_at']!, _lastActiveAtMeta));
    } else if (isInserting) {
      context.missing(_lastActiveAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bvid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bvid'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastActiveAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_active_at'])!,
    );
  }

  @override
  $ChatSessionsTable createAlias(String alias) {
    return $ChatSessionsTable(attachedDatabase, alias);
  }
}

class ChatSession extends DataClass implements Insertable<ChatSession> {
  final String id;
  final String bvid;
  final String title;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  const ChatSession(
      {required this.id,
      required this.bvid,
      required this.title,
      required this.createdAt,
      required this.lastActiveAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bvid'] = Variable<String>(bvid);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_active_at'] = Variable<DateTime>(lastActiveAt);
    return map;
  }

  ChatSessionsCompanion toCompanion(bool nullToAbsent) {
    return ChatSessionsCompanion(
      id: Value(id),
      bvid: Value(bvid),
      title: Value(title),
      createdAt: Value(createdAt),
      lastActiveAt: Value(lastActiveAt),
    );
  }

  factory ChatSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatSession(
      id: serializer.fromJson<String>(json['id']),
      bvid: serializer.fromJson<String>(json['bvid']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastActiveAt: serializer.fromJson<DateTime>(json['lastActiveAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bvid': serializer.toJson<String>(bvid),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastActiveAt': serializer.toJson<DateTime>(lastActiveAt),
    };
  }

  ChatSession copyWith(
          {String? id,
          String? bvid,
          String? title,
          DateTime? createdAt,
          DateTime? lastActiveAt}) =>
      ChatSession(
        id: id ?? this.id,
        bvid: bvid ?? this.bvid,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      );
  ChatSession copyWithCompanion(ChatSessionsCompanion data) {
    return ChatSession(
      id: data.id.present ? data.id.value : this.id,
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastActiveAt: data.lastActiveAt.present
          ? data.lastActiveAt.value
          : this.lastActiveAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatSession(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActiveAt: $lastActiveAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bvid, title, createdAt, lastActiveAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSession &&
          other.id == this.id &&
          other.bvid == this.bvid &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.lastActiveAt == this.lastActiveAt);
}

class ChatSessionsCompanion extends UpdateCompanion<ChatSession> {
  final Value<String> id;
  final Value<String> bvid;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastActiveAt;
  final Value<int> rowid;
  const ChatSessionsCompanion({
    this.id = const Value.absent(),
    this.bvid = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastActiveAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatSessionsCompanion.insert({
    required String id,
    required String bvid,
    this.title = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastActiveAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bvid = Value(bvid),
        createdAt = Value(createdAt),
        lastActiveAt = Value(lastActiveAt);
  static Insertable<ChatSession> custom({
    Expression<String>? id,
    Expression<String>? bvid,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastActiveAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bvid != null) 'bvid': bvid,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (lastActiveAt != null) 'last_active_at': lastActiveAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? bvid,
      Value<String>? title,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastActiveAt,
      Value<int>? rowid}) {
    return ChatSessionsCompanion(
      id: id ?? this.id,
      bvid: bvid ?? this.bvid,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastActiveAt.present) {
      map['last_active_at'] = Variable<DateTime>(lastActiveAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionsCompanion(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActiveAt: $lastActiveAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isCompressedMeta =
      const VerificationMeta('isCompressed');
  @override
  late final GeneratedColumn<bool> isCompressed = GeneratedColumn<bool>(
      'is_compressed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_compressed" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionId, role, content, timestamp, isCompressed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(Insertable<ChatMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_compressed')) {
      context.handle(
          _isCompressedMeta,
          isCompressed.isAcceptableOrUnknown(
              data['is_compressed']!, _isCompressedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      isCompressed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_compressed'])!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isCompressed;
  const ChatMessage(
      {required this.id,
      required this.sessionId,
      required this.role,
      required this.content,
      required this.timestamp,
      required this.isCompressed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_compressed'] = Variable<bool>(isCompressed);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      role: Value(role),
      content: Value(content),
      timestamp: Value(timestamp),
      isCompressed: Value(isCompressed),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isCompressed: serializer.fromJson<bool>(json['isCompressed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isCompressed': serializer.toJson<bool>(isCompressed),
    };
  }

  ChatMessage copyWith(
          {String? id,
          String? sessionId,
          String? role,
          String? content,
          DateTime? timestamp,
          bool? isCompressed}) =>
      ChatMessage(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        role: role ?? this.role,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        isCompressed: isCompressed ?? this.isCompressed,
      );
  ChatMessage copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessage(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isCompressed: data.isCompressed.present
          ? data.isCompressed.value
          : this.isCompressed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('isCompressed: $isCompressed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, role, content, timestamp, isCompressed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.role == this.role &&
          other.content == this.content &&
          other.timestamp == this.timestamp &&
          other.isCompressed == this.isCompressed);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> timestamp;
  final Value<bool> isCompressed;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isCompressed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String sessionId,
    required String role,
    required String content,
    required DateTime timestamp,
    this.isCompressed = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        role = Value(role),
        content = Value(content),
        timestamp = Value(timestamp);
  static Insertable<ChatMessage> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? timestamp,
    Expression<bool>? isCompressed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (isCompressed != null) 'is_compressed': isCompressed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<String>? role,
      Value<String>? content,
      Value<DateTime>? timestamp,
      Value<bool>? isCompressed,
      Value<int>? rowid}) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isCompressed: isCompressed ?? this.isCompressed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isCompressed.present) {
      map['is_compressed'] = Variable<bool>(isCompressed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('isCompressed: $isCompressed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContainersTable extends Containers
    with TableInfo<$ContainersTable, Container> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContainersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _externalIdMeta =
      const VerificationMeta('externalId');
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
      'external_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalCountMeta =
      const VerificationMeta('totalCount');
  @override
  late final GeneratedColumn<int> totalCount = GeneratedColumn<int>(
      'total_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, externalId, name, totalCount, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'containers';
  @override
  VerificationContext validateIntegrity(Insertable<Container> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
          _externalIdMeta,
          externalId.isAcceptableOrUnknown(
              data['external_id']!, _externalIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('total_count')) {
      context.handle(
          _totalCountMeta,
          totalCount.isAcceptableOrUnknown(
              data['total_count']!, _totalCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Container map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Container(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      externalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      totalCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ContainersTable createAlias(String alias) {
    return $ContainersTable(attachedDatabase, alias);
  }
}

class Container extends DataClass implements Insertable<Container> {
  final int id;
  final String type;
  final String? externalId;
  final String name;
  final int totalCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Container(
      {required this.id,
      required this.type,
      this.externalId,
      required this.name,
      required this.totalCount,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['name'] = Variable<String>(name);
    map['total_count'] = Variable<int>(totalCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContainersCompanion toCompanion(bool nullToAbsent) {
    return ContainersCompanion(
      id: Value(id),
      type: Value(type),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      name: Value(name),
      totalCount: Value(totalCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Container.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Container(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      name: serializer.fromJson<String>(json['name']),
      totalCount: serializer.fromJson<int>(json['totalCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'externalId': serializer.toJson<String?>(externalId),
      'name': serializer.toJson<String>(name),
      'totalCount': serializer.toJson<int>(totalCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Container copyWith(
          {int? id,
          String? type,
          Value<String?> externalId = const Value.absent(),
          String? name,
          int? totalCount,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Container(
        id: id ?? this.id,
        type: type ?? this.type,
        externalId: externalId.present ? externalId.value : this.externalId,
        name: name ?? this.name,
        totalCount: totalCount ?? this.totalCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Container copyWithCompanion(ContainersCompanion data) {
    return Container(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      externalId:
          data.externalId.present ? data.externalId.value : this.externalId,
      name: data.name.present ? data.name.value : this.name,
      totalCount:
          data.totalCount.present ? data.totalCount.value : this.totalCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Container(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('externalId: $externalId, ')
          ..write('name: $name, ')
          ..write('totalCount: $totalCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, externalId, name, totalCount, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Container &&
          other.id == this.id &&
          other.type == this.type &&
          other.externalId == this.externalId &&
          other.name == this.name &&
          other.totalCount == this.totalCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ContainersCompanion extends UpdateCompanion<Container> {
  final Value<int> id;
  final Value<String> type;
  final Value<String?> externalId;
  final Value<String> name;
  final Value<int> totalCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ContainersCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.externalId = const Value.absent(),
    this.name = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ContainersCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    this.externalId = const Value.absent(),
    required String name,
    this.totalCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : type = Value(type),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Container> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? externalId,
    Expression<String>? name,
    Expression<int>? totalCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (externalId != null) 'external_id': externalId,
      if (name != null) 'name': name,
      if (totalCount != null) 'total_count': totalCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ContainersCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<String?>? externalId,
      Value<String>? name,
      Value<int>? totalCount,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ContainersCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      externalId: externalId ?? this.externalId,
      name: name ?? this.name,
      totalCount: totalCount ?? this.totalCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (totalCount.present) {
      map['total_count'] = Variable<int>(totalCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContainersCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('externalId: $externalId, ')
          ..write('name: $name, ')
          ..write('totalCount: $totalCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ContainerVideosTable extends ContainerVideos
    with TableInfo<$ContainerVideosTable, ContainerVideo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContainerVideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _containerIdMeta =
      const VerificationMeta('containerId');
  @override
  late final GeneratedColumn<int> containerId = GeneratedColumn<int>(
      'container_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
      'bvid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [containerId, bvid, addedAt, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'container_videos';
  @override
  VerificationContext validateIntegrity(Insertable<ContainerVideo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('container_id')) {
      context.handle(
          _containerIdMeta,
          containerId.isAcceptableOrUnknown(
              data['container_id']!, _containerIdMeta));
    } else if (isInserting) {
      context.missing(_containerIdMeta);
    }
    if (data.containsKey('bvid')) {
      context.handle(
          _bvidMeta, bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta));
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {containerId, bvid};
  @override
  ContainerVideo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContainerVideo(
      containerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}container_id'])!,
      bvid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bvid'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $ContainerVideosTable createAlias(String alias) {
    return $ContainerVideosTable(attachedDatabase, alias);
  }
}

class ContainerVideo extends DataClass implements Insertable<ContainerVideo> {
  final int containerId;
  final String bvid;
  final DateTime addedAt;
  final String note;
  const ContainerVideo(
      {required this.containerId,
      required this.bvid,
      required this.addedAt,
      required this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['container_id'] = Variable<int>(containerId);
    map['bvid'] = Variable<String>(bvid);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['note'] = Variable<String>(note);
    return map;
  }

  ContainerVideosCompanion toCompanion(bool nullToAbsent) {
    return ContainerVideosCompanion(
      containerId: Value(containerId),
      bvid: Value(bvid),
      addedAt: Value(addedAt),
      note: Value(note),
    );
  }

  factory ContainerVideo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContainerVideo(
      containerId: serializer.fromJson<int>(json['containerId']),
      bvid: serializer.fromJson<String>(json['bvid']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'containerId': serializer.toJson<int>(containerId),
      'bvid': serializer.toJson<String>(bvid),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'note': serializer.toJson<String>(note),
    };
  }

  ContainerVideo copyWith(
          {int? containerId, String? bvid, DateTime? addedAt, String? note}) =>
      ContainerVideo(
        containerId: containerId ?? this.containerId,
        bvid: bvid ?? this.bvid,
        addedAt: addedAt ?? this.addedAt,
        note: note ?? this.note,
      );
  ContainerVideo copyWithCompanion(ContainerVideosCompanion data) {
    return ContainerVideo(
      containerId:
          data.containerId.present ? data.containerId.value : this.containerId,
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContainerVideo(')
          ..write('containerId: $containerId, ')
          ..write('bvid: $bvid, ')
          ..write('addedAt: $addedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(containerId, bvid, addedAt, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContainerVideo &&
          other.containerId == this.containerId &&
          other.bvid == this.bvid &&
          other.addedAt == this.addedAt &&
          other.note == this.note);
}

class ContainerVideosCompanion extends UpdateCompanion<ContainerVideo> {
  final Value<int> containerId;
  final Value<String> bvid;
  final Value<DateTime> addedAt;
  final Value<String> note;
  final Value<int> rowid;
  const ContainerVideosCompanion({
    this.containerId = const Value.absent(),
    this.bvid = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContainerVideosCompanion.insert({
    required int containerId,
    required String bvid,
    required DateTime addedAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : containerId = Value(containerId),
        bvid = Value(bvid),
        addedAt = Value(addedAt);
  static Insertable<ContainerVideo> custom({
    Expression<int>? containerId,
    Expression<String>? bvid,
    Expression<DateTime>? addedAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (containerId != null) 'container_id': containerId,
      if (bvid != null) 'bvid': bvid,
      if (addedAt != null) 'added_at': addedAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContainerVideosCompanion copyWith(
      {Value<int>? containerId,
      Value<String>? bvid,
      Value<DateTime>? addedAt,
      Value<String>? note,
      Value<int>? rowid}) {
    return ContainerVideosCompanion(
      containerId: containerId ?? this.containerId,
      bvid: bvid ?? this.bvid,
      addedAt: addedAt ?? this.addedAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (containerId.present) {
      map['container_id'] = Variable<int>(containerId.value);
    }
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContainerVideosCompanion(')
          ..write('containerId: $containerId, ')
          ..write('bvid: $bvid, ')
          ..write('addedAt: $addedAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VideoGroupsTable videoGroups = $VideoGroupsTable(this);
  late final $VideosTable videos = $VideosTable(this);
  late final $UpMastersTable upMasters = $UpMastersTable(this);
  late final $SubtitlesTable subtitles = $SubtitlesTable(this);
  late final $SummariesTable summaries = $SummariesTable(this);
  late final $ChatSessionsTable chatSessions = $ChatSessionsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $ContainersTable containers = $ContainersTable(this);
  late final $ContainerVideosTable containerVideos =
      $ContainerVideosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        videoGroups,
        videos,
        upMasters,
        subtitles,
        summaries,
        chatSessions,
        chatMessages,
        containers,
        containerVideos
      ];
}

typedef $$VideoGroupsTableCreateCompanionBuilder = VideoGroupsCompanion
    Function({
  required String bvid,
  required String title,
  Value<String> cover,
  Value<String> uploader,
  Value<int> upMid,
  Value<String> upFace,
  Value<int> totalDuration,
  Value<int> pageCount,
  Value<String> pageNamesJson,
  required DateTime addedAt,
  Value<String> tags,
  Value<String> aiTags,
  Value<int> rowid,
});
typedef $$VideoGroupsTableUpdateCompanionBuilder = VideoGroupsCompanion
    Function({
  Value<String> bvid,
  Value<String> title,
  Value<String> cover,
  Value<String> uploader,
  Value<int> upMid,
  Value<String> upFace,
  Value<int> totalDuration,
  Value<int> pageCount,
  Value<String> pageNamesJson,
  Value<DateTime> addedAt,
  Value<String> tags,
  Value<String> aiTags,
  Value<int> rowid,
});

class $$VideoGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $VideoGroupsTable> {
  $$VideoGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cover => $composableBuilder(
      column: $table.cover, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uploader => $composableBuilder(
      column: $table.uploader, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get upMid => $composableBuilder(
      column: $table.upMid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get upFace => $composableBuilder(
      column: $table.upFace, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalDuration => $composableBuilder(
      column: $table.totalDuration, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageCount => $composableBuilder(
      column: $table.pageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pageNamesJson => $composableBuilder(
      column: $table.pageNamesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiTags => $composableBuilder(
      column: $table.aiTags, builder: (column) => ColumnFilters(column));
}

class $$VideoGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $VideoGroupsTable> {
  $$VideoGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cover => $composableBuilder(
      column: $table.cover, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uploader => $composableBuilder(
      column: $table.uploader, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get upMid => $composableBuilder(
      column: $table.upMid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get upFace => $composableBuilder(
      column: $table.upFace, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalDuration => $composableBuilder(
      column: $table.totalDuration,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageCount => $composableBuilder(
      column: $table.pageCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pageNamesJson => $composableBuilder(
      column: $table.pageNamesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiTags => $composableBuilder(
      column: $table.aiTags, builder: (column) => ColumnOrderings(column));
}

class $$VideoGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideoGroupsTable> {
  $$VideoGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get uploader =>
      $composableBuilder(column: $table.uploader, builder: (column) => column);

  GeneratedColumn<int> get upMid =>
      $composableBuilder(column: $table.upMid, builder: (column) => column);

  GeneratedColumn<String> get upFace =>
      $composableBuilder(column: $table.upFace, builder: (column) => column);

  GeneratedColumn<int> get totalDuration => $composableBuilder(
      column: $table.totalDuration, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get pageNamesJson => $composableBuilder(
      column: $table.pageNamesJson, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get aiTags =>
      $composableBuilder(column: $table.aiTags, builder: (column) => column);
}

class $$VideoGroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VideoGroupsTable,
    VideoGroup,
    $$VideoGroupsTableFilterComposer,
    $$VideoGroupsTableOrderingComposer,
    $$VideoGroupsTableAnnotationComposer,
    $$VideoGroupsTableCreateCompanionBuilder,
    $$VideoGroupsTableUpdateCompanionBuilder,
    (VideoGroup, BaseReferences<_$AppDatabase, $VideoGroupsTable, VideoGroup>),
    VideoGroup,
    PrefetchHooks Function()> {
  $$VideoGroupsTableTableManager(_$AppDatabase db, $VideoGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideoGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideoGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideoGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> bvid = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> cover = const Value.absent(),
            Value<String> uploader = const Value.absent(),
            Value<int> upMid = const Value.absent(),
            Value<String> upFace = const Value.absent(),
            Value<int> totalDuration = const Value.absent(),
            Value<int> pageCount = const Value.absent(),
            Value<String> pageNamesJson = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> aiTags = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VideoGroupsCompanion(
            bvid: bvid,
            title: title,
            cover: cover,
            uploader: uploader,
            upMid: upMid,
            upFace: upFace,
            totalDuration: totalDuration,
            pageCount: pageCount,
            pageNamesJson: pageNamesJson,
            addedAt: addedAt,
            tags: tags,
            aiTags: aiTags,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String bvid,
            required String title,
            Value<String> cover = const Value.absent(),
            Value<String> uploader = const Value.absent(),
            Value<int> upMid = const Value.absent(),
            Value<String> upFace = const Value.absent(),
            Value<int> totalDuration = const Value.absent(),
            Value<int> pageCount = const Value.absent(),
            Value<String> pageNamesJson = const Value.absent(),
            required DateTime addedAt,
            Value<String> tags = const Value.absent(),
            Value<String> aiTags = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VideoGroupsCompanion.insert(
            bvid: bvid,
            title: title,
            cover: cover,
            uploader: uploader,
            upMid: upMid,
            upFace: upFace,
            totalDuration: totalDuration,
            pageCount: pageCount,
            pageNamesJson: pageNamesJson,
            addedAt: addedAt,
            tags: tags,
            aiTags: aiTags,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VideoGroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VideoGroupsTable,
    VideoGroup,
    $$VideoGroupsTableFilterComposer,
    $$VideoGroupsTableOrderingComposer,
    $$VideoGroupsTableAnnotationComposer,
    $$VideoGroupsTableCreateCompanionBuilder,
    $$VideoGroupsTableUpdateCompanionBuilder,
    (VideoGroup, BaseReferences<_$AppDatabase, $VideoGroupsTable, VideoGroup>),
    VideoGroup,
    PrefetchHooks Function()>;
typedef $$VideosTableCreateCompanionBuilder = VideosCompanion Function({
  required String bvid,
  required int page,
  required int aid,
  Value<int> cid,
  Value<String> partName,
  Value<String> partTitle,
  Value<String> partCover,
  Value<int> duration,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$VideosTableUpdateCompanionBuilder = VideosCompanion Function({
  Value<String> bvid,
  Value<int> page,
  Value<int> aid,
  Value<int> cid,
  Value<String> partName,
  Value<String> partTitle,
  Value<String> partCover,
  Value<int> duration,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

class $$VideosTableFilterComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get aid => $composableBuilder(
      column: $table.aid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cid => $composableBuilder(
      column: $table.cid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get partName => $composableBuilder(
      column: $table.partName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get partTitle => $composableBuilder(
      column: $table.partTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get partCover => $composableBuilder(
      column: $table.partCover, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));
}

class $$VideosTableOrderingComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get aid => $composableBuilder(
      column: $table.aid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cid => $composableBuilder(
      column: $table.cid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get partName => $composableBuilder(
      column: $table.partName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get partTitle => $composableBuilder(
      column: $table.partTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get partCover => $composableBuilder(
      column: $table.partCover, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));
}

class $$VideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get aid =>
      $composableBuilder(column: $table.aid, builder: (column) => column);

  GeneratedColumn<int> get cid =>
      $composableBuilder(column: $table.cid, builder: (column) => column);

  GeneratedColumn<String> get partName =>
      $composableBuilder(column: $table.partName, builder: (column) => column);

  GeneratedColumn<String> get partTitle =>
      $composableBuilder(column: $table.partTitle, builder: (column) => column);

  GeneratedColumn<String> get partCover =>
      $composableBuilder(column: $table.partCover, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$VideosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VideosTable,
    Video,
    $$VideosTableFilterComposer,
    $$VideosTableOrderingComposer,
    $$VideosTableAnnotationComposer,
    $$VideosTableCreateCompanionBuilder,
    $$VideosTableUpdateCompanionBuilder,
    (Video, BaseReferences<_$AppDatabase, $VideosTable, Video>),
    Video,
    PrefetchHooks Function()> {
  $$VideosTableTableManager(_$AppDatabase db, $VideosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> bvid = const Value.absent(),
            Value<int> page = const Value.absent(),
            Value<int> aid = const Value.absent(),
            Value<int> cid = const Value.absent(),
            Value<String> partName = const Value.absent(),
            Value<String> partTitle = const Value.absent(),
            Value<String> partCover = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VideosCompanion(
            bvid: bvid,
            page: page,
            aid: aid,
            cid: cid,
            partName: partName,
            partTitle: partTitle,
            partCover: partCover,
            duration: duration,
            addedAt: addedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String bvid,
            required int page,
            required int aid,
            Value<int> cid = const Value.absent(),
            Value<String> partName = const Value.absent(),
            Value<String> partTitle = const Value.absent(),
            Value<String> partCover = const Value.absent(),
            Value<int> duration = const Value.absent(),
            required DateTime addedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              VideosCompanion.insert(
            bvid: bvid,
            page: page,
            aid: aid,
            cid: cid,
            partName: partName,
            partTitle: partTitle,
            partCover: partCover,
            duration: duration,
            addedAt: addedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VideosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VideosTable,
    Video,
    $$VideosTableFilterComposer,
    $$VideosTableOrderingComposer,
    $$VideosTableAnnotationComposer,
    $$VideosTableCreateCompanionBuilder,
    $$VideosTableUpdateCompanionBuilder,
    (Video, BaseReferences<_$AppDatabase, $VideosTable, Video>),
    Video,
    PrefetchHooks Function()>;
typedef $$UpMastersTableCreateCompanionBuilder = UpMastersCompanion Function({
  Value<int> id,
  required int uid,
  required String name,
  Value<String> face,
  Value<int?> lastVideoAid,
  Value<DateTime?> lastSyncedAt,
  required int containerId,
  required DateTime addedAt,
});
typedef $$UpMastersTableUpdateCompanionBuilder = UpMastersCompanion Function({
  Value<int> id,
  Value<int> uid,
  Value<String> name,
  Value<String> face,
  Value<int?> lastVideoAid,
  Value<DateTime?> lastSyncedAt,
  Value<int> containerId,
  Value<DateTime> addedAt,
});

class $$UpMastersTableFilterComposer
    extends Composer<_$AppDatabase, $UpMastersTable> {
  $$UpMastersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get face => $composableBuilder(
      column: $table.face, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastVideoAid => $composableBuilder(
      column: $table.lastVideoAid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get containerId => $composableBuilder(
      column: $table.containerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));
}

class $$UpMastersTableOrderingComposer
    extends Composer<_$AppDatabase, $UpMastersTable> {
  $$UpMastersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get face => $composableBuilder(
      column: $table.face, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastVideoAid => $composableBuilder(
      column: $table.lastVideoAid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get containerId => $composableBuilder(
      column: $table.containerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));
}

class $$UpMastersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UpMastersTable> {
  $$UpMastersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get face =>
      $composableBuilder(column: $table.face, builder: (column) => column);

  GeneratedColumn<int> get lastVideoAid => $composableBuilder(
      column: $table.lastVideoAid, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<int> get containerId => $composableBuilder(
      column: $table.containerId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$UpMastersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UpMastersTable,
    UpMaster,
    $$UpMastersTableFilterComposer,
    $$UpMastersTableOrderingComposer,
    $$UpMastersTableAnnotationComposer,
    $$UpMastersTableCreateCompanionBuilder,
    $$UpMastersTableUpdateCompanionBuilder,
    (UpMaster, BaseReferences<_$AppDatabase, $UpMastersTable, UpMaster>),
    UpMaster,
    PrefetchHooks Function()> {
  $$UpMastersTableTableManager(_$AppDatabase db, $UpMastersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UpMastersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UpMastersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UpMastersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> face = const Value.absent(),
            Value<int?> lastVideoAid = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<int> containerId = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
          }) =>
              UpMastersCompanion(
            id: id,
            uid: uid,
            name: name,
            face: face,
            lastVideoAid: lastVideoAid,
            lastSyncedAt: lastSyncedAt,
            containerId: containerId,
            addedAt: addedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int uid,
            required String name,
            Value<String> face = const Value.absent(),
            Value<int?> lastVideoAid = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            required int containerId,
            required DateTime addedAt,
          }) =>
              UpMastersCompanion.insert(
            id: id,
            uid: uid,
            name: name,
            face: face,
            lastVideoAid: lastVideoAid,
            lastSyncedAt: lastSyncedAt,
            containerId: containerId,
            addedAt: addedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UpMastersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UpMastersTable,
    UpMaster,
    $$UpMastersTableFilterComposer,
    $$UpMastersTableOrderingComposer,
    $$UpMastersTableAnnotationComposer,
    $$UpMastersTableCreateCompanionBuilder,
    $$UpMastersTableUpdateCompanionBuilder,
    (UpMaster, BaseReferences<_$AppDatabase, $UpMastersTable, UpMaster>),
    UpMaster,
    PrefetchHooks Function()>;
typedef $$SubtitlesTableCreateCompanionBuilder = SubtitlesCompanion Function({
  Value<int> id,
  required String bvid,
  Value<int> page,
  required String language,
  required String rawJson,
  required String plainText,
  Value<int> charCount,
  Value<int> entryCount,
  required DateTime downloadedAt,
});
typedef $$SubtitlesTableUpdateCompanionBuilder = SubtitlesCompanion Function({
  Value<int> id,
  Value<String> bvid,
  Value<int> page,
  Value<String> language,
  Value<String> rawJson,
  Value<String> plainText,
  Value<int> charCount,
  Value<int> entryCount,
  Value<DateTime> downloadedAt,
});

class $$SubtitlesTableFilterComposer
    extends Composer<_$AppDatabase, $SubtitlesTable> {
  $$SubtitlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plainText => $composableBuilder(
      column: $table.plainText, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get charCount => $composableBuilder(
      column: $table.charCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entryCount => $composableBuilder(
      column: $table.entryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));
}

class $$SubtitlesTableOrderingComposer
    extends Composer<_$AppDatabase, $SubtitlesTable> {
  $$SubtitlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plainText => $composableBuilder(
      column: $table.plainText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get charCount => $composableBuilder(
      column: $table.charCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entryCount => $composableBuilder(
      column: $table.entryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SubtitlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubtitlesTable> {
  $$SubtitlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

  GeneratedColumn<int> get charCount =>
      $composableBuilder(column: $table.charCount, builder: (column) => column);

  GeneratedColumn<int> get entryCount => $composableBuilder(
      column: $table.entryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => column);
}

class $$SubtitlesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubtitlesTable,
    Subtitle,
    $$SubtitlesTableFilterComposer,
    $$SubtitlesTableOrderingComposer,
    $$SubtitlesTableAnnotationComposer,
    $$SubtitlesTableCreateCompanionBuilder,
    $$SubtitlesTableUpdateCompanionBuilder,
    (Subtitle, BaseReferences<_$AppDatabase, $SubtitlesTable, Subtitle>),
    Subtitle,
    PrefetchHooks Function()> {
  $$SubtitlesTableTableManager(_$AppDatabase db, $SubtitlesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubtitlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubtitlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubtitlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> bvid = const Value.absent(),
            Value<int> page = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<String> rawJson = const Value.absent(),
            Value<String> plainText = const Value.absent(),
            Value<int> charCount = const Value.absent(),
            Value<int> entryCount = const Value.absent(),
            Value<DateTime> downloadedAt = const Value.absent(),
          }) =>
              SubtitlesCompanion(
            id: id,
            bvid: bvid,
            page: page,
            language: language,
            rawJson: rawJson,
            plainText: plainText,
            charCount: charCount,
            entryCount: entryCount,
            downloadedAt: downloadedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String bvid,
            Value<int> page = const Value.absent(),
            required String language,
            required String rawJson,
            required String plainText,
            Value<int> charCount = const Value.absent(),
            Value<int> entryCount = const Value.absent(),
            required DateTime downloadedAt,
          }) =>
              SubtitlesCompanion.insert(
            id: id,
            bvid: bvid,
            page: page,
            language: language,
            rawJson: rawJson,
            plainText: plainText,
            charCount: charCount,
            entryCount: entryCount,
            downloadedAt: downloadedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SubtitlesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubtitlesTable,
    Subtitle,
    $$SubtitlesTableFilterComposer,
    $$SubtitlesTableOrderingComposer,
    $$SubtitlesTableAnnotationComposer,
    $$SubtitlesTableCreateCompanionBuilder,
    $$SubtitlesTableUpdateCompanionBuilder,
    (Subtitle, BaseReferences<_$AppDatabase, $SubtitlesTable, Subtitle>),
    Subtitle,
    PrefetchHooks Function()>;
typedef $$SummariesTableCreateCompanionBuilder = SummariesCompanion Function({
  required String id,
  required String bvid,
  Value<int> page,
  Value<String> title,
  required String type,
  required String content,
  Value<String> modelUsed,
  Value<String> promptUsed,
  Value<String> targetTopic,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SummariesTableUpdateCompanionBuilder = SummariesCompanion Function({
  Value<String> id,
  Value<String> bvid,
  Value<int> page,
  Value<String> title,
  Value<String> type,
  Value<String> content,
  Value<String> modelUsed,
  Value<String> promptUsed,
  Value<String> targetTopic,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SummariesTableFilterComposer
    extends Composer<_$AppDatabase, $SummariesTable> {
  $$SummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelUsed => $composableBuilder(
      column: $table.modelUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promptUsed => $composableBuilder(
      column: $table.promptUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetTopic => $composableBuilder(
      column: $table.targetTopic, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $SummariesTable> {
  $$SummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelUsed => $composableBuilder(
      column: $table.modelUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promptUsed => $composableBuilder(
      column: $table.promptUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetTopic => $composableBuilder(
      column: $table.targetTopic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SummariesTable> {
  $$SummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get modelUsed =>
      $composableBuilder(column: $table.modelUsed, builder: (column) => column);

  GeneratedColumn<String> get promptUsed => $composableBuilder(
      column: $table.promptUsed, builder: (column) => column);

  GeneratedColumn<String> get targetTopic => $composableBuilder(
      column: $table.targetTopic, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SummariesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SummariesTable,
    Summary,
    $$SummariesTableFilterComposer,
    $$SummariesTableOrderingComposer,
    $$SummariesTableAnnotationComposer,
    $$SummariesTableCreateCompanionBuilder,
    $$SummariesTableUpdateCompanionBuilder,
    (Summary, BaseReferences<_$AppDatabase, $SummariesTable, Summary>),
    Summary,
    PrefetchHooks Function()> {
  $$SummariesTableTableManager(_$AppDatabase db, $SummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bvid = const Value.absent(),
            Value<int> page = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> modelUsed = const Value.absent(),
            Value<String> promptUsed = const Value.absent(),
            Value<String> targetTopic = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SummariesCompanion(
            id: id,
            bvid: bvid,
            page: page,
            title: title,
            type: type,
            content: content,
            modelUsed: modelUsed,
            promptUsed: promptUsed,
            targetTopic: targetTopic,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bvid,
            Value<int> page = const Value.absent(),
            Value<String> title = const Value.absent(),
            required String type,
            required String content,
            Value<String> modelUsed = const Value.absent(),
            Value<String> promptUsed = const Value.absent(),
            Value<String> targetTopic = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SummariesCompanion.insert(
            id: id,
            bvid: bvid,
            page: page,
            title: title,
            type: type,
            content: content,
            modelUsed: modelUsed,
            promptUsed: promptUsed,
            targetTopic: targetTopic,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SummariesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SummariesTable,
    Summary,
    $$SummariesTableFilterComposer,
    $$SummariesTableOrderingComposer,
    $$SummariesTableAnnotationComposer,
    $$SummariesTableCreateCompanionBuilder,
    $$SummariesTableUpdateCompanionBuilder,
    (Summary, BaseReferences<_$AppDatabase, $SummariesTable, Summary>),
    Summary,
    PrefetchHooks Function()>;
typedef $$ChatSessionsTableCreateCompanionBuilder = ChatSessionsCompanion
    Function({
  required String id,
  required String bvid,
  Value<String> title,
  required DateTime createdAt,
  required DateTime lastActiveAt,
  Value<int> rowid,
});
typedef $$ChatSessionsTableUpdateCompanionBuilder = ChatSessionsCompanion
    Function({
  Value<String> id,
  Value<String> bvid,
  Value<String> title,
  Value<DateTime> createdAt,
  Value<DateTime> lastActiveAt,
  Value<int> rowid,
});

class $$ChatSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastActiveAt => $composableBuilder(
      column: $table.lastActiveAt, builder: (column) => ColumnFilters(column));
}

class $$ChatSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastActiveAt => $composableBuilder(
      column: $table.lastActiveAt,
      builder: (column) => ColumnOrderings(column));
}

class $$ChatSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActiveAt => $composableBuilder(
      column: $table.lastActiveAt, builder: (column) => column);
}

class $$ChatSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatSessionsTable,
    ChatSession,
    $$ChatSessionsTableFilterComposer,
    $$ChatSessionsTableOrderingComposer,
    $$ChatSessionsTableAnnotationComposer,
    $$ChatSessionsTableCreateCompanionBuilder,
    $$ChatSessionsTableUpdateCompanionBuilder,
    (
      ChatSession,
      BaseReferences<_$AppDatabase, $ChatSessionsTable, ChatSession>
    ),
    ChatSession,
    PrefetchHooks Function()> {
  $$ChatSessionsTableTableManager(_$AppDatabase db, $ChatSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bvid = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastActiveAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatSessionsCompanion(
            id: id,
            bvid: bvid,
            title: title,
            createdAt: createdAt,
            lastActiveAt: lastActiveAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bvid,
            Value<String> title = const Value.absent(),
            required DateTime createdAt,
            required DateTime lastActiveAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatSessionsCompanion.insert(
            id: id,
            bvid: bvid,
            title: title,
            createdAt: createdAt,
            lastActiveAt: lastActiveAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChatSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatSessionsTable,
    ChatSession,
    $$ChatSessionsTableFilterComposer,
    $$ChatSessionsTableOrderingComposer,
    $$ChatSessionsTableAnnotationComposer,
    $$ChatSessionsTableCreateCompanionBuilder,
    $$ChatSessionsTableUpdateCompanionBuilder,
    (
      ChatSession,
      BaseReferences<_$AppDatabase, $ChatSessionsTable, ChatSession>
    ),
    ChatSession,
    PrefetchHooks Function()>;
typedef $$ChatMessagesTableCreateCompanionBuilder = ChatMessagesCompanion
    Function({
  required String id,
  required String sessionId,
  required String role,
  required String content,
  required DateTime timestamp,
  Value<bool> isCompressed,
  Value<int> rowid,
});
typedef $$ChatMessagesTableUpdateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<String> id,
  Value<String> sessionId,
  Value<String> role,
  Value<String> content,
  Value<DateTime> timestamp,
  Value<bool> isCompressed,
  Value<int> rowid,
});

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompressed => $composableBuilder(
      column: $table.isCompressed, builder: (column) => ColumnFilters(column));
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompressed => $composableBuilder(
      column: $table.isCompressed,
      builder: (column) => ColumnOrderings(column));
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isCompressed => $composableBuilder(
      column: $table.isCompressed, builder: (column) => column);
}

class $$ChatMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (
      ChatMessage,
      BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>
    ),
    ChatMessage,
    PrefetchHooks Function()> {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<bool> isCompressed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion(
            id: id,
            sessionId: sessionId,
            role: role,
            content: content,
            timestamp: timestamp,
            isCompressed: isCompressed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sessionId,
            required String role,
            required String content,
            required DateTime timestamp,
            Value<bool> isCompressed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion.insert(
            id: id,
            sessionId: sessionId,
            role: role,
            content: content,
            timestamp: timestamp,
            isCompressed: isCompressed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChatMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (
      ChatMessage,
      BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>
    ),
    ChatMessage,
    PrefetchHooks Function()>;
typedef $$ContainersTableCreateCompanionBuilder = ContainersCompanion Function({
  Value<int> id,
  required String type,
  Value<String?> externalId,
  required String name,
  Value<int> totalCount,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$ContainersTableUpdateCompanionBuilder = ContainersCompanion Function({
  Value<int> id,
  Value<String> type,
  Value<String?> externalId,
  Value<String> name,
  Value<int> totalCount,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$ContainersTableFilterComposer
    extends Composer<_$AppDatabase, $ContainersTable> {
  $$ContainersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCount => $composableBuilder(
      column: $table.totalCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ContainersTableOrderingComposer
    extends Composer<_$AppDatabase, $ContainersTable> {
  $$ContainersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCount => $composableBuilder(
      column: $table.totalCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ContainersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContainersTable> {
  $$ContainersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
      column: $table.externalId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get totalCount => $composableBuilder(
      column: $table.totalCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ContainersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContainersTable,
    Container,
    $$ContainersTableFilterComposer,
    $$ContainersTableOrderingComposer,
    $$ContainersTableAnnotationComposer,
    $$ContainersTableCreateCompanionBuilder,
    $$ContainersTableUpdateCompanionBuilder,
    (Container, BaseReferences<_$AppDatabase, $ContainersTable, Container>),
    Container,
    PrefetchHooks Function()> {
  $$ContainersTableTableManager(_$AppDatabase db, $ContainersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContainersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContainersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContainersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> externalId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> totalCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ContainersCompanion(
            id: id,
            type: type,
            externalId: externalId,
            name: name,
            totalCount: totalCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            Value<String?> externalId = const Value.absent(),
            required String name,
            Value<int> totalCount = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              ContainersCompanion.insert(
            id: id,
            type: type,
            externalId: externalId,
            name: name,
            totalCount: totalCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ContainersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ContainersTable,
    Container,
    $$ContainersTableFilterComposer,
    $$ContainersTableOrderingComposer,
    $$ContainersTableAnnotationComposer,
    $$ContainersTableCreateCompanionBuilder,
    $$ContainersTableUpdateCompanionBuilder,
    (Container, BaseReferences<_$AppDatabase, $ContainersTable, Container>),
    Container,
    PrefetchHooks Function()>;
typedef $$ContainerVideosTableCreateCompanionBuilder = ContainerVideosCompanion
    Function({
  required int containerId,
  required String bvid,
  required DateTime addedAt,
  Value<String> note,
  Value<int> rowid,
});
typedef $$ContainerVideosTableUpdateCompanionBuilder = ContainerVideosCompanion
    Function({
  Value<int> containerId,
  Value<String> bvid,
  Value<DateTime> addedAt,
  Value<String> note,
  Value<int> rowid,
});

class $$ContainerVideosTableFilterComposer
    extends Composer<_$AppDatabase, $ContainerVideosTable> {
  $$ContainerVideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get containerId => $composableBuilder(
      column: $table.containerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$ContainerVideosTableOrderingComposer
    extends Composer<_$AppDatabase, $ContainerVideosTable> {
  $$ContainerVideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get containerId => $composableBuilder(
      column: $table.containerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$ContainerVideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContainerVideosTable> {
  $$ContainerVideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get containerId => $composableBuilder(
      column: $table.containerId, builder: (column) => column);

  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$ContainerVideosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContainerVideosTable,
    ContainerVideo,
    $$ContainerVideosTableFilterComposer,
    $$ContainerVideosTableOrderingComposer,
    $$ContainerVideosTableAnnotationComposer,
    $$ContainerVideosTableCreateCompanionBuilder,
    $$ContainerVideosTableUpdateCompanionBuilder,
    (
      ContainerVideo,
      BaseReferences<_$AppDatabase, $ContainerVideosTable, ContainerVideo>
    ),
    ContainerVideo,
    PrefetchHooks Function()> {
  $$ContainerVideosTableTableManager(
      _$AppDatabase db, $ContainerVideosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContainerVideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContainerVideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContainerVideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> containerId = const Value.absent(),
            Value<String> bvid = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContainerVideosCompanion(
            containerId: containerId,
            bvid: bvid,
            addedAt: addedAt,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int containerId,
            required String bvid,
            required DateTime addedAt,
            Value<String> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContainerVideosCompanion.insert(
            containerId: containerId,
            bvid: bvid,
            addedAt: addedAt,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ContainerVideosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ContainerVideosTable,
    ContainerVideo,
    $$ContainerVideosTableFilterComposer,
    $$ContainerVideosTableOrderingComposer,
    $$ContainerVideosTableAnnotationComposer,
    $$ContainerVideosTableCreateCompanionBuilder,
    $$ContainerVideosTableUpdateCompanionBuilder,
    (
      ContainerVideo,
      BaseReferences<_$AppDatabase, $ContainerVideosTable, ContainerVideo>
    ),
    ContainerVideo,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VideoGroupsTableTableManager get videoGroups =>
      $$VideoGroupsTableTableManager(_db, _db.videoGroups);
  $$VideosTableTableManager get videos =>
      $$VideosTableTableManager(_db, _db.videos);
  $$UpMastersTableTableManager get upMasters =>
      $$UpMastersTableTableManager(_db, _db.upMasters);
  $$SubtitlesTableTableManager get subtitles =>
      $$SubtitlesTableTableManager(_db, _db.subtitles);
  $$SummariesTableTableManager get summaries =>
      $$SummariesTableTableManager(_db, _db.summaries);
  $$ChatSessionsTableTableManager get chatSessions =>
      $$ChatSessionsTableTableManager(_db, _db.chatSessions);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$ContainersTableTableManager get containers =>
      $$ContainersTableTableManager(_db, _db.containers);
  $$ContainerVideosTableTableManager get containerVideos =>
      $$ContainerVideosTableTableManager(_db, _db.containerVideos);
}
