import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/download_service/data/datasources/download_service_remote_datasource.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_status.dart';

class DownloadServiceRepository {
  final DownloadServiceRemoteDataSource remoteDataSource;
  final Logger logger;

  DownloadServiceRepository({
    required this.remoteDataSource,
    required this.logger,
  });

  Future<List<DownloadServiceBookModel>> searchBooks(String query) async {
    try {
      return await remoteDataSource.searchBooks(query);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> downloadBook(String bookId) async {
    try {
      return await remoteDataSource.downloadBook(bookId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DownloadServiceBookModel>> getDownloadStatus() async {
    try {
      return await remoteDataSource.getDownloadStatus();
    } catch (e) {
      rethrow;
    }
  }

  List<DownloadServiceBookModel> getBooksByStatus(
    List<DownloadServiceBookModel> books,
    DownloaderStatus status,
  ) {
    return books.where((book) => book.status == status).toList();
  }
}
