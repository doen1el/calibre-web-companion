import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/book_view/data/datasources/book_view_remote_datasource.dart';
import 'package:calibre_web_companion/features/offline/data/repositories/offline_library_repository.dart';
import 'package:calibre_web_companion/features/shelf_details/data/datasources/shelf_details_remote_datasource.dart';

enum WidgetShelfSource { bookList, shelf, magicShelf, offline }

extension WidgetShelfSourceX on WidgetShelfSource {
  String get key {
    switch (this) {
      case WidgetShelfSource.bookList:
        return 'book_list';
      case WidgetShelfSource.shelf:
        return 'shelf';
      case WidgetShelfSource.magicShelf:
        return 'magic_shelf';
      case WidgetShelfSource.offline:
        return 'offline';
    }
  }

  bool get needsShelfId =>
      this == WidgetShelfSource.shelf || this == WidgetShelfSource.magicShelf;

  static WidgetShelfSource fromKey(String? key) {
    switch (key) {
      case 'shelf':
        return WidgetShelfSource.shelf;
      case 'magic_shelf':
        return WidgetShelfSource.magicShelf;
      case 'offline':
        return WidgetShelfSource.offline;
      case 'book_list':
      default:
        return WidgetShelfSource.bookList;
    }
  }
}

class WidgetShelfBook {
  final String uuid;
  final int id;
  final String title;
  final String authors;
  final String coverUrl;
  final String coverPath;
  final String format;

  const WidgetShelfBook({
    required this.uuid,
    required this.id,
    required this.title,
    required this.authors,
    this.coverUrl = '',
    this.coverPath = '',
    this.format = 'epub',
  });

  WidgetShelfBook copyWith({String? coverPath}) => WidgetShelfBook(
    uuid: uuid,
    id: id,
    title: title,
    authors: authors,
    coverUrl: coverUrl,
    coverPath: coverPath ?? this.coverPath,
    format: format,
  );

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'id': id,
    'title': title,
    'authors': authors,
    'coverUrl': coverUrl,
    'coverPath': coverPath,
    'format': format,
  };

  factory WidgetShelfBook.fromJson(Map<String, dynamic> json) =>
      WidgetShelfBook(
        uuid: json['uuid']?.toString() ?? '',
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? '',
        authors: json['authors']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        coverPath: json['coverPath']?.toString() ?? '',
        format: json['format']?.toString() ?? 'epub',
      );
}

class WidgetShelfLoader {
  final SharedPreferences prefs;
  final Logger logger;
  final OfflineLibraryRepository offlineRepository;

  WidgetShelfLoader({
    required this.prefs,
    required this.logger,
    required this.offlineRepository,
  });

  Future<List<WidgetShelfBook>> load({
    required WidgetShelfSource source,
    required String shelfId,
    required int limit,
  }) async {
    switch (source) {
      case WidgetShelfSource.offline:
        return _loadOffline(limit);
      case WidgetShelfSource.bookList:
        return _loadBookList(limit);
      case WidgetShelfSource.shelf:
      case WidgetShelfSource.magicShelf:
        if (shelfId.isEmpty) return const [];
        return _loadShelf(
          shelfId,
          limit,
          isMagic: source == WidgetShelfSource.magicShelf,
        );
    }
  }

  List<WidgetShelfBook> _loadOffline(int limit) {
    final books =
        offlineRepository.getAll()
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

    return books
        .take(limit)
        .map(
          (book) => WidgetShelfBook(
            uuid: book.uuid,
            id: book.id,
            title: book.title,
            authors: book.authors,
            coverPath: book.coverPath ?? '',
            format: book.format,
          ),
        )
        .toList();
  }

  Future<List<WidgetShelfBook>> _loadBookList(int limit) async {
    final datasource = BookViewRemoteDatasource(
      preferences: prefs,
      logger: logger,
    );

    final books = await datasource.fetchBooks(
      offset: 0,
      limit: limit,
      sortBy: 'added',
      sortOrder: 'desc',
    );

    return books
        .take(limit)
        .map(
          (book) => WidgetShelfBook(
            uuid: book.uuid,
            id: book.id,
            title: book.title,
            authors: book.authors,
            coverUrl: book.coverUrl ?? '',
            format: book.formats.isNotEmpty ? book.formats.first : 'epub',
          ),
        )
        .toList();
  }

  Future<List<WidgetShelfBook>> _loadShelf(
    String shelfId,
    int limit, {
    required bool isMagic,
  }) async {
    final datasource = ShelfDetailsRemoteDataSource(
      apiService: ApiService(),
      logger: logger,
      preferences: prefs,
    );

    final books = <WidgetShelfBook>[];
    int? offset = 0;

    while (offset != null && books.length < limit) {
      final details = await datasource.getShelfDetails(
        shelfId,
        offset: offset,
        isMagic: isMagic,
      );

      if (details.books.isEmpty) break;

      books.addAll(
        details.books.map(
          (book) => WidgetShelfBook(
            uuid: book.uuid.toLowerCase().replaceAll('urn:uuid:', ''),
            id: 0,
            title: book.title,
            authors: book.authors,
            coverUrl: book.coverUrl ?? '',
            format: book.formats.isNotEmpty ? book.formats.first : 'epub',
          ),
        ),
      );

      final next = details.nextOffset;
      offset = (next != null && next > offset) ? next : null;
    }

    return books.take(limit).toList();
  }
}
