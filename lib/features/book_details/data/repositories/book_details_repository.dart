import 'dart:typed_data';

import 'package:docman/docman.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/book_details/data/datasources/book_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';

class BookDetailsRepository {
  final BookDetailsRemoteDatasource datasource;
  final Logger logger;

  BookDetailsRepository({required this.datasource, required this.logger});

  Future<BookDetailsModel> getBookDetails(
    BookViewModel bookListModel,
    String bookUuid,
  ) async {
    try {
      return await datasource.fetchBookDetails(bookListModel, bookUuid);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> toggleReadStatus(int bookId) async {
    try {
      return await datasource.toggleReadStatus(bookId);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> toggleArchiveStatus(int bookId) async {
    try {
      return await datasource.toggleArchiveStatus(bookId);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> openInReader(
    BookDetailsModel book,
    DocumentFile selectedDirectory,
    DownloadSchema schema, {
    Function(int)? progressCallback,
  }) async {
    try {
      return await datasource.openInReader(
        book,
        selectedDirectory,
        schema,
        progressCallback: progressCallback,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openInBrowser(BookDetailsModel book) async {
    try {
      await datasource.openInBrowser(book);
    } catch (e) {
      rethrow;
    }
  }

  Future<StreamedResponse> getDownloadStream(
    String bookId,
    String format,
  ) async {
    try {
      return await datasource.getDownloadStream(bookId, format);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateBookMetadata(
    String bookId, {
    required String title,
    required String authors,
    required String comments,
    required String tags,
    Uint8List? coverImageBytes,
    String? coverFileName,
  }) async {
    try {
      return await datasource.updateBookMetadata(
        bookId,
        title: title,
        authors: authors,
        comments: comments,
        tags: tags,
        coverImageBytes: coverImageBytes,
        coverFileName: coverFileName,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> sendBookViaEmail(
    String bookId,
    String format,
    int conversion,
  ) async {
    try {
      return await datasource.sendBookViaEmail(bookId, format, conversion);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> uploadToSend2Ereader(
    String url,
    String code,
    String filename,
    List<int> fileBytes, {
    bool isKindle = false,
    Function(int)? onProgressUpdate,
  }) async {
    try {
      return datasource.uploadToSend2Ereader(
        url,
        code,
        filename,
        fileBytes,
        isKindle: isKindle,
        onProgressUpdate: onProgressUpdate,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String> downloadBook(
    BookDetailsModel book,
    DocumentFile selectedDirectory,
    DownloadSchema schema, {
    String format = 'epub',
    Function(int)? progressCallback,
  }) async {
    try {
      return await datasource.downloadBook(
        book,
        selectedDirectory,
        schema,
        format: format,
        progressCallback: progressCallback,
      );
    } catch (e) {
      logger.e('Error downloading book: $e');
      rethrow;
    }
  }
}
