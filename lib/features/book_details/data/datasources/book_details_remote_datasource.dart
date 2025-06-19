import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:calibre_web_companion/core/services/tag_service.dart';
import 'package:calibre_web_companion/features/book_details/data/models/tag_model.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/book_details/data/models/form_metadata_model.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class BookDetailsRemoteDatasource {
  final ApiService apiService;
  final Logger logger;
  final TagService tagService;

  BookDetailsRemoteDatasource({
    required this.apiService,
    required this.logger,
    required this.tagService,
  });

  Future<BookDetailsModel> fetchBookDetails(
    BookViewModel bookListModel,
    String bookUuid,
  ) async {
    try {
      if (!tagService.isInitialized) {
        await tagService.initialize();
      }

      final response = await apiService.getJson(
        endpoint: '/ajax/book/$bookUuid',
        authMethod: AuthMethod.basic,
      );

      return BookDetailsModel.fromBookListModel(
        bookListModel,
        response,
        tagService,
      );
    } catch (e) {
      logger.e("Error fetching book details: $e");
      throw Exception("Failed to fetch book details: $e");
    }
  }

  Future<bool> toggleReadStatus(int bookId) async {
    try {
      logger.i('Toggling read status for book: $bookId');

      final response = await apiService.post(
        endpoint: '/ajax/toggleread/$bookId',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode == 200) {
        logger.i('Successfully toggled read status');
        return true;
      } else {
        logger.e('Failed to toggle read status: ${response.statusCode}');
        throw Exception(
          'Failed to toggle read status (${response.statusCode})',
        );
      }
    } catch (e) {
      logger.e('Error toggling read status: $e');
      throw Exception('Error toggling read status: $e');
    }
  }

  Future<bool> toggleArchiveStatus(int bookId) async {
    try {
      logger.i('Toggling archive status for book: $bookId');

      final response = await apiService.post(
        endpoint: '/ajax/togglearchived/$bookId',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode == 200) {
        logger.i('Successfully toggled archive status');
        return true;
      } else {
        logger.e('Failed to toggle archive status: ${response.statusCode}');
        throw Exception(
          'Failed to toggle archive status (${response.statusCode})',
        );
      }
    } catch (e) {
      logger.e('Error toggling archive status: $e');
      throw Exception('Error toggling archive status: $e');
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
      String filePath = await _createPathBasedOnSchema(
        selectedDirectory,
        book,
        format,
        schema,
      );

      final file = File(filePath);
      if (await file.exists()) {
        logger.i('File already exists: $filePath');
        return filePath;
      }

      await Directory(path.dirname(filePath)).create(recursive: true);

      final tempFilePath = '$filePath.downloading';
      final tempFile = File(tempFilePath);

      final response = await apiService.getStream(
        endpoint: '/download/${book.id}/$format/${book.id}.$format',
        authMethod: AuthMethod.cookie,
      );

      final contentLength = response.contentLength ?? -1;
      logger.i(
        'Download response status: ${response.statusCode}, Content length: $contentLength',
      );

      final sink = tempFile.openWrite();
      int receivedBytes = 0;

      try {
        await for (final chunk in response.stream) {
          receivedBytes += chunk.length;
          sink.add(chunk);

          if (contentLength > 0 && progressCallback != null) {
            final progress = (receivedBytes / contentLength * 100).round();
            progressCallback(progress);
            logger.d(
              'Download progress: $progress%, $receivedBytes/$contentLength bytes',
            );
          }
        }

        await sink.flush();
        await sink.close();

        if (await tempFile.exists()) {
          await tempFile.rename(filePath);
        } else {
          throw Exception('Temporary file was not created correctly');
        }

        logger.i('Download complete: $filePath with $receivedBytes bytes');
        return filePath;
      } catch (e) {
        logger.e('Error during download: $e');

        await sink.close();

        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        rethrow;
      }
    } catch (e) {
      logger.e('Exception while downloading book: $e');
      throw Exception('Error downloading book: $e');
    }
  }

  Future<String> _createPathBasedOnSchema(
    String baseDirectory,
    BookDetailsModel book,
    String format,
    DownloadSchema schema,
  ) async {
    // Sanitize the file name to prevent invalid characters
    final safeTitle = book.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final safeAuthor = book.authors.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = '$safeTitle.$format';
    String? safeSeries;

    if (book.series.isNotEmpty) {
      safeSeries = book.series.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    }

    String filePath;
    Directory directory;

    switch (schema) {
      case DownloadSchema.flat:
        filePath = path.join(baseDirectory, fileName);
        break;

      case DownloadSchema.authorOnly:
        final authorDir = path.join(baseDirectory, safeAuthor);
        directory = Directory(authorDir);
        await directory.create(recursive: true);
        filePath = path.join(authorDir, fileName);
        break;

      case DownloadSchema.authorBook:
        final bookDir = path.join(baseDirectory, safeAuthor, safeTitle);
        directory = Directory(bookDir);
        await directory.create(recursive: true);
        filePath = path.join(bookDir, fileName);
        break;

      case DownloadSchema.authorSeriesBook:
        if (safeSeries != null && safeSeries.isNotEmpty) {
          final bookDir = path.join(
            baseDirectory,
            safeAuthor,
            safeSeries,
            safeTitle,
          );
          directory = Directory(bookDir);
          await directory.create(recursive: true);
          filePath = path.join(bookDir, fileName);
        } else {
          final bookDir = path.join(baseDirectory, safeAuthor, safeTitle);
          directory = Directory(bookDir);
          await directory.create(recursive: true);
          filePath = path.join(bookDir, fileName);
        }
        break;
    }

    logger.d('Created path based on schema $schema: $filePath');
    return filePath;
  }

  Future<bool> sendViaEmail(
    String bookId,
    String format,
    int conversion,
  ) async {
    try {
      logger.i(
        'Sending book via email - BookId: $bookId, Format: $format, Conversion: $conversion',
      );

      final response = await apiService.post(
        endpoint: '/send/$bookId/$format/$conversion',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        logger.i('Successfully sent book via email');
        return true;
      } else {
        logger.e('Failed to send book via email: ${response.statusCode}');
        throw Exception('Failed to send email (${response.statusCode})');
      }
    } catch (e) {
      logger.e('Error sending book via email: $e');
      throw Exception('Error sending book via email: $e');
    }
  }

  Future<bool> openInReader(
    BookDetailsModel book,
    String selectedDirectory,
    DownloadSchema schema,
  ) async {
    try {
      logger.i('Opening book in reader: ${book.title}');

      String format = 'epub';
      if (book.formats.isNotEmpty) {
        format = book.formats.first.toLowerCase();
      }

      final filePath = await downloadBook(
        book,
        selectedDirectory,
        schema,
        format: format,
      );

      if (filePath.isEmpty) {
        logger.e('Error downloading file for reader');
        throw Exception('Error downloading file');
      }

      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        logger.e('Error while opening the file: ${result.message}');
        throw Exception('Error while opening: ${result.message}');
      }

      logger.i('Opened book successfully');
      return true;
    } catch (e) {
      logger.e('Error opening book in reader: $e');
      throw Exception('Error opening book in reader: $e');
    }
  }

  Future<void> openInBrowser(BookDetailsModel book) async {
    try {
      final baseUrl = apiService.getBaseUrl();

      if (baseUrl.isEmpty) {
        logger.w('No server URL found');
        throw Exception('Server URL missing');
      }

      final Uri url = Uri.parse('$baseUrl/book/${book.id}');

      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }

      logger.i('Opened book in browser: $url');
    } catch (e) {
      logger.e('Error opening book in browser: $e');
      throw Exception('Error opening book in browser: $e');
    }
  }

  Future<StreamedResponse> getDownloadStream(
    String bookId,
    String format,
  ) async {
    try {
      logger.i('Getting download stream for book: $bookId, Format: $format');

      final response = await apiService.getStream(
        endpoint: '/download/$bookId/$format/$bookId.$format',
        authMethod: AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        logger.i('Successfully got download stream');
        return response;
      } else {
        logger.e('Failed to get download stream: ${response.statusCode}');
        throw Exception(
          'Failed to get download stream (${response.statusCode})',
        );
      }
    } catch (e) {
      logger.e('Error getting download stream: $e');
      throw Exception('Error getting download stream: $e');
    }
  }

  Future<bool> updateBookMetadata(
    String bookId, {
    required String title,
    required String authors,
    required String comments,
    required String tags,
  }) async {
    try {
      final response = await apiService.post(
        endpoint: '/admin/book/$bookId',
        body: {
          'title': title,
          'authors': authors,
          'comments': comments,
          'tags': tags,
        },
        authMethod: AuthMethod.cookie,
        useCsrf: true,
        contentType: 'text/html; charset=utf-8',
      );

      if (response.statusCode == 302) {
        logger.i('Successfully updated book metadata');
        return true;
      } else {
        logger.e(
          'Failed to update book metadata: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e('Error updating book metadata: $e');
      throw Exception('Failed to update book metadata: $e');
    }
  }

  /// Send book via email using the Calibre-Web email functionality
  Future<bool> sendBookViaEmail(
    String bookId,
    String format,
    int conversion,
  ) async {
    try {
      logger.i(
        'Sending book via email - BookId: $bookId, Format: $format, Conversion: $conversion',
      );

      final response = await apiService.post(
        endpoint: '/send/$bookId/$format/$conversion',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        logger.i('Successfully sent book via email');
        return true;
      } else {
        logger.e('Failed to send book via email: ${response.statusCode}');
        throw Exception('Failed to send email (${response.statusCode})');
      }
    } catch (e) {
      logger.e('Error sending book via email: $e');
      throw Exception('Error sending book via email: $e');
    }
  }

  /// Open book in external reader application
  Future<bool> openBookInReader(
    String bookId,
    String selectedDirectory,
    DownloadSchema schema,
  ) async {
    try {
      logger.i('Opening book in reader - BookId: $bookId');

      // First, get book details to determine available formats
      final bookDetailsResponse = await apiService.get(
        endpoint: '/ajax/book/$bookId',
        authMethod: AuthMethod.basic,
      );

      if (bookDetailsResponse.statusCode != 200) {
        throw Exception('Failed to get book details');
      }

      final bookJson = json.decode(bookDetailsResponse.body);
      final formats = List<String>.from(bookJson['formats'] ?? ['epub']);

      String format = 'epub';
      if (formats.isNotEmpty) {
        format = formats.first.toLowerCase();
      }

      logger.i('Using format for reader: $format');

      // Create a simplified book model for path creation
      final bookForPath = BookDetailsModel(
        id: int.parse(bookId),
        title: bookJson['title'] ?? 'Unknown Title',
        authors: bookJson['authors'] ?? 'Unknown Author',
        comments: bookJson['comments'] ?? '',
        pubdate: bookJson['pubdate'] ?? '',
        publishers: bookJson['publishers'] ?? '',
        tags: List<String>.from(bookJson['tags'] ?? []),
        series: bookJson['series'] ?? '',
        seriesIndex: (bookJson['series_index'] ?? 0.0).toDouble(),
        rating: (bookJson['rating'] ?? 0.0).toDouble(),
        formats: formats,
        uuid: bookJson['uuid'] ?? '',
        thumbnail: bookJson['thumbnail'] ?? '',
        readStatus: bookJson['read_status'] ?? false,
        isArchived: bookJson['is_archived'] ?? false,
        formatMetadata: FormatMetadata.fromJson(
          bookJson['format_metadata'] ?? {},
        ),
        lastModified: bookJson['last_modified'] ?? '',
      );

      // Download the book
      final filePath = await downloadBook(
        bookForPath,
        selectedDirectory,
        schema,
        format: format,
      );

      if (filePath.isEmpty) {
        throw Exception('Failed to download book');
      }

      // Open with default application
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('Failed to open file: ${result.message}');
      }

      logger.i('Successfully opened book in reader');
      return true;
    } catch (e) {
      logger.e('Error opening book in reader: $e');
      throw Exception('Error opening book in reader: $e');
    }
  }

  /// Open book in web browser
  Future<bool> openBookInBrowser(String bookId) async {
    try {
      final baseUrl = apiService.getBaseUrl();

      if (baseUrl.isEmpty) {
        throw Exception('Server URL not configured');
      }

      final Uri url = Uri.parse('$baseUrl/book/$bookId');

      if (!await launchUrl(url)) {
        throw Exception('Could not launch browser with URL: $url');
      }

      logger.i('Successfully opened book in browser: $url');
      return true;
    } catch (e) {
      logger.e('Error opening book in browser: $e');
      throw Exception('Error opening book in browser: $e');
    }
  }

  /// Add book to a specific shelf
  Future<bool> addBookToShelf(String shelfId, String bookId) async {
    try {
      logger.i('Adding book $bookId to shelf $shelfId');

      final response = await apiService.post(
        endpoint: '/shelf/add/$shelfId/$bookId',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        logger.i('Successfully added book to shelf');
        return true;
      } else {
        logger.e('Failed to add book to shelf: ${response.statusCode}');
        throw Exception('Failed to add book to shelf (${response.statusCode})');
      }
    } catch (e) {
      logger.e('Error adding book to shelf: $e');
      throw Exception('Error adding book to shelf: $e');
    }
  }

  /// Remove book from a specific shelf
  Future<bool> removeBookFromShelf(String shelfId, String bookId) async {
    try {
      logger.i('Removing book $bookId from shelf $shelfId');

      final response = await apiService.post(
        endpoint: '/shelf/remove/$shelfId/$bookId',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        logger.i('Successfully removed book from shelf');
        return true;
      } else {
        logger.e('Failed to remove book from shelf: ${response.statusCode}');
        throw Exception(
          'Failed to remove book from shelf (${response.statusCode})',
        );
      }
    } catch (e) {
      logger.e('Error removing book from shelf: $e');
      throw Exception('Error removing book from shelf: $e');
    }
  }

  /// Get download stream with progress tracking for large files
  Future<StreamedResponse> getDownloadStreamWithProgress(
    String bookId,
    String format,
  ) async {
    try {
      logger.i(
        'Getting download stream with progress - BookId: $bookId, Format: $format',
      );

      final response = await apiService.getStream(
        endpoint: '/download/$bookId/$format/$bookId.$format',
        authMethod: AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        logger.i('Successfully got download stream with progress tracking');
        return response;
      } else {
        logger.e('Failed to get download stream: ${response.statusCode}');
        throw Exception(
          'Failed to get download stream (${response.statusCode})',
        );
      }
    } catch (e) {
      logger.e('Error getting download stream with progress: $e');
      throw Exception('Error getting download stream: $e');
    }
  }

  /// Download book and return the file path (used for "Open in Reader" functionality)
  Future<String> downloadBookForReader(
    BookDetailsModel book,
    String selectedDirectory,
    DownloadSchema schema, {
    String format = 'epub',
    Function(int)? progressCallback,
  }) async {
    return await downloadBook(
      book,
      selectedDirectory,
      schema,
      format: format,
      progressCallback: progressCallback,
    );
  }

  /// Validate if a book format is available for download
  Future<bool> isFormatAvailable(String bookId, String format) async {
    try {
      logger.i('Checking if format $format is available for book $bookId');

      final response = await apiService.get(
        endpoint: '/ajax/book/$bookId',
        authMethod: AuthMethod.basic,
      );

      if (response.statusCode == 200) {
        final bookJson = json.decode(response.body);
        final formats = List<String>.from(bookJson['formats'] ?? []);

        final isAvailable = formats.any(
          (f) => f.toLowerCase() == format.toLowerCase(),
        );

        logger.i('Format $format availability for book $bookId: $isAvailable');
        return isAvailable;
      } else {
        logger.e('Failed to check format availability: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logger.e('Error checking format availability: $e');
      return false;
    }
  }

  /// Get book file size for a specific format
  Future<int?> getBookFileSize(String bookId, String format) async {
    try {
      logger.i('Getting file size for book $bookId, format $format');

      final response = await apiService.get(
        endpoint: '/ajax/book/$bookId',
        authMethod: AuthMethod.basic,
      );

      if (response.statusCode == 200) {
        final bookJson = json.decode(response.body);
        final formatSizes = Map<String, int>.from(
          bookJson['format_sizes'] ?? {},
        );

        final size = formatSizes[format.toUpperCase()];

        logger.i('File size for book $bookId ($format): ${size ?? 'unknown'}');
        return size;
      } else {
        logger.e('Failed to get file size: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Error getting file size: $e');
      return null;
    }
  }

  Future<bool> uploadToSend2Ereader(
    String url,
    String code,
    String filename,
    List<int> bookBytes, {
    bool isKindle = false,
    Function(int)? onProgressUpdate,
  }) async {
    try {
      logger.i(
        'Uploading to send2ereader - URL: $url, Code: $code, Kindle: $isKindle',
      );

      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }

      final request = http.MultipartRequest('POST', Uri.parse("$url/upload"));

      request.fields['key'] = code;
      request.fields['kepubify'] = (!isKindle).toString();
      request.fields['kindlegen'] = isKindle.toString();

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bookBytes,
        filename: path.basename(filename),
      );

      request.files.add(multipartFile);

      // Simulate progress before sending (since we can't track real upload progress)
      if (onProgressUpdate != null) {
        onProgressUpdate(20);
        await Future.delayed(const Duration(milliseconds: 200));
        onProgressUpdate(40);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final response = await request.send();

      // Simulate progress after sending
      if (onProgressUpdate != null) {
        onProgressUpdate(70);
        await Future.delayed(const Duration(milliseconds: 200));
        onProgressUpdate(90);
        await Future.delayed(const Duration(milliseconds: 200));
        onProgressUpdate(100);
      }

      // Get response body for error reporting if needed
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        logger.i('Successfully uploaded to send2ereader');
        return true;
      } else {
        logger.e(
          'Failed to upload: ${response.statusCode}, Body: $responseBody',
        );
        return false;
      }
    } catch (e) {
      logger.e('Error uploading to send2ereader: $e');
      return false;
    }
  }
}
