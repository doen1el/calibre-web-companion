import 'package:calibre_web_companion/features/shelf_view.dart/data/datasources/shelf_view_remote_datasource.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_list_view_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/magic_shelf_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/magic_rule_models.dart';

class ShelfViewRepository {
  final ShelfViewRemoteDataSource dataSource;

  ShelfViewRepository({required this.dataSource});

  Future<ShelfListViewModel> loadShelves() async {
    try {
      final shelves = await dataSource.loadShelves();
      return shelves;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createShelf(String shelfName, bool isPublic) async {
    try {
      final result = await dataSource.createShelf(
        shelfName,
        isPublic: isPublic,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeBookFromShelf({
    required String bookId,
    required String shelfId,
  }) async {
    try {
      await dataSource.removeBookFromShelf(bookId: bookId, shelfId: shelfId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addBookToShelf({
    required String bookId,
    required String shelfId,
  }) async {
    try {
      await dataSource.addBookToShelf(bookId: bookId, shelfId: shelfId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ShelfViewModel>> findShelvesContainingBook(String bookId) async {
    try {
      final shelves = await dataSource.findShelvesContainingBook(bookId);
      return shelves;
    } catch (e) {
      rethrow;
    }
  }

  bool getIsOpds() => dataSource.getIsOpds();

  Future<bool> supportsMagicShelves() => dataSource.supportsMagicShelves();

  Future<MagicShelfListModel> loadMagicShelves() =>
      dataSource.loadMagicShelves();

  Future<void> deleteMagicShelf(String shelfId) =>
      dataSource.deleteMagicShelf(shelfId);

  Future<String> duplicateMagicShelf(String shelfId) =>
      dataSource.duplicateMagicShelf(shelfId);

  Future<void> hideMagicShelf(String shelfId) =>
      dataSource.hideMagicShelf(shelfId);

  Future<void> unhideMagicShelf(String shelfId) =>
      dataSource.unhideMagicShelf(shelfId);

  Future<String> createMagicShelf({
    required String name,
    required Map<String, dynamic> rules,
    required String icon,
    bool koboSync = false,
    bool isPublic = false,
  }) => dataSource.createMagicShelf(
    name: name,
    rules: rules,
    icon: icon,
    koboSync: koboSync,
    isPublic: isPublic,
  );

  Future<void> editMagicShelf({
    required String shelfId,
    required String name,
    required Map<String, dynamic> rules,
    required String icon,
    bool koboSync = false,
    bool isPublic = false,
  }) => dataSource.editMagicShelf(
    shelfId: shelfId,
    name: name,
    rules: rules,
    icon: icon,
    koboSync: koboSync,
    isPublic: isPublic,
  );

  Future<Map<String, dynamic>> previewMagicShelf(Map<String, dynamic> rules) =>
      dataSource.previewMagicShelf(rules);

  Future<MagicShelfFormData> getMagicShelfFormData({String? shelfId}) =>
      dataSource.getMagicShelfFormData(shelfId: shelfId);

  Future<List<MagicShelfModel>> findMagicShelvesContainingBook(String bookId) =>
      dataSource.findMagicShelvesContainingBook(bookId);
}
