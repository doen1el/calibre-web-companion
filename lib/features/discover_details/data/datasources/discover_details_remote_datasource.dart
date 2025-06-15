import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_details_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_feed_model.dart';
import 'package:logger/logger.dart';

class DiscoverDetailsRemoteDatasource {
  final ApiService apiService;
  final Logger logger;

  DiscoverDetailsRemoteDatasource({
    required this.apiService,
    required this.logger,
  });

  Future<DiscoverFeedModel> loadBooks(
    DiscoverType type, {
    String? subPath,
  }) async {
    try {
      final String path = _getBookListPath(type, subPath);
      final jsonData = await apiService.getXmlAsJson(
        endpoint: path,
        authMethod: AuthMethod.basic,
      );

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
        authMethod: AuthMethod.basic,
      );

      final dynamic entryData = jsonData['feed']["entry"];
      final List<dynamic> items = entryData is List ? entryData : [entryData];
      final categories =
          items.map((item) => CategoryModel.fromJson(item)).toList();

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
      final jsonData = await apiService.getXmlAsJson(
        endpoint: fullPath,
        authMethod: AuthMethod.basic,
      );

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

  String _getBookListPath(DiscoverType type, String? subPath) {
    final Map<DiscoverType, String> paths = {
      DiscoverType.discover: '/opds/discover',
      DiscoverType.hot: '/opds/hot',
      DiscoverType.newlyAdded: '/opds/new',
      DiscoverType.rated: '/opds/rated',
      DiscoverType.readbooks: '/opds/readbooks',
      DiscoverType.unreadbooks: '/opds/unreadbooks',
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
    };

    String basePath = paths[type] ?? '/opds/category';
    return subPath != null ? '$basePath/$subPath' : basePath;
  }
}
