import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_details_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_feed_model.dart';

class DiscoverDetailsRemoteDatasource {
  final ApiService apiService;
  final Logger logger;
  final SharedPreferences preferences;

  DiscoverDetailsRemoteDatasource({
    required this.apiService,
    required this.logger,
    required this.preferences,
  });

  Future<DiscoverFeedModel> loadBooks(
    DiscoverType type, {
    String? subPath,
  }) async {
    try {
      final String path = _getBookListPath(type, subPath);
      final jsonData = await apiService.getXmlAsJson(
        endpoint: path,
        authMethod: AuthMethod.auto,
      );

      if (jsonData['feed'] == null || jsonData['feed']['entry'] == null) {
        logger.i('No entries found in feed for path: $path');
        return const DiscoverFeedModel(books: [], nextPageUrl: null);
      }

      final dynamic entryData = jsonData['feed']["entry"];
      final List<dynamic> items = entryData is List ? entryData : [entryData];
      final books =
          items
              .map(
                (item) => DiscoverDetailsModel.fromJson(
                  item,
                  apiService.getBaseUrl(),
                ),
              )
              .toList();

      return DiscoverFeedModel(
        books: books,
        nextPageUrl: jsonData['nextPageUrl'],
      );
    } catch (e) {
      logger.e('Error loading books: $e');
      throw Exception('Failed to load books: $e');
    }
  }

  Future<CategoryFeed> loadCategories(
    CategoryType type, {
    String? subPath,
  }) async {
    try {
      final String path = _getCategoryPath(type, subPath);
      final jsonData = await apiService.getXmlAsJson(
        endpoint: path,
        authMethod: AuthMethod.auto,
      );

      if (jsonData['feed'] == null || jsonData['feed']['entry'] == null) {
        logger.i('No entries found in feed for path: $path');
        return const CategoryFeed(categories: [], nextPageUrl: null);
      }

      final dynamic entryData = jsonData['feed']["entry"];
      final List<dynamic> items = entryData is List ? entryData : [entryData];

      final categories =
          items.map((item) {
            if (type == CategoryType.libraries) {
              String id = '';
              final links = item['link'];
              if (links != null) {
                final linkList = links is List ? links : [links];
                for (var link in linkList) {
                  if (link['_rel'] == 'subsection' ||
                      link['_rel'] == 'http://opds-spec.org/acquisition') {
                    id = link['_href'];
                    break;
                  }
                }
              }
              if (id.isEmpty) id = item['id'] ?? '';

              return CategoryModel(id: id, title: item['title'] ?? 'Unknown');
            }
            return CategoryModel.fromJson(item);
          }).toList();

      bool shouldSort = true;
      if (subPath == null &&
          (type == CategoryType.author ||
              type == CategoryType.category ||
              type == CategoryType.series ||
              type == CategoryType.libraries)) {
        shouldSort = false;
      }

      if (shouldSort) {
        categories.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      }

      return CategoryFeed(
        categories: categories,
        nextPageUrl: jsonData['nextPageUrl'],
      );
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<DiscoverFeedModel> loadBooksFromPath(String fullPath) async {
    logger.d('Loading books from path: $fullPath');
    try {
      String endpoint = fullPath;
      final baseUrl = apiService.getBaseUrl();

      if (endpoint.startsWith(baseUrl)) {
        endpoint = endpoint.substring(baseUrl.length);
      } else if (baseUrl.endsWith('/api/v1/opds') &&
          endpoint.startsWith('/api/v1/opds')) {
        endpoint = endpoint.replaceFirst('/api/v1/opds', '');
      }

      final jsonData = await apiService.getXmlAsJson(
        endpoint: endpoint,
        authMethod: AuthMethod.auto,
      );

      if (jsonData['feed'] == null || jsonData['feed']['entry'] == null) {
        logger.i('No entries found in feed for path: $fullPath');
        return const DiscoverFeedModel(books: [], nextPageUrl: null);
      }

      final dynamic entryData = jsonData['feed']["entry"];
      final List<dynamic> items = entryData is List ? entryData : [entryData];

      final books =
          items
              .map(
                (item) => DiscoverDetailsModel.fromJson(
                  item,
                  apiService.getBaseUrl(),
                ),
              )
              .toList();

      for (final book in books) {
        logger.d(book.coverUrl);
      }

      return DiscoverFeedModel(
        books: books,
        nextPageUrl: jsonData['nextPageUrl'],
      );
    } catch (e) {
      logger.e('Error loading books from path: $e');
      throw Exception('Failed to load books from path: $e');
    }
  }

  Future<CategoryFeed> loadCategoriesgeneric(String path) async {
    try {
      final jsonData = await apiService.getXmlAsJson(
        endpoint: path,
        authMethod: AuthMethod.auto,
      );

      final feed = _parseCategoryFeed(jsonData);
      return feed;
    } catch (e) {
      throw Exception('Failed to load generic categories from $path: $e');
    }
  }

  CategoryFeed _parseCategoryFeed(Map<String, dynamic> jsonData) {
    if (jsonData['feed'] == null || jsonData['feed']['entry'] == null) {
      return const CategoryFeed(categories: []);
    }

    final dynamic entryData = jsonData['feed']["entry"];
    final List<dynamic> items = entryData is List ? entryData : [entryData];

    final categories =
        items.map((json) => CategoryModel.fromJson(json)).where((c) {
          return c.title != 'All books';
        }).toList();

    categories.sort((a, b) => a.title.compareTo(b.title));

    return CategoryFeed(categories: categories);
  }

  String _getBookListPath(DiscoverType type, String? subPath) {
    final isOpds =
        preferences.getString('server_type') == 'opds' ||
        preferences.getString('server_type') == 'booklore';

    final Map<DiscoverType, String> paths = {
      DiscoverType.discover: '/opds/discover',
      DiscoverType.hot: '/opds/hot',
      DiscoverType.newlyAdded: isOpds ? '/recent' : '/opds/new',
      DiscoverType.rated: '/opds/rated',
      DiscoverType.readbooks: '/opds/readbooks',
      DiscoverType.unreadbooks: '/opds/unreadbooks',
      DiscoverType.surprise: '/surprise',
    };

    String basePath = paths[type] ?? '/opds/discover';

    return subPath != null ? '$basePath/$subPath' : basePath;
  }

  String _getCategoryPath(CategoryType type, String? subPath) {
    final Map<CategoryType, String> paths = {
      CategoryType.author: '/opds/author',
      CategoryType.category: '/opds/category',
      CategoryType.series: '/opds/series',
      CategoryType.publisher: '/opds/publisher',
      CategoryType.language: '/opds/language',
      CategoryType.formats: '/opds/formats',
      CategoryType.ratings: '/opds/ratings',
      CategoryType.libraries: '/libraries',
    };

    String basePath = paths[type] ?? '/opds/category';
    return subPath != null ? '$basePath/$subPath' : basePath;
  }
}
