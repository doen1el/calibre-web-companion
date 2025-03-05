import 'package:shared_preferences/shared_preferences.dart';

enum CoverResolution { original, small, medium, large }

class BookModel {
  final String defaultPubdate;
  final String atomTimestamp;
  final String authorSort;
  final List<String> authors;
  final String comments;
  final String customColumn2;
  final String data;
  final int flags;
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
  final String ratings;
  final bool readStatus;
  final String registry;
  final String series;
  final double seriesIndex;
  final String sort;
  final String tags;
  final String timestamp;
  final String title;
  final String uuid;

  BookModel({
    this.defaultPubdate = '',
    this.atomTimestamp = '',
    this.authorSort = '',
    this.authors = const [],
    this.comments = '',
    this.customColumn2 = '',
    this.data = '',
    this.flags = 0,
    this.hasCover = false,
    this.id = 0,
    this.identifiers = '',
    this.isArchived = false,
    this.isbn = '',
    this.languages = '',
    this.lastModified = '',
    this.path = '',
    this.pubdate = '',
    this.publishers = '',
    this.ratings = '',
    this.readStatus = false,
    this.registry = '',
    this.series = '',
    this.seriesIndex = 1.0,
    this.sort = '',
    this.tags = '',
    this.timestamp = '',
    this.title = '',
    this.uuid = '',
  });

  // Factory constructor to create a BookModel from JSON
  factory BookModel.fromJson(Map<String, dynamic> json) {
    // Parse authors string into a list
    List<String> authorsList = [];
    if (json['authors'] != null && json['authors'].toString().isNotEmpty) {
      authorsList = json['authors'].toString().split('|');
    }

    return BookModel(
      defaultPubdate: json['DEFAULT_PUBDATE']?.toString() ?? '',
      atomTimestamp: json['atom_timestamp']?.toString() ?? '',
      authorSort: json['author_sort']?.toString() ?? '',
      authors: authorsList,
      comments: json['comments']?.toString() ?? '',
      customColumn2: json['custom_column_2']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
      flags: json['flags'] is int ? json['flags'] : 0,
      hasCover: json['has_cover'] == 1 || json['has_cover'] == true,
      id: json['id'] is int ? json['id'] : 0,
      identifiers: json['identifiers']?.toString() ?? '',
      isArchived: json['is_archived'] == true,
      isbn: json['isbn']?.toString() ?? '',
      languages: json['languages']?.toString() ?? '',
      lastModified: json['last_modified']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      pubdate: json['pubdate']?.toString() ?? '',
      publishers: json['publishers']?.toString() ?? '',
      ratings: json['ratings']?.toString() ?? '',
      readStatus: json['read_status'] == true,
      registry: json['registry']?.toString() ?? '',
      series: json['series']?.toString() ?? '',
      seriesIndex:
          json['series_index'] is num ? json['series_index'].toDouble() : 1.0,
      sort: json['sort']?.toString() ?? '',
      tags: json['tags']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      uuid: json['uuid']?.toString() ?? '',
    );
  }

  // Convert the model back to JSON
  Map<String, dynamic> toJson() {
    return {
      'DEFAULT_PUBDATE': defaultPubdate,
      'atom_timestamp': atomTimestamp,
      'author_sort': authorSort,
      'authors': authors.join('|'),
      'comments': comments,
      'custom_column_2': customColumn2,
      'data': data,
      'flags': flags,
      'has_cover': hasCover ? 1 : 0,
      'id': id,
      'identifiers': identifiers,
      'is_archived': isArchived,
      'isbn': isbn,
      'languages': languages,
      'last_modified': lastModified,
      'path': path,
      'pubdate': pubdate,
      'publishers': publishers,
      'ratings': ratings,
      'read_status': readStatus,
      'registry': registry,
      'series': series,
      'series_index': seriesIndex,
      'sort': sort,
      'tags': tags,
      'timestamp': timestamp,
      'title': title,
      'uuid': uuid,
    };
  }

  // Helper method to get cover image URL
  Future<String> getCoverUrl(CoverResolution resolution) async {
    if (!hasCover) return '';

    final serverUrl = await getServerUrl();

    switch (resolution) {
      case CoverResolution.original:
        return '$serverUrl/cover/$id/og';
      case CoverResolution.small:
        return '$serverUrl/cover/$id/sm';
      case CoverResolution.medium:
        return '$serverUrl/cover/$id/md';
      case CoverResolution.large:
        return '$serverUrl/cover/$id/lg';
    }
  }

  // Helper to get author names as a formatted string
  String getAuthorsText() {
    return authors.join(', ');
  }

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url');
  }
}
