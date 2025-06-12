import 'package:calibre_web_companion/features/shelf_view.dart/data/datasources/shelf_view_datasource.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_list_view_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';

class ShelfViewRepository {
  final ShelfViewDataSource dataSource;

  ShelfViewRepository({required this.dataSource});

  Future<ShelfListViewModel> loadShelves() async {
    try {
      final shelves = await dataSource.loadShelves();
      return shelves;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> createShelf(String shelfName) async {
    try {
      final result = await dataSource.createShelf(shelfName);
      return result;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> removeBookFromShelf({
    required String bookId,
    required String shelfId,
  }) async {
    try {
      await dataSource.removeBookFromShelf(bookId: bookId, shelfId: shelfId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> addBookToShelf({
    required String bookId,
    required String shelfId,
  }) async {
    try {
      await dataSource.addBookToShelf(bookId: bookId, shelfId: shelfId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<ShelfViewModel>> findShelvesContainingBook(String bookId) async {
    try {
      final shelves = await dataSource.findShelvesContainingBook(bookId);
      return shelves;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
