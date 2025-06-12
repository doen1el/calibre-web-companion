import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

class BookViewModel extends Equatable {
  final String authorSort;
  final String authors;
  final String comments;
  final String data;
  final bool flags; // 1 = true, 0 = false
  final bool hasCover; // 1 = true, 0 = false
  final int id;
  final String identifiers;
  final bool isArchived; // 1 = true, 0 = false
  final String isbn;
  final String languages;
  final String lastModified;
  final String path;
  final String pubdate;
  final String publishers;
  final double ratings;
  final bool readStatus; // "true" or "false"
  final String registry;
  final String series;
  final double seriesIndex;
  final String sort;
  final List<String> tags;
  final String timestamp;
  final String title;
  final String uuid;

  static final Logger _logger = Logger();

  const BookViewModel({
    required this.id,
    required this.uuid,
    required this.title,
    required this.authors,
    this.authorSort = '',
    this.comments = '',
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
    this.ratings = 0.0,
    this.readStatus = false,
    this.registry = '',
    this.series = '',
    this.seriesIndex = 0.0,
    this.sort = '',
    this.tags = const [],
    this.timestamp = '',
  });

  @override
  List<Object?> get props => [
    id,
    uuid,
    title,
    authors,
    authorSort,
    comments,
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
    ratings,
    readStatus,
    registry,
    series,
    seriesIndex,
    sort,
    tags,
    timestamp,
  ];

  /// Converts the BookItem to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'title': title,
      'authors': authors,
      'author_sort': authorSort,
      'description': comments,
      'data': data,
      'flags': flags,
      'has_cover': hasCover,
      'identifiers': identifiers,
      'archived': isArchived,
      'isbn': isbn,
      'languages': languages,
      'last_modified': lastModified,
      'path': path,
      'pubdate': pubdate,
      'publisher_name': publishers,
      'ratings': ratings,
      'read_status': readStatus,
      'registry': registry,
      'series': series,
      'series_index': seriesIndex.toString(),
      'sort': sort,
      'tags': tags.join(','),
      'timestamp': timestamp,
    };
  }

  /// Factory method to create a BookItem from JSON
  factory BookViewModel.fromJson(Map<String, dynamic> json) {
    try {
      return BookViewModel(
        id: json['id'],
        uuid: json['uuid'],
        title: json['title'],
        authors: json['authors'],
        authorSort: json['author_sort'],
        comments: json['comments'],
        data: json['data'],
        flags: json['flags'] == 1,
        hasCover: json['has_cover'] == 1,
        identifiers: json['identifiers'],
        isArchived: json['archived'] == 1,
        isbn: json['isbn'],
        languages: json['languages'],
        lastModified: json['last_modified'],
        path: json['path'],
        pubdate: json['pubdate'],
        publishers: json['publishers'],
        ratings: json['ratings'],
        readStatus: json['read_status'] == 'true',
        registry: json['registry'],
        series: json['series'],
        seriesIndex: json['series_index'],
        sort: json['sort'],
        tags:
            (() {
              final tagsJson = json['tags'];
              if (tagsJson is List) {
                return tagsJson.map((tag) => tag.toString()).toList();
              } else {
                return <String>[];
              }
            })(),
        timestamp: json['timestamp'],
      );
    } catch (e) {
      _logger.e('Error creating BookItem from JSON: $e');
      throw FormatException('Failed to parse book data: $e');
    }
  }
}
