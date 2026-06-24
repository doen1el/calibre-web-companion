import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/server_capabilities.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class CancellationToken {
  bool _isCancelled = false;

  void cancel() => _isCancelled = true;
  bool get isCancelled => _isCancelled;
}

class BookViewRemoteDatasource {
  final ApiService _apiService;
  final Logger _logger;
  final SharedPreferences _preferences;

  BookViewRemoteDatasource({
    required SharedPreferences preferences,
    ApiService? apiService,
    Logger? logger,
  }) : _preferences = preferences,
       _apiService = apiService ?? ApiService(),
       _logger = logger ?? Logger();

  Future<List<BookViewModel>> fetchBooks({
    required int offset,
    required int limit,
    String? searchQuery,
    String sortBy = '',
    String sortOrder = '',
  }) async {
    try {
      final serverType = _preferences.getString('server_type');

      if (serverType == 'grimmory' || serverType == 'booklore') {
        return _fetchBooksBooklore(
          offset: offset,
          limit: limit,
          searchQuery: searchQuery,
        );
      } else if (serverType == 'opds') {
        return _fetchBooksOpds();
      } else if (serverType == 'calibre') {
        return _fetchBooksCalibre(
          offset: offset,
          limit: limit,
          searchQuery: searchQuery,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );
      }

      List<BookViewModel> books = [];

      final queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
        'sort': sortBy,
        'order': sortOrder,
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final response = await _apiService.getJson(
        endpoint: '/ajax/listbooks',
        authMethod: AuthMethod.cookie,
        queryParams: queryParams,
      );

      if (response.containsKey('rows') && response['rows'] is List) {
        final List<dynamic> rows = response['rows'];
        if (rows.isEmpty) {
          _logger.i('Received empty book list');
          return books;
        }
        for (var bookData in rows) {
          try {
            final book = BookViewModel.fromJson(bookData);
            books.add(book);
          } catch (e) {
            _logger.e('Error parsing book: $e');
          }
        }
        _logger.i('Parsed ${books.length} books');
        return books;
      }
      throw Exception('Invalid response format: $response');
    } catch (e) {
      _logger.e('Error fetching books: $e');
      throw Exception('Failed to load books: $e');
    }
  }

  Future<List<BookViewModel>> _fetchBooksOpds() async {
    try {
      final response = await _apiService.getXmlAsJson(
        endpoint: '',
        authMethod: AuthMethod.none,
      );

      List<BookViewModel> books = [];

      if (response.containsKey('feed') && response['feed'] != null) {
        final feed = response['feed'];

        if (feed.containsKey('entry')) {
          final entries = feed['entry'];

          if (entries is List) {
            for (var entry in entries) {
              final book = _mapOpdsEntryToViewModel(entry);
              if (book != null) books.add(book);
            }
          } else if (entries is Map) {
            final book = _mapOpdsEntryToViewModel(entries);
            if (book != null) books.add(book);
          }
        }
      }

      _logger.i('Parsed ${books.length} OPDS books');
      return books;
    } catch (e) {
      _logger.e('Error fetching OPDS books: $e');
      throw Exception('Failed to load OPDS books: $e');
    }
  }

  Future<List<BookViewModel>> _fetchBooksBooklore({
    required int offset,
    required int limit,
    String? searchQuery,
  }) async {
    try {
      final int page = (offset / limit).floor() + 1;

      final queryParams = {'page': page.toString(), 'size': limit.toString()};

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }

      final response = await _apiService.getXmlAsJson(
        endpoint: '/catalog',
        authMethod: AuthMethod.basic,
        queryParams: queryParams,
      );

      List<BookViewModel> books = [];

      if (response.containsKey('feed') && response['feed'] != null) {
        final feed = response['feed'];

        if (feed.containsKey('entry')) {
          final entries = feed['entry'];

          if (entries is List) {
            for (var entry in entries) {
              final book = _mapOpdsEntryToViewModel(entry);
              if (book != null) books.add(book);
            }
          } else if (entries is Map) {
            final book = _mapOpdsEntryToViewModel(entries);
            if (book != null) books.add(book);
          }
        }
      }

      _logger.i('Parsed ${books.length} OPDS books');
      return books;
    } catch (e) {
      _logger.e('Error fetching OPDS books: $e');
      throw Exception('Failed to load OPDS books: $e');
    }
  }

  BookViewModel? _mapOpdsEntryToViewModel(dynamic entry) {
    try {
      if (entry is! Map) return null;

      final title = entry['title'] ?? 'Unknown Title';

      final rawId = entry['id'] ?? '';
      final uuid = rawId.toString().replaceFirst('urn:uuid:', '');

      int id = 0;

      final parts = rawId.toString().split(':');
      if (parts.isNotEmpty) {
        final lastPart = parts.last;
        final parsed = int.tryParse(lastPart);
        if (parsed != null) {
          id = parsed;
        }
      }

      if (id == 0 && entry.containsKey('link')) {
        final links = entry['link'];
        final linkList = links is List ? links : [links];
        for (var link in linkList) {
          if (link is Map && link['_href'] != null) {
            final href = link['_href'].toString();
            final uri = Uri.tryParse(href);
            if (uri != null) {
              for (var segment in uri.pathSegments) {
                if (RegExp(r'^\d+$').hasMatch(segment)) {
                  id = int.parse(segment);
                  break;
                }
              }
            }
          }
        }
      }

      String authors = 'Unknown';
      if (entry.containsKey('author')) {
        final authorData = entry['author'];
        if (authorData is Map && authorData.containsKey('name')) {
          authors = authorData['name'];
        } else if (authorData is List) {
          authors = authorData.map((a) => a['name']).join(', ');
        }
      }

      bool hasCover = false;
      String? coverUrl;
      List<String> formats = [];

      if (entry.containsKey('link')) {
        final links = entry['link'];
        final linkList = links is List ? links : [links];

        for (var link in linkList) {
          if (link is Map) {
            final rel = link['_rel'] ?? link['rel'];
            final type = link['_type'] ?? link['type'];
            final href = link['_href'] ?? link['href'];

            if (rel == 'http://opds-spec.org/image' ||
                rel == 'http://opds-spec.org/image/thumbnail' ||
                (type != null && type.toString().startsWith('image/'))) {
              hasCover = true;
              if (href != null) {
                coverUrl = href.toString();
              }
            }

            if (rel == 'http://opds-spec.org/acquisition' && type != null) {
              final mimeType = type.toString().toLowerCase();
              if (mimeType.contains('application/epub+zip')) {
                formats.add('epub');
              } else if (mimeType.contains('application/pdf')) {
                formats.add('pdf');
              } else if (mimeType.contains('application/x-mobipocket-ebook') ||
                  mimeType.contains('application/mobi')) {
                formats.add('mobi');
              } else if (mimeType.contains(
                'application/vnd.amazon.mobi8-ebook',
              )) {
                formats.add('azw3');
              } else if (mimeType.contains('application/fb2')) {
                formats.add('fb2');
              } else if (mimeType.contains('application/vnd.comicbook+zip') ||
                  mimeType.contains('application/x-cbz')) {
                formats.add('cbz');
              } else if (mimeType.contains('application/vnd.comicbook-rar') ||
                  mimeType.contains('application/x-cbr')) {
                formats.add('cbr');
              } else if (mimeType.contains('text/plain')) {
                formats.add('txt');
              }
            }
          }
        }
      }

      String pubdate = '';
      if (entry.containsKey('published')) {
        pubdate = entry['published'];
      }

      List<String> tags = [];
      if (entry.containsKey('category')) {
        final categories = entry['category'];
        final categoryList = categories is List ? categories : [categories];
        for (var cat in categoryList) {
          if (cat is Map) {
            final term =
                cat['term'] ?? cat['_term'] ?? cat['label'] ?? cat['_label'];
            if (term != null && term.toString().isNotEmpty) {
              tags.add(term.toString());
            }
          }
        }
      }

      String description = '';
      if (entry.containsKey('content')) {
        final content = entry['content'];
        if (content is Map) {
          description =
              content['__cdata'] ?? content['#text'] ?? content.toString();
        } else {
          description = content.toString();
        }
      } else if (entry.containsKey('summary')) {
        final summary = entry['summary'];
        if (summary is Map) {
          description =
              summary['__cdata'] ?? summary['#text'] ?? summary.toString();
        } else {
          description = summary.toString();
        }
      }

      return BookViewModel(
        id: id,
        uuid: uuid,
        title: title,
        authors: authors,
        hasCover: hasCover,
        pubdate: pubdate,
        data: description,
        path: '',
        series: '',
        seriesIndex: 0,
        coverUrl: coverUrl,
        formats: formats.isNotEmpty ? formats : const [],
        tags: tags,
      );
    } catch (e) {
      _logger.w('Error mapping OPDS entry: $e');
      return null;
    }
  }

  Future<List<BookViewModel>> _fetchBooksCalibre({
    required int offset,
    required int limit,
    String? searchQuery,
    String sortBy = '',
    String sortOrder = '',
  }) async {
    try {
      final libraryId = _preferences.getString('calibre_library_id');
      final librarySegment =
          (libraryId != null && libraryId.isNotEmpty) ? '/$libraryId' : '';

      final queryParams = <String, String>{
        'num': limit.toString(),
        'offset': offset.toString(),
      };

      final sortField = _mapCalibreSortField(sortBy);
      if (sortField.isNotEmpty) {
        queryParams['sort'] = sortField;
        queryParams['sort_order'] = sortOrder == 'desc' ? 'desc' : 'asc';
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['query'] = searchQuery;
      }

      final searchResponse = await _apiService.getJson(
        endpoint: '/ajax/search$librarySegment',
        authMethod: AuthMethod.auto,
        queryParams: queryParams,
      );

      final bookIds =
          (searchResponse['book_ids'] as List?)
              ?.map((id) => id.toString())
              .toList() ??
          const <String>[];

      if (bookIds.isEmpty) {
        _logger.i('Calibre search returned no books');
        return [];
      }

      final booksResponse = await _apiService.getJson(
        endpoint: '/ajax/books$librarySegment',
        authMethod: AuthMethod.auto,
        queryParams: {'ids': bookIds.join(',')},
      );

      final books = <BookViewModel>[];

      for (final id in bookIds) {
        final data = booksResponse[id];
        if (data is Map) {
          final book = _mapCalibreBook(
            Map<String, dynamic>.from(data),
            id,
            libraryId,
          );
          if (book != null) books.add(book);
        }
      }

      _logger.i('Parsed ${books.length} Calibre books');
      return books;
    } catch (e) {
      _logger.e('Error fetching Calibre books: $e');
      throw Exception('Failed to load Calibre books: $e');
    }
  }

  String _mapCalibreSortField(String sortBy) {
    switch (sortBy) {
      case 'title':
        return 'title';
      case 'authors':
        return 'authors';
      case 'series':
        return 'series';
      case 'added':
        return 'timestamp';
      default:
        return '';
    }
  }

  BookViewModel? _mapCalibreBook(
    Map<String, dynamic> data,
    String idString,
    String? libraryId,
  ) {
    try {
      final id = int.tryParse(idString) ?? 0;

      String joinList(dynamic value) {
        if (value is List) return value.map((e) => e.toString()).join(', ');
        return value?.toString() ?? '';
      }

      final authors = joinList(data['authors']);
      final tags =
          (data['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];
      final formats =
          (data['formats'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];

      final seriesIndex =
          double.tryParse(data['series_index']?.toString() ?? '')?.toInt() ?? 0;

      final librarySegment =
          (libraryId != null && libraryId.isNotEmpty) ? '/$libraryId' : '';
      final coverUrl =
          data['cover']?.toString().isNotEmpty == true
              ? data['cover'].toString()
              : '/get/cover/$id$librarySegment';

      return BookViewModel(
        id: id,
        uuid: data['uuid']?.toString() ?? '',
        title: data['title']?.toString() ?? 'Unknown Title',
        authors: authors.isEmpty ? 'Unknown' : authors,
        series: data['series']?.toString() ?? '',
        seriesIndex: seriesIndex,
        publishers: data['publisher']?.toString() ?? '',
        languages: joinList(data['languages']),
        pubdate: data['pubdate']?.toString() ?? '',
        data: data['comments']?.toString() ?? '',
        hasCover: true,
        coverUrl: coverUrl,
        formats: formats,
        tags: tags,
      );
    } catch (e) {
      _logger.w('Error mapping Calibre book $idString: $e');
      return null;
    }
  }

  ServerCapabilities getCapabilities() =>
      ServerCapabilities.fromServerType(_preferences.getString('server_type'));

  Map<String, String> getLibraries() {
    final raw = _preferences.getString('calibre_library_map');
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      _logger.w('Could not decode calibre_library_map: $e');
      return const {};
    }
  }

  String? getCurrentLibraryId() => _preferences.getString('calibre_library_id');

  Future<void> setCurrentLibraryId(String libraryId) async {
    await _preferences.setString('calibre_library_id', libraryId);
  }

  Future<bool> uploadEbook(File book, CancellationToken cancelToken) async {
    try {
      if (_preferences.getString('server_type') == 'calibre') {
        return _uploadEbookCalibre(book);
      }

      final result = await _apiService.uploadFile(
        file: book,
        endpoint: '/upload',
        cancelToken: cancelToken,
        timeoutSeconds: 60,
      );

      if (result['cancelled'] == true) {
        _logger.i('Upload was cancelled');
        return false;
      }

      if (result['success'] == true) {
        return true;
      } else {
        _logger.e('Upload failed: ${result['error']}');
        throw Exception(result['error']);
      }
    } catch (e) {
      _logger.e('Error uploading book: $e');
      if (!cancelToken.isCancelled) {
        throw Exception('Upload error: $e');
      }
      return false;
    }
  }

  Future<bool> _uploadEbookCalibre(File book) async {
    final libraryId = _preferences.getString('calibre_library_id');
    final librarySegment =
        (libraryId != null && libraryId.isNotEmpty) ? '/$libraryId' : '';

    final rawName = book.path.split('/').last.split('\\').last;
    final dotIndex = rawName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == rawName.length - 1) {
      throw Exception('The file needs an extension to upload to Calibre.');
    }
    final extension = rawName.substring(dotIndex);
    final base = rawName
        .substring(0, dotIndex)
        .replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '')
        .trim()
        .replaceAll(' ', '_');
    final filename = '${base.isEmpty ? 'book' : base}$extension';

    final jobId = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = await book.readAsBytes();

    final response = await _apiService.post(
      endpoint:
          '/cdb/add-book/$jobId/y/${Uri.encodeComponent(filename)}$librarySegment',
      authMethod: AuthMethod.auto,
      contentType: 'application/octet-stream',
      body: bytes,
    );

    if (response.statusCode == 200) {
      _logger.i('Calibre add-book succeeded for "$filename"');
      return true;
    }
    if (response.statusCode == 403) {
      throw Exception(
        'The Calibre server does not allow adding books (read-only mode or a '
        'user without write permission).',
      );
    }
    throw Exception('Upload failed (${response.statusCode})');
  }

  Future<int> getColumnCount() async {
    return _preferences.getInt('grid_column_count') ?? 2;
  }

  Future<void> setColumnCount(int count) async {
    if (count < 1) count = 1;
    if (count > 5) count = 5;
    await _preferences.setInt('grid_column_count', count);
  }

  Future<bool> getIsListView() async {
    return _preferences.getBool('is_list_view') ?? false;
  }

  Future<void> setIsListView(bool isList) async {
    await _preferences.setBool('is_list_view', isList);
  }

  bool getIsOpds() {
    return _preferences.getString('server_type') == 'opds' ||
        _preferences.getString('server_type') == 'grimmory' ||
        _preferences.getString('server_type') == 'booklore';
  }
}
