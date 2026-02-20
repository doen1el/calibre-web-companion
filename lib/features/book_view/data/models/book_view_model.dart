import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

class BookViewModel extends Equatable {
  final String authorSort;
  final String authors;
  final String data;
  final bool flags;
  final bool hasCover;
  final int id;
  final String identifiers;
  final bool isArchived;
  final String isbn;
  final String languages;
  final String lastModified;
  final String path;
  final String pubdate;
  final String publishers;
  final bool readStatus;
  final String registry;
  final String series;
  final int seriesIndex;
  final String sort;
  final String timestamp;
  final String title;
  final String uuid;
  final String? coverUrl;
  final List<String> formats;
  final List<String> tags;

  static final Logger _logger = Logger();

  const BookViewModel({
    required this.id,
    required this.uuid,
    required this.title,
    required this.authors,
    this.authorSort = '',
    this.data = '',
    this.flags = false,
    this.hasCover = false,
    this.identifiers = '',
    this.isArchived = false,
    this.isbn = '',
    this.languages = '',
    this.lastModified = '',
    this.path = '',
    this.pubdate = '',
    this.publishers = '',
    this.readStatus = false,
    this.registry = '',
    this.series = '',
    this.seriesIndex = 0,
    this.sort = '',
    this.timestamp = '',
    this.coverUrl,
    this.formats = const [],
    this.tags = const [],
  });

  @override
  List<Object?> get props => [
    id,
    uuid,
    title,
    authors,
    authorSort,
    data,
    flags,
    hasCover,
    identifiers,
    isArchived,
    isbn,
    languages,
    lastModified,
    path,
    pubdate,
    publishers,
    readStatus,
    registry,
    series,
    seriesIndex,
    sort,
    timestamp,
    coverUrl,
    formats,
    tags,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'title': title,
      'authors': authors,
      'author_sort': authorSort,
      'data': data,
      'flags': flags,
      'has_cover': hasCover,
      'identifiers': identifiers,
      'is_archived': isArchived,
      'isbn': isbn,
      'languages': languages,
      'last_modified': lastModified,
      'path': path,
      'pubdate': pubdate,
      'publisher_name': publishers,
      'read_status': readStatus,
      'registry': registry,
      'series': series,
      'series_index': seriesIndex.toString(),
      'sort': sort,
      'timestamp': timestamp,
      'cover_url': coverUrl,
      'formats': formats,
      'tags': tags,
    };
  }

  factory BookViewModel.fromJson(Map<String, dynamic> json) {
    try {
      String asString(dynamic value, [String fallback = '']) {
        if (value == null) return fallback;
        return value.toString();
      }

      int asInt(dynamic value, [int fallback = 0]) {
        if (value == null) return fallback;
        if (value is int) return value;
        if (value is double) return value.toInt();
        return int.tryParse(value.toString()) ?? fallback;
      }

      bool asBool(dynamic value, [bool fallback = false]) {
        if (value == null) return fallback;
        if (value is bool) return value;
        if (value is num) return value != 0;
        final v = value.toString().toLowerCase().trim();
        if (v == 'true' || v == '1' || v == 'yes') return true;
        if (v == 'false' || v == '0' || v == 'no') return false;
        return fallback;
      }

      List<String> parsedTags = [];
      final dynamic rawTags = json['tags'];
      if (rawTags is String) {
        if (rawTags.isNotEmpty) {
          parsedTags = rawTags.split(',').map((e) => e.trim()).toList();
        }
      } else if (rawTags is List) {
        parsedTags = rawTags.map((e) => e.toString()).toList();
      }

      return BookViewModel(
        id: asInt(json['id']),
        uuid: asString(json['uuid']),
        title: asString(json['title'], 'Unknown Title'),
        authors: asString(json['authors'], 'Unknown'),
        authorSort: asString(json['author_sort']),
        data: asString(json['comments'] ?? json['data']),
        flags: asBool(json['flags']),
        hasCover: asBool(json['has_cover']),
        identifiers: asString(json['identifiers']),
        isArchived: asBool(json['is_archived']),
        isbn: asString(json['isbn']),
        languages: asString(json['languages']),
        lastModified: asString(json['last_modified']),
        path: asString(json['path']),
        pubdate: asString(json['pubdate']),
        publishers: asString(json['publishers'] ?? json['publisher_name']),
        readStatus: asBool(json['read_status']),
        registry: asString(json['registry']),
        series: asString(json['series']),
        seriesIndex: asInt(json['series_index']),
        sort: asString(json['sort']),
        timestamp: asString(json['timestamp']),
        coverUrl: json['cover_url']?.toString(),
        formats:
            json['formats'] is List
                ? List<String>.from(
                  (json['formats'] as List).map((e) => e.toString()),
                )
                : const [],
        tags: parsedTags,
      );
    } catch (e) {
      _logger.e('Error creating BookItem from JSON: $e');
      throw FormatException('Failed to parse book data: $e');
    }
  }

  BookViewModel copyWith({
    String? authorSort,
    String? authors,
    String? data,
    bool? flags,
    bool? hasCover,
    int? id,
    String? identifiers,
    bool? isArchived,
    String? isbn,
    String? languages,
    String? lastModified,
    String? path,
    String? pubdate,
    String? publishers,
    bool? readStatus,
    String? registry,
    String? series,
    int? seriesIndex,
    String? sort,
    String? timestamp,
    String? title,
    String? uuid,
    String? coverUrl,
    List<String>? formats,
    List<String>? tags,
  }) {
    return BookViewModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      authorSort: authorSort ?? this.authorSort,
      data: data ?? this.data,
      flags: flags ?? this.flags,
      hasCover: hasCover ?? this.hasCover,
      identifiers: identifiers ?? this.identifiers,
      isArchived: isArchived ?? this.isArchived,
      isbn: isbn ?? this.isbn,
      languages: languages ?? this.languages,
      lastModified: lastModified ?? this.lastModified,
      path: path ?? this.path,
      pubdate: pubdate ?? this.pubdate,
      publishers: publishers ?? this.publishers,
      readStatus: readStatus ?? this.readStatus,
      registry: registry ?? this.registry,
      series: series ?? this.series,
      seriesIndex: seriesIndex ?? this.seriesIndex,
      sort: sort ?? this.sort,
      timestamp: timestamp ?? this.timestamp,
      coverUrl: coverUrl ?? this.coverUrl,
      formats: formats ?? this.formats,
      tags: tags ?? this.tags,
    );
  }
}
