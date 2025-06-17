import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';

class BookViewModel extends Equatable {
  final String authorSort;
  final String authors;
  final String data;
  final bool flags; // 1 = true, 0 = false
  final bool hasCover; // 1 = true, 0 = false
  final int id;
  final String identifiers;
  final bool isArchived; // true or false
  final String isbn;
  final String languages;
  final String lastModified;
  final String path;
  final String pubdate;
  final String publishers;
  final bool readStatus; // "true" or "false"
  final String registry;
  final String series;
  final int seriesIndex;
  final String sort;
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
  ];

  /// Converts the BookItem to a JSON map
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
        data: json['data'],
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
      );
    } catch (e) {
      _logger.e('Error creating BookItem from JSON: $e');
      throw FormatException('Failed to parse book data: $e');
    }
  }
}
