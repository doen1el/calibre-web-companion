import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover_details/data/datasources/discover_details_datasource.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_feed_model.dart';

class DiscoverDetailsRepository {
  final DiscoverDetailsDatasource dataSource;

  DiscoverDetailsRepository({required this.dataSource});

  Future<DiscoverFeedModel> loadBooks(
    DiscoverType type, {
    String? subPath,
  }) async {
    try {
      final books = await dataSource.loadBooks(type, subPath: subPath);
      return books;
    } catch (e) {
      throw Exception('Failed to load books: $e');
    }
  }

  Future<CategoryFeed> loadCategories(
    CategoryType type, {
    String? subPath,
  }) async {
    try {
      final categories = await dataSource.loadCategories(
        type,
        subPath: subPath,
      );
      return categories;
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<DiscoverFeedModel> loadBooksFromPath(String fullPath) async {
    try {
      final books = await dataSource.loadBooksFromPath(fullPath);
      return books;
    } catch (e) {
      throw Exception('Failed to load books from path: $e');
    }
  }
}
