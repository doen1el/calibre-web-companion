import 'dart:typed_data';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/book_details/data/datasources/book_details_datasource.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class BookDetailsRepository {
  final BookDetailsDatasource _datasource;
  final Logger _logger;

  BookDetailsRepository({
    required BookDetailsDatasource datasource,
    Logger? logger,
  }) : _datasource = datasource,
       _logger = logger ?? Logger();

  Future<BookDetailsModel> getBookDetails(
    BookViewModel bookListModel,
    String bookUuid,
  ) async {
    try {
      return await _datasource.fetchBookDetails(bookListModel, bookUuid);
    } catch (e) {
      _logger.e('Error fetching book details: $e');
      throw Exception('Failed to load book details');
    }
  }

  Future<bool> toggleReadStatus(int bookId) async {
    try {
      return await _datasource.toggleReadStatus(bookId);
    } catch (e) {
      _logger.e('Error toggling read status: $e');
      throw Exception('Failed to toggle read status');
    }
  }

  Future<bool> toggleArchiveStatus(int bookId) async {
    try {
      return await _datasource.toggleArchiveStatus(bookId);
    } catch (e) {
      _logger.e('Error toggling archive status: $e');
      throw Exception('Failed to toggle archive status');
    }
  }

  Future<bool> checkIfBookIsRead(int bookId) async {
    try {
      return await _datasource.checkIfBookIsRead(bookId);
    } catch (e) {
      _logger.e('Error checking read status: $e');
      return false;
    }
  }

  Future<bool> checkIfBookIsArchived(int bookId) async {
    try {
      return await _datasource.checkIfBookIsArchived(bookId);
    } catch (e) {
      _logger.e('Error checking archive status: $e');
      return false;
    }
  }

  Future<Uint8List?> downloadBookBytes(String bookId, String format) async {
    try {
      return await _datasource.downloadBookBytes(bookId, format);
    } catch (e) {
      _logger.e('Error downloading book bytes: $e');
      throw Exception('Failed to download book');
    }
  }

  Future<String> downloadBook(
    BookDetailsModel book,
    String selectedDirectory,
    DownloadSchema schema, {
    String format = 'epub',
    Function(int)? progressCallback,
  }) async {
    try {
      return await _datasource.downloadBook(
        book,
        selectedDirectory,
        schema,
        format: format,
        progressCallback: progressCallback,
      );
    } catch (e) {
      _logger.e('Error downloading book: $e');
      throw Exception('Failed to download book');
    }
  }

  Future<bool> sendViaEmail(
    String bookId,
    String format,
    int conversion,
  ) async {
    try {
      return await _datasource.sendViaEmail(bookId, format, conversion);
    } catch (e) {
      _logger.e('Error sending book via email: $e');
      throw Exception('Failed to send book via email');
    }
  }

  Future<bool> openInReader(
    BookDetailsModel book,
    String selectedDirectory,
    DownloadSchema schema,
  ) async {
    try {
      return await _datasource.openInReader(book, selectedDirectory, schema);
    } catch (e) {
      _logger.e('Error opening book in reader: $e');
      throw Exception('Failed to open book in reader');
    }
  }

  Future<void> openInBrowser(BookDetailsModel book) async {
    try {
      await _datasource.openInBrowser(book);
    } catch (e) {
      _logger.e('Error opening book in browser: $e');
      throw Exception('Failed to open book in browser');
    }
  }

  Future<StreamedResponse> getDownloadStream(
    String bookId,
    String format,
  ) async {
    return await _datasource.getDownloadStream(bookId, format);
  }

  Future<bool> updateBookMetadata(
    String bookId, {
    required String title,
    required String authors,
    required String comments,
    required String tags,
  }) async {
    return await _datasource.updateBookMetadata(
      bookId,
      title: title,
      authors: authors,
      comments: comments,
      tags: tags,
    );
  }

  Future<bool> sendBookViaEmail(
    String bookId,
    String format,
    int conversion,
  ) async {
    return await _datasource.sendBookViaEmail(bookId, format, conversion);
  }

  Future<bool> uploadToSend2Ereader(
    String url,
    String code,
    String filename,
    Uint8List fileBytes, {
    bool isKindle = false,
  }) async {
    return await _datasource.uploadToSend2Ereader(
      url,
      code,
      filename,
      fileBytes,
      isKindle: isKindle,
    );
  }
}
