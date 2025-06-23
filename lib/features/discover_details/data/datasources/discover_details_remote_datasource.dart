import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
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

  Future<BookViewModel> loadBookDetails(String bookId) async {
    try {
      logger.i('Loading book details for bookId: $bookId');
      List<BookViewModel> books = [];
      bool foundBook = false;
      BookViewModel? targetBook;

      final int limit = 100;
      bool hasMoreBooks = true;

      while (hasMoreBooks && !foundBook) {
        final queryParams = {'limit': limit.toString(), 'order': 'asc'};

        logger.i('Loading books with limit $limit');

        final response = await apiService.getJson(
          endpoint: '/ajax/listbooks',
          authMethod: AuthMethod.cookie,
          queryParams: queryParams,
        );

        if (response.containsKey('rows') && response['rows'] is List) {
          final List<dynamic> rows = response['rows'];

          if (rows.isEmpty) {
            // No more books to load
            hasMoreBooks = false;
            logger.i('Received empty book list');
            break;
          }

          for (var bookData in rows) {
            try {
              final book = BookViewModel.fromJson(bookData);

              if (book.uuid == bookId) {
                targetBook = book;
                foundBook = true;
                logger.i('Found target book with id $bookId');
                break;
              }

              books.add(book);
            } catch (e) {
              logger.e('Error parsing book: $e');
            }
          }

          if (response.containsKey('total') && response.containsKey('page')) {
            final int total = response['total'];
            final int currentPage = response['page'];
            final int totalPages = (total / limit).ceil();

            hasMoreBooks = currentPage < totalPages;
            logger.i('Page $currentPage of $totalPages (total books: $total)');
          } else {
            hasMoreBooks = rows.length >= limit;
            logger.i('Loaded ${rows.length} books');
          }

          if (foundBook) break;
        } else {
          hasMoreBooks = false;
          logger.e('Invalid response format, missing "rows" array');
        }
      }

      if (targetBook != null) {
        return targetBook;
      } else {
        logger.e(
          'Book with id $bookId not found after loading ${books.length} books',
        );
        throw Exception('Book with ID $bookId not found');
      }
    } catch (e) {
      logger.e('Error loading book details: $e');
      throw Exception('Failed to load book details: $e');
    }
  }
}
