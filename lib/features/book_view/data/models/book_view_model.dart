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
      List<String> parsedTags = [];
      if (json['tags'] != null) {
        final dynamic t = json['tags'];
        if (t is String) {
          if (t.isNotEmpty) {
            parsedTags = t.split(',').map((e) => e.trim()).toList();
          }
        } else if (t is List) {
          parsedTags = t.map((e) => e.toString()).toList();
        }
      }

      return BookViewModel(
        id: json['id'],
        uuid: json['uuid'],
        title: json['title'],
        authors: json['authors'],
        authorSort: json['author_sort'],
        data: json['comments'] ?? json['data'] ?? '',
        flags: json['flags'] == 1,
        hasCover: json['has_cover'] == 1,
        identifiers: json['identifiers'],
        isArchived: json['is_archived'] == true,
        isbn: json['isbn'],
        languages: json['languages'],
        lastModified: json['last_modified'],
        path: json['path'],
        pubdate: json['pubdate'],
        publishers: json['publishers'],
        readStatus: json['read_status'] == true,
        registry: json['registry'],
        series: json['series'],
        seriesIndex:
            double.tryParse(json['series_index']?.toString() ?? '0')?.toInt() ??
            0,
        sort: json['sort'],
        timestamp: json['timestamp'],
        coverUrl: json['cover_url'],
        formats:
            json['formats'] != null
                ? List<String>.from(json['formats'])
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
