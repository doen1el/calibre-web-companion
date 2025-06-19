import 'package:calibre_web_companion/features/shelf_details/data/datasources/shelf_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';

class ShelfDetailsRepository {
  final ShelfDetailsRemoteDataSource dataSource;

  ShelfDetailsRepository({required this.dataSource});

  Future<ShelfDetailsModel> getShelfDetails(String shelfId) async {
    try {
      final shelfDetails = await dataSource.getShelfDetails(shelfId);
      return shelfDetails;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> removeFromShelf(String shelfId, String bookId) async {
    try {
      final result = await dataSource.removeFromShelf(shelfId, bookId);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> editShelf(String shelfId, String newShelfName) async {
    try {
      final result = await dataSource.editShelf(shelfId, newShelfName);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteShelf(String shelfId) async {
    try {
      final result = await dataSource.deleteShelf(shelfId);
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
