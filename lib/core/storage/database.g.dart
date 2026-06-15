// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, false,
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
  static const VerificationMeta _aidMeta = const VerificationMeta('aid');
  @override
  late final GeneratedColumn<int> aid = GeneratedColumn<int>(
      'aid', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
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
  @override
  List<GeneratedColumn> get $columns => [
        bvid,
        title,
        coverUrl,
        uploader,
        aid,
        duration,
        pageCount,
        addedAt,
        tags
      ];
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
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('uploader')) {
      context.handle(_uploaderMeta,
          uploader.isAcceptableOrUnknown(data['uploader']!, _uploaderMeta));
    }
    if (data.containsKey('aid')) {
      context.handle(
          _aidMeta, aid.isAcceptableOrUnknown(data['aid']!, _aidMeta));
    } else if (isInserting) {
      context.missing(_aidMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('page_count')) {
      context.handle(_pageCountMeta,
          pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta));
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bvid};
  @override
  Video map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Video(
      bvid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bvid'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url'])!,
      uploader: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uploader'])!,
      aid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}aid'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      pageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_count'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
    );
  }

  @override
  $VideosTable createAlias(String alias) {
    return $VideosTable(attachedDatabase, alias);
  }
}

class Video extends DataClass implements Insertable<Video> {
  final String bvid;
  final String title;
  final String coverUrl;
  final String uploader;
  final int aid;
  final int duration;
  final int pageCount;
  final DateTime addedAt;
  final String tags;
  const Video(
      {required this.bvid,
      required this.title,
      required this.coverUrl,
      required this.uploader,
      required this.aid,
      required this.duration,
      required this.pageCount,
      required this.addedAt,
      required this.tags});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bvid'] = Variable<String>(bvid);
    map['title'] = Variable<String>(title);
    map['cover_url'] = Variable<String>(coverUrl);
    map['uploader'] = Variable<String>(uploader);
    map['aid'] = Variable<int>(aid);
    map['duration'] = Variable<int>(duration);
    map['page_count'] = Variable<int>(pageCount);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['tags'] = Variable<String>(tags);
    return map;
  }

  VideosCompanion toCompanion(bool nullToAbsent) {
    return VideosCompanion(
      bvid: Value(bvid),
      title: Value(title),
      coverUrl: Value(coverUrl),
      uploader: Value(uploader),
      aid: Value(aid),
      duration: Value(duration),
      pageCount: Value(pageCount),
      addedAt: Value(addedAt),
      tags: Value(tags),
    );
  }

  factory Video.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Video(
      bvid: serializer.fromJson<String>(json['bvid']),
      title: serializer.fromJson<String>(json['title']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      uploader: serializer.fromJson<String>(json['uploader']),
      aid: serializer.fromJson<int>(json['aid']),
      duration: serializer.fromJson<int>(json['duration']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      tags: serializer.fromJson<String>(json['tags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bvid': serializer.toJson<String>(bvid),
      'title': serializer.toJson<String>(title),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'uploader': serializer.toJson<String>(uploader),
      'aid': serializer.toJson<int>(aid),
      'duration': serializer.toJson<int>(duration),
      'pageCount': serializer.toJson<int>(pageCount),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'tags': serializer.toJson<String>(tags),
    };
  }

  Video copyWith(
          {String? bvid,
          String? title,
          String? coverUrl,
          String? uploader,
          int? aid,
          int? duration,
          int? pageCount,
          DateTime? addedAt,
          String? tags}) =>
      Video(
        bvid: bvid ?? this.bvid,
        title: title ?? this.title,
        coverUrl: coverUrl ?? this.coverUrl,
        uploader: uploader ?? this.uploader,
        aid: aid ?? this.aid,
        duration: duration ?? this.duration,
        pageCount: pageCount ?? this.pageCount,
        addedAt: addedAt ?? this.addedAt,
        tags: tags ?? this.tags,
      );
  Video copyWithCompanion(VideosCompanion data) {
    return Video(
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      title: data.title.present ? data.title.value : this.title,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      uploader: data.uploader.present ? data.uploader.value : this.uploader,
      aid: data.aid.present ? data.aid.value : this.aid,
      duration: data.duration.present ? data.duration.value : this.duration,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      tags: data.tags.present ? data.tags.value : this.tags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Video(')
          ..write('bvid: $bvid, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('uploader: $uploader, ')
          ..write('aid: $aid, ')
          ..write('duration: $duration, ')
          ..write('pageCount: $pageCount, ')
          ..write('addedAt: $addedAt, ')
          ..write('tags: $tags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      bvid, title, coverUrl, uploader, aid, duration, pageCount, addedAt, tags);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Video &&
          other.bvid == this.bvid &&
          other.title == this.title &&
          other.coverUrl == this.coverUrl &&
          other.uploader == this.uploader &&
          other.aid == this.aid &&
          other.duration == this.duration &&
          other.pageCount == this.pageCount &&
          other.addedAt == this.addedAt &&
          other.tags == this.tags);
}

class VideosCompanion extends UpdateCompanion<Video> {
  final Value<String> bvid;
  final Value<String> title;
  final Value<String> coverUrl;
  final Value<String> uploader;
  final Value<int> aid;
  final Value<int> duration;
  final Value<int> pageCount;
  final Value<DateTime> addedAt;
  final Value<String> tags;
  final Value<int> rowid;
  const VideosCompanion({
    this.bvid = const Value.absent(),
    this.title = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.uploader = const Value.absent(),
    this.aid = const Value.absent(),
    this.duration = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VideosCompanion.insert({
    required String bvid,
    required String title,
    this.coverUrl = const Value.absent(),
    this.uploader = const Value.absent(),
    required int aid,
    this.duration = const Value.absent(),
    this.pageCount = const Value.absent(),
    required DateTime addedAt,
    this.tags = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : bvid = Value(bvid),
        title = Value(title),
        aid = Value(aid),
        addedAt = Value(addedAt);
  static Insertable<Video> custom({
    Expression<String>? bvid,
    Expression<String>? title,
    Expression<String>? coverUrl,
    Expression<String>? uploader,
    Expression<int>? aid,
    Expression<int>? duration,
    Expression<int>? pageCount,
    Expression<DateTime>? addedAt,
    Expression<String>? tags,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bvid != null) 'bvid': bvid,
      if (title != null) 'title': title,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (uploader != null) 'uploader': uploader,
      if (aid != null) 'aid': aid,
      if (duration != null) 'duration': duration,
      if (pageCount != null) 'page_count': pageCount,
      if (addedAt != null) 'added_at': addedAt,
      if (tags != null) 'tags': tags,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VideosCompanion copyWith(
      {Value<String>? bvid,
      Value<String>? title,
      Value<String>? coverUrl,
      Value<String>? uploader,
      Value<int>? aid,
      Value<int>? duration,
      Value<int>? pageCount,
      Value<DateTime>? addedAt,
      Value<String>? tags,
      Value<int>? rowid}) {
    return VideosCompanion(
      bvid: bvid ?? this.bvid,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      uploader: uploader ?? this.uploader,
      aid: aid ?? this.aid,
      duration: duration ?? this.duration,
      pageCount: pageCount ?? this.pageCount,
      addedAt: addedAt ?? this.addedAt,
      tags: tags ?? this.tags,
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
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (uploader.present) {
      map['uploader'] = Variable<String>(uploader.value);
    }
    if (aid.present) {
      map['aid'] = Variable<int>(aid.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
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
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('uploader: $uploader, ')
          ..write('aid: $aid, ')
          ..write('duration: $duration, ')
          ..write('pageCount: $pageCount, ')
          ..write('addedAt: $addedAt, ')
          ..write('tags: $tags, ')
          ..write('rowid: $rowid')
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
  static const VerificationMeta _pageNumMeta =
      const VerificationMeta('pageNum');
  @override
  late final GeneratedColumn<int> pageNum = GeneratedColumn<int>(
      'page_num', aliasedName, false,
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
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, bvid, pageNum, language, rawJson, plainText, downloadedAt];
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
    if (data.containsKey('page_num')) {
      context.handle(_pageNumMeta,
          pageNum.isAcceptableOrUnknown(data['page_num']!, _pageNumMeta));
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
        {bvid, pageNum, language},
      ];
  @override
  Subtitle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subtitle(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      bvid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bvid'])!,
      pageNum: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_num'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      rawJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_json'])!,
      plainText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plain_text'])!,
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
  final int pageNum;
  final String language;
  final String rawJson;
  final String plainText;
  final DateTime downloadedAt;
  const Subtitle(
      {required this.id,
      required this.bvid,
      required this.pageNum,
      required this.language,
      required this.rawJson,
      required this.plainText,
      required this.downloadedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bvid'] = Variable<String>(bvid);
    map['page_num'] = Variable<int>(pageNum);
    map['language'] = Variable<String>(language);
    map['raw_json'] = Variable<String>(rawJson);
    map['plain_text'] = Variable<String>(plainText);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  SubtitlesCompanion toCompanion(bool nullToAbsent) {
    return SubtitlesCompanion(
      id: Value(id),
      bvid: Value(bvid),
      pageNum: Value(pageNum),
      language: Value(language),
      rawJson: Value(rawJson),
      plainText: Value(plainText),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory Subtitle.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subtitle(
      id: serializer.fromJson<int>(json['id']),
      bvid: serializer.fromJson<String>(json['bvid']),
      pageNum: serializer.fromJson<int>(json['pageNum']),
      language: serializer.fromJson<String>(json['language']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      plainText: serializer.fromJson<String>(json['plainText']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bvid': serializer.toJson<String>(bvid),
      'pageNum': serializer.toJson<int>(pageNum),
      'language': serializer.toJson<String>(language),
      'rawJson': serializer.toJson<String>(rawJson),
      'plainText': serializer.toJson<String>(plainText),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  Subtitle copyWith(
          {int? id,
          String? bvid,
          int? pageNum,
          String? language,
          String? rawJson,
          String? plainText,
          DateTime? downloadedAt}) =>
      Subtitle(
        id: id ?? this.id,
        bvid: bvid ?? this.bvid,
        pageNum: pageNum ?? this.pageNum,
        language: language ?? this.language,
        rawJson: rawJson ?? this.rawJson,
        plainText: plainText ?? this.plainText,
        downloadedAt: downloadedAt ?? this.downloadedAt,
      );
  Subtitle copyWithCompanion(SubtitlesCompanion data) {
    return Subtitle(
      id: data.id.present ? data.id.value : this.id,
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      pageNum: data.pageNum.present ? data.pageNum.value : this.pageNum,
      language: data.language.present ? data.language.value : this.language,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
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
          ..write('pageNum: $pageNum, ')
          ..write('language: $language, ')
          ..write('rawJson: $rawJson, ')
          ..write('plainText: $plainText, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, bvid, pageNum, language, rawJson, plainText, downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subtitle &&
          other.id == this.id &&
          other.bvid == this.bvid &&
          other.pageNum == this.pageNum &&
          other.language == this.language &&
          other.rawJson == this.rawJson &&
          other.plainText == this.plainText &&
          other.downloadedAt == this.downloadedAt);
}

class SubtitlesCompanion extends UpdateCompanion<Subtitle> {
  final Value<int> id;
  final Value<String> bvid;
  final Value<int> pageNum;
  final Value<String> language;
  final Value<String> rawJson;
  final Value<String> plainText;
  final Value<DateTime> downloadedAt;
  const SubtitlesCompanion({
    this.id = const Value.absent(),
    this.bvid = const Value.absent(),
    this.pageNum = const Value.absent(),
    this.language = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.plainText = const Value.absent(),
    this.downloadedAt = const Value.absent(),
  });
  SubtitlesCompanion.insert({
    this.id = const Value.absent(),
    required String bvid,
    this.pageNum = const Value.absent(),
    required String language,
    required String rawJson,
    required String plainText,
    required DateTime downloadedAt,
  })  : bvid = Value(bvid),
        language = Value(language),
        rawJson = Value(rawJson),
        plainText = Value(plainText),
        downloadedAt = Value(downloadedAt);
  static Insertable<Subtitle> custom({
    Expression<int>? id,
    Expression<String>? bvid,
    Expression<int>? pageNum,
    Expression<String>? language,
    Expression<String>? rawJson,
    Expression<String>? plainText,
    Expression<DateTime>? downloadedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bvid != null) 'bvid': bvid,
      if (pageNum != null) 'page_num': pageNum,
      if (language != null) 'language': language,
      if (rawJson != null) 'raw_json': rawJson,
      if (plainText != null) 'plain_text': plainText,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
    });
  }

  SubtitlesCompanion copyWith(
      {Value<int>? id,
      Value<String>? bvid,
      Value<int>? pageNum,
      Value<String>? language,
      Value<String>? rawJson,
      Value<String>? plainText,
      Value<DateTime>? downloadedAt}) {
    return SubtitlesCompanion(
      id: id ?? this.id,
      bvid: bvid ?? this.bvid,
      pageNum: pageNum ?? this.pageNum,
      language: language ?? this.language,
      rawJson: rawJson ?? this.rawJson,
      plainText: plainText ?? this.plainText,
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
    if (pageNum.present) {
      map['page_num'] = Variable<int>(pageNum.value);
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
          ..write('pageNum: $pageNum, ')
          ..write('language: $language, ')
          ..write('rawJson: $rawJson, ')
          ..write('plainText: $plainText, ')
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
  List<GeneratedColumn> get $columns =>
      [id, bvid, type, content, modelUsed, promptUsed, targetTopic, createdAt];
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
  final String type;
  final String content;
  final String modelUsed;
  final String promptUsed;
  final String targetTopic;
  final DateTime createdAt;
  const Summary(
      {required this.id,
      required this.bvid,
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
          String? type,
          String? content,
          String? modelUsed,
          String? promptUsed,
          String? targetTopic,
          DateTime? createdAt}) =>
      Summary(
        id: id ?? this.id,
        bvid: bvid ?? this.bvid,
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
  int get hashCode => Object.hash(
      id, bvid, type, content, modelUsed, promptUsed, targetTopic, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Summary &&
          other.id == this.id &&
          other.bvid == this.bvid &&
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
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
      'bvid', aliasedName, false,
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
  @override
  List<GeneratedColumn> get $columns => [id, bvid, role, content, timestamp];
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
    if (data.containsKey('bvid')) {
      context.handle(
          _bvidMeta, bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta));
    } else if (isInserting) {
      context.missing(_bvidMeta);
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
      bvid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bvid'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final String id;
  final String bvid;
  final String role;
  final String content;
  final DateTime timestamp;
  const ChatMessage(
      {required this.id,
      required this.bvid,
      required this.role,
      required this.content,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bvid'] = Variable<String>(bvid);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      bvid: Value(bvid),
      role: Value(role),
      content: Value(content),
      timestamp: Value(timestamp),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      id: serializer.fromJson<String>(json['id']),
      bvid: serializer.fromJson<String>(json['bvid']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bvid': serializer.toJson<String>(bvid),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  ChatMessage copyWith(
          {String? id,
          String? bvid,
          String? role,
          String? content,
          DateTime? timestamp}) =>
      ChatMessage(
        id: id ?? this.id,
        bvid: bvid ?? this.bvid,
        role: role ?? this.role,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
      );
  ChatMessage copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessage(
      id: data.id.present ? data.id.value : this.id,
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bvid, role, content, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == this.id &&
          other.bvid == this.bvid &&
          other.role == this.role &&
          other.content == this.content &&
          other.timestamp == this.timestamp);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<String> id;
  final Value<String> bvid;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.bvid = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String bvid,
    required String role,
    required String content,
    required DateTime timestamp,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bvid = Value(bvid),
        role = Value(role),
        content = Value(content),
        timestamp = Value(timestamp);
  static Insertable<ChatMessage> custom({
    Expression<String>? id,
    Expression<String>? bvid,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bvid != null) 'bvid': bvid,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? bvid,
      Value<String>? role,
      Value<String>? content,
      Value<DateTime>? timestamp,
      Value<int>? rowid}) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      bvid: bvid ?? this.bvid,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
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
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
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
          ..write('bvid: $bvid, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VideoTagsTable extends VideoTags
    with TableInfo<$VideoTagsTable, VideoTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideoTagsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, bvid, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'video_tags';
  @override
  VerificationContext validateIntegrity(Insertable<VideoTag> instance,
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
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {bvid, tag},
      ];
  @override
  VideoTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VideoTag(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      bvid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bvid'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag'])!,
    );
  }

  @override
  $VideoTagsTable createAlias(String alias) {
    return $VideoTagsTable(attachedDatabase, alias);
  }
}

class VideoTag extends DataClass implements Insertable<VideoTag> {
  final int id;
  final String bvid;
  final String tag;
  const VideoTag({required this.id, required this.bvid, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bvid'] = Variable<String>(bvid);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  VideoTagsCompanion toCompanion(bool nullToAbsent) {
    return VideoTagsCompanion(
      id: Value(id),
      bvid: Value(bvid),
      tag: Value(tag),
    );
  }

  factory VideoTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VideoTag(
      id: serializer.fromJson<int>(json['id']),
      bvid: serializer.fromJson<String>(json['bvid']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bvid': serializer.toJson<String>(bvid),
      'tag': serializer.toJson<String>(tag),
    };
  }

  VideoTag copyWith({int? id, String? bvid, String? tag}) => VideoTag(
        id: id ?? this.id,
        bvid: bvid ?? this.bvid,
        tag: tag ?? this.tag,
      );
  VideoTag copyWithCompanion(VideoTagsCompanion data) {
    return VideoTag(
      id: data.id.present ? data.id.value : this.id,
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VideoTag(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bvid, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoTag &&
          other.id == this.id &&
          other.bvid == this.bvid &&
          other.tag == this.tag);
}

class VideoTagsCompanion extends UpdateCompanion<VideoTag> {
  final Value<int> id;
  final Value<String> bvid;
  final Value<String> tag;
  const VideoTagsCompanion({
    this.id = const Value.absent(),
    this.bvid = const Value.absent(),
    this.tag = const Value.absent(),
  });
  VideoTagsCompanion.insert({
    this.id = const Value.absent(),
    required String bvid,
    required String tag,
  })  : bvid = Value(bvid),
        tag = Value(tag);
  static Insertable<VideoTag> custom({
    Expression<int>? id,
    Expression<String>? bvid,
    Expression<String>? tag,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bvid != null) 'bvid': bvid,
      if (tag != null) 'tag': tag,
    });
  }

  VideoTagsCompanion copyWith(
      {Value<int>? id, Value<String>? bvid, Value<String>? tag}) {
    return VideoTagsCompanion(
      id: id ?? this.id,
      bvid: bvid ?? this.bvid,
      tag: tag ?? this.tag,
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
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideoTagsCompanion(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VideosTable videos = $VideosTable(this);
  late final $SubtitlesTable subtitles = $SubtitlesTable(this);
  late final $SummariesTable summaries = $SummariesTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $VideoTagsTable videoTags = $VideoTagsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [videos, subtitles, summaries, chatMessages, videoTags];
}

typedef $$VideosTableCreateCompanionBuilder = VideosCompanion Function({
  required String bvid,
  required String title,
  Value<String> coverUrl,
  Value<String> uploader,
  required int aid,
  Value<int> duration,
  Value<int> pageCount,
  required DateTime addedAt,
  Value<String> tags,
  Value<int> rowid,
});
typedef $$VideosTableUpdateCompanionBuilder = VideosCompanion Function({
  Value<String> bvid,
  Value<String> title,
  Value<String> coverUrl,
  Value<String> uploader,
  Value<int> aid,
  Value<int> duration,
  Value<int> pageCount,
  Value<DateTime> addedAt,
  Value<String> tags,
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

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uploader => $composableBuilder(
      column: $table.uploader, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get aid => $composableBuilder(
      column: $table.aid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageCount => $composableBuilder(
      column: $table.pageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uploader => $composableBuilder(
      column: $table.uploader, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get aid => $composableBuilder(
      column: $table.aid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageCount => $composableBuilder(
      column: $table.pageCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get uploader =>
      $composableBuilder(column: $table.uploader, builder: (column) => column);

  GeneratedColumn<int> get aid =>
      $composableBuilder(column: $table.aid, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);
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
            Value<String> title = const Value.absent(),
            Value<String> coverUrl = const Value.absent(),
            Value<String> uploader = const Value.absent(),
            Value<int> aid = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<int> pageCount = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VideosCompanion(
            bvid: bvid,
            title: title,
            coverUrl: coverUrl,
            uploader: uploader,
            aid: aid,
            duration: duration,
            pageCount: pageCount,
            addedAt: addedAt,
            tags: tags,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String bvid,
            required String title,
            Value<String> coverUrl = const Value.absent(),
            Value<String> uploader = const Value.absent(),
            required int aid,
            Value<int> duration = const Value.absent(),
            Value<int> pageCount = const Value.absent(),
            required DateTime addedAt,
            Value<String> tags = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VideosCompanion.insert(
            bvid: bvid,
            title: title,
            coverUrl: coverUrl,
            uploader: uploader,
            aid: aid,
            duration: duration,
            pageCount: pageCount,
            addedAt: addedAt,
            tags: tags,
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
typedef $$SubtitlesTableCreateCompanionBuilder = SubtitlesCompanion Function({
  Value<int> id,
  required String bvid,
  Value<int> pageNum,
  required String language,
  required String rawJson,
  required String plainText,
  required DateTime downloadedAt,
});
typedef $$SubtitlesTableUpdateCompanionBuilder = SubtitlesCompanion Function({
  Value<int> id,
  Value<String> bvid,
  Value<int> pageNum,
  Value<String> language,
  Value<String> rawJson,
  Value<String> plainText,
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

  ColumnFilters<int> get pageNum => $composableBuilder(
      column: $table.pageNum, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plainText => $composableBuilder(
      column: $table.plainText, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get pageNum => $composableBuilder(
      column: $table.pageNum, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plainText => $composableBuilder(
      column: $table.plainText, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get pageNum =>
      $composableBuilder(column: $table.pageNum, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

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
            Value<int> pageNum = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<String> rawJson = const Value.absent(),
            Value<String> plainText = const Value.absent(),
            Value<DateTime> downloadedAt = const Value.absent(),
          }) =>
              SubtitlesCompanion(
            id: id,
            bvid: bvid,
            pageNum: pageNum,
            language: language,
            rawJson: rawJson,
            plainText: plainText,
            downloadedAt: downloadedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String bvid,
            Value<int> pageNum = const Value.absent(),
            required String language,
            required String rawJson,
            required String plainText,
            required DateTime downloadedAt,
          }) =>
              SubtitlesCompanion.insert(
            id: id,
            bvid: bvid,
            pageNum: pageNum,
            language: language,
            rawJson: rawJson,
            plainText: plainText,
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
typedef $$ChatMessagesTableCreateCompanionBuilder = ChatMessagesCompanion
    Function({
  required String id,
  required String bvid,
  required String role,
  required String content,
  required DateTime timestamp,
  Value<int> rowid,
});
typedef $$ChatMessagesTableUpdateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<String> id,
  Value<String> bvid,
  Value<String> role,
  Value<String> content,
  Value<DateTime> timestamp,
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

  ColumnFilters<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get bvid => $composableBuilder(
      column: $table.bvid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
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
            Value<String> bvid = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion(
            id: id,
            bvid: bvid,
            role: role,
            content: content,
            timestamp: timestamp,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bvid,
            required String role,
            required String content,
            required DateTime timestamp,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatMessagesCompanion.insert(
            id: id,
            bvid: bvid,
            role: role,
            content: content,
            timestamp: timestamp,
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
typedef $$VideoTagsTableCreateCompanionBuilder = VideoTagsCompanion Function({
  Value<int> id,
  required String bvid,
  required String tag,
});
typedef $$VideoTagsTableUpdateCompanionBuilder = VideoTagsCompanion Function({
  Value<int> id,
  Value<String> bvid,
  Value<String> tag,
});

class $$VideoTagsTableFilterComposer
    extends Composer<_$AppDatabase, $VideoTagsTable> {
  $$VideoTagsTableFilterComposer({
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

  ColumnFilters<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnFilters(column));
}

class $$VideoTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $VideoTagsTable> {
  $$VideoTagsTableOrderingComposer({
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

  ColumnOrderings<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnOrderings(column));
}

class $$VideoTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideoTagsTable> {
  $$VideoTagsTableAnnotationComposer({
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

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);
}

class $$VideoTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VideoTagsTable,
    VideoTag,
    $$VideoTagsTableFilterComposer,
    $$VideoTagsTableOrderingComposer,
    $$VideoTagsTableAnnotationComposer,
    $$VideoTagsTableCreateCompanionBuilder,
    $$VideoTagsTableUpdateCompanionBuilder,
    (VideoTag, BaseReferences<_$AppDatabase, $VideoTagsTable, VideoTag>),
    VideoTag,
    PrefetchHooks Function()> {
  $$VideoTagsTableTableManager(_$AppDatabase db, $VideoTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideoTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideoTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideoTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> bvid = const Value.absent(),
            Value<String> tag = const Value.absent(),
          }) =>
              VideoTagsCompanion(
            id: id,
            bvid: bvid,
            tag: tag,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String bvid,
            required String tag,
          }) =>
              VideoTagsCompanion.insert(
            id: id,
            bvid: bvid,
            tag: tag,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VideoTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VideoTagsTable,
    VideoTag,
    $$VideoTagsTableFilterComposer,
    $$VideoTagsTableOrderingComposer,
    $$VideoTagsTableAnnotationComposer,
    $$VideoTagsTableCreateCompanionBuilder,
    $$VideoTagsTableUpdateCompanionBuilder,
    (VideoTag, BaseReferences<_$AppDatabase, $VideoTagsTable, VideoTag>),
    VideoTag,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VideosTableTableManager get videos =>
      $$VideosTableTableManager(_db, _db.videos);
  $$SubtitlesTableTableManager get subtitles =>
      $$SubtitlesTableTableManager(_db, _db.subtitles);
  $$SummariesTableTableManager get summaries =>
      $$SummariesTableTableManager(_db, _db.summaries);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$VideoTagsTableTableManager get videoTags =>
      $$VideoTagsTableTableManager(_db, _db.videoTags);
}
