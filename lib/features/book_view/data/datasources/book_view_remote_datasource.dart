import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
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

      if (serverType == 'booklore') {
        return _fetchBooksBooklore(
          offset: offset,
          limit: limit,
          searchQuery: searchQuery,
        );
      } else if (serverType == 'opds') {
        return _fetchBooksOpds();
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

  Future<bool> uploadEbook(File book, CancellationToken cancelToken) async {
    try {
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
    return _preferences.getString('server_type') == 'opds';
  }
}
