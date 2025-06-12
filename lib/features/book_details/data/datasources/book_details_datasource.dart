import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:calibre_web_companion/features/book_details/data/models/form_metadata_model.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/json_service.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class BookDetailsDatasource {
  final ApiService _apiService;
  // final JsonService _jsonService;
  final Logger _logger;

  BookDetailsDatasource({
    ApiService? apiService,
    JsonService? jsonService,
    Logger? logger,
  }) : _apiService = apiService ?? ApiService(),
       //  _jsonService = jsonService ?? JsonService(),
       _logger = logger ?? Logger();

  Future<BookDetailsModel> fetchBookDetails(
    BookViewModel bookListModel,
    String bookUuid,
  ) async {
    try {
      final response = await _apiService.get(
        '/ajax/book/$bookUuid',
        AuthMethod.basic,
      );

      _logger.d(response.body);

      if (response.statusCode == 200) {
        try {
          // Try parsing the JSON response
          final bookJson = json.decode(response.body);
          final book = BookDetailsModel.fromBookListModel(
            bookListModel,
            bookJson,
          );
          _logger.i("Fetched book details: ${book.title}");

          return book;
        } catch (jsonError) {
          _logger.w('JSON parsing failed: $jsonError.');
          throw Exception('Failed to parse book details JSON: $jsonError');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e("Error fetching book details: $e");
      throw Exception("Failed to fetch book details: $e");
    }
  }

  Future<bool> toggleReadStatus(int bookId) async {
    try {
      _logger.i('Toggling read status for book: $bookId');

      final response = await _apiService.post(
        '/ajax/toggleread/$bookId',
        null,
        {},
        AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode == 200) {
        _logger.i('Successfully toggled read status');
        return true;
      } else {
        _logger.e('Failed to toggle read status: ${response.statusCode}');
        throw Exception(
          'Failed to toggle read status (${response.statusCode})',
        );
      }
    } catch (e) {
      _logger.e('Error toggling read status: $e');
      throw Exception('Error toggling read status: $e');
    }
  }

  Future<bool> toggleArchiveStatus(int bookId) async {
    try {
      _logger.i('Toggling archive status for book: $bookId');

      final response = await _apiService.post(
        '/ajax/togglearchived/$bookId',
        null,
        {},
        AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode == 200) {
        _logger.i('Successfully toggled archive status');
        return true;
      } else {
        _logger.e('Failed to toggle archive status: ${response.statusCode}');
        throw Exception(
          'Failed to toggle archive status (${response.statusCode})',
        );
      }
    } catch (e) {
      _logger.e('Error toggling archive status: $e');
      throw Exception('Error toggling archive status: $e');
    }
  }

  Future<bool> checkIfBookIsRead(int bookId) async {
    try {
      _logger.i('Checking if book is read: $bookId');

      final response = await _apiService.get(
        '/read/stored/',
        AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        final pattern = 'href="/book/$bookId"';
        final isRead = response.body.contains(pattern);
        _logger.i("Book $bookId read status: $isRead");
        return isRead;
      } else {
        _logger.w("Failed to check read status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      _logger.e('Error checking if book is read: $e');
      return false;
    }
  }

  Future<bool> checkIfBookIsArchived(int bookId) async {
    try {
      _logger.i('Checking if book is archived: $bookId');

      final response = await _apiService.get(
        '/archived/stored/',
        AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        final pattern = 'href="/book/$bookId"';
        final isArchived = response.body.contains(pattern);
        _logger.i("Book $bookId archived status: $isArchived");
        return isArchived;
      } else {
        _logger.w("Failed to check archived status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      _logger.e('Error checking if book is archived: $e');
      return false;
    }
  }

  Future<Uint8List?> downloadBookBytes(String bookId, String format) async {
    try {
      _logger.i('Downloading book bytes - BookId: $bookId, Format: $format');

      final response = await _apiService.getStream(
        '/download/$bookId/$format/$bookId.$format',
        AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        _logger.i('Successfully downloaded book bytes');
        return await response.stream.toBytes();
      } else {
        _logger.e('Error downloading book bytes: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Exception downloading book bytes: $e');
      throw Exception('Failed to download book bytes: $e');
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
        _logger.i('File already exists: $filePath');
        return filePath;
      }

      await Directory(path.dirname(filePath)).create(recursive: true);

      final tempFilePath = '$filePath.downloading';
      final tempFile = File(tempFilePath);

      final response = await _apiService.getStream(
        '/download/${book.id}/$format/${book.id}.$format',
        AuthMethod.cookie,
      );

      final contentLength = response.contentLength ?? -1;
      _logger.i(
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
            _logger.d(
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

        _logger.i('Download complete: $filePath with $receivedBytes bytes');
        return filePath;
      } catch (e) {
        _logger.e('Error during download: $e');

        await sink.close();

        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        rethrow;
      }
    } catch (e) {
      _logger.e('Exception while downloading book: $e');
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

    _logger.d('Created path based on schema $schema: $filePath');
    return filePath;
  }

  Future<bool> sendViaEmail(
    String bookId,
    String format,
    int conversion,
  ) async {
    try {
      _logger.i(
        'Sending book via email - BookId: $bookId, Format: $format, Conversion: $conversion',
      );

      final response = await _apiService.post(
        '/send/$bookId/$format/$conversion',
        null,
        {},
        AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        _logger.i('Successfully sent book via email');
        return true;
      } else {
        _logger.e('Failed to send book via email: ${response.statusCode}');
        throw Exception('Failed to send email (${response.statusCode})');
      }
    } catch (e) {
      _logger.e('Error sending book via email: $e');
      throw Exception('Error sending book via email: $e');
    }
  }

  Future<bool> openInReader(
    BookDetailsModel book,
    String selectedDirectory,
    DownloadSchema schema,
  ) async {
    try {
      _logger.i('Opening book in reader: ${book.title}');

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
        _logger.e('Error downloading file for reader');
        throw Exception('Error downloading file');
      }

      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        _logger.e('Error while opening the file: ${result.message}');
        throw Exception('Error while opening: ${result.message}');
      }

      _logger.i('Opened book successfully');
      return true;
    } catch (e) {
      _logger.e('Error opening book in reader: $e');
      throw Exception('Error opening book in reader: $e');
    }
  }

  Future<void> openInBrowser(BookDetailsModel book) async {
    try {
      final baseUrl = _apiService.getBaseUrl();

      if (baseUrl.isEmpty) {
        _logger.w('No server URL found');
        throw Exception('Server URL missing');
      }

      final Uri url = Uri.parse('$baseUrl/book/${book.id}');

      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }

      _logger.i('Opened book in browser: $url');
    } catch (e) {
      _logger.e('Error opening book in browser: $e');
      throw Exception('Error opening book in browser: $e');
    }
  }

  Future<StreamedResponse> getDownloadStream(
    String bookId,
    String format,
  ) async {
    try {
      _logger.i('Getting download stream for book: $bookId, Format: $format');

      final response = await _apiService.getStream(
        '/download/$bookId/$format/$bookId.$format',
        AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        _logger.i('Successfully got download stream');
        return response;
      } else {
        _logger.e('Failed to get download stream: ${response.statusCode}');
        throw Exception(
          'Failed to get download stream (${response.statusCode})',
        );
      }
    } catch (e) {
      _logger.e('Error getting download stream: $e');
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
      final response = await _apiService.post(
        '/admin/book/$bookId',
        null,
        {
          'title': title,
          'authors': authors,
          'description': comments,
          'tags': tags,
        },
        AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        _logger.i('Successfully updated book metadata');
        return true;
      } else {
        _logger.e('Failed to update book metadata: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Error updating book metadata: $e');
      throw Exception('Failed to update book metadata: $e');
    }
  }

  // ...existing code...

  /// Upload book to send2ereader service via browser method
  Future<bool> uploadToSend2Ereader(
    String url,
    String code,
    String filename,
    Uint8List fileBytes, {
    bool isKindle = false,
  }) async {
    try {
      _logger.i(
        'Uploading to send2ereader - URL: $url, Code: $code, Kindle: $isKindle',
      );

      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      // Add form fields
      request.fields['code'] = code;
      if (isKindle) {
        request.fields['kindle'] = 'true';
      }

      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _logger.i('Successfully uploaded to send2ereader');
        return true;
      } else {
        _logger.e('Failed to upload to send2ereader: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error uploading to send2ereader: $e');
      return false;
    }
  }

  /// Send book via email using the Calibre-Web email functionality
  Future<bool> sendBookViaEmail(
    String bookId,
    String format,
    int conversion,
  ) async {
    try {
      _logger.i(
        'Sending book via email - BookId: $bookId, Format: $format, Conversion: $conversion',
      );

      final response = await _apiService.post(
        '/send/$bookId/$format/$conversion',
        null,
        {},
        AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        _logger.i('Successfully sent book via email');
        return true;
      } else {
        _logger.e('Failed to send book via email: ${response.statusCode}');
        throw Exception('Failed to send email (${response.statusCode})');
      }
    } catch (e) {
      _logger.e('Error sending book via email: $e');
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
      _logger.i('Opening book in reader - BookId: $bookId');

      // First, get book details to determine available formats
      final bookDetailsResponse = await _apiService.get(
        '/ajax/book/$bookId',
        AuthMethod.basic,
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

      _logger.i('Using format for reader: $format');

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
        ratings: (bookJson['ratings'] ?? 0.0).toDouble(),
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

      _logger.i('Successfully opened book in reader');
      return true;
    } catch (e) {
      _logger.e('Error opening book in reader: $e');
      throw Exception('Error opening book in reader: $e');
    }
  }

  /// Open book in web browser
  Future<bool> openBookInBrowser(String bookId) async {
    try {
      final baseUrl = _apiService.getBaseUrl();

      if (baseUrl.isEmpty) {
        throw Exception('Server URL not configured');
      }

      final Uri url = Uri.parse('$baseUrl/book/$bookId');

      if (!await launchUrl(url)) {
        throw Exception('Could not launch browser with URL: $url');
      }

      _logger.i('Successfully opened book in browser: $url');
      return true;
    } catch (e) {
      _logger.e('Error opening book in browser: $e');
      throw Exception('Error opening book in browser: $e');
    }
  }

  /// Add book to a specific shelf
  Future<bool> addBookToShelf(String shelfId, String bookId) async {
    try {
      _logger.i('Adding book $bookId to shelf $shelfId');

      final response = await _apiService.post(
        '/shelf/add/$shelfId/$bookId',
        null,
        {},
        AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        _logger.i('Successfully added book to shelf');
        return true;
      } else {
        _logger.e('Failed to add book to shelf: ${response.statusCode}');
        throw Exception('Failed to add book to shelf (${response.statusCode})');
      }
    } catch (e) {
      _logger.e('Error adding book to shelf: $e');
      throw Exception('Error adding book to shelf: $e');
    }
  }

  /// Remove book from a specific shelf
  Future<bool> removeBookFromShelf(String shelfId, String bookId) async {
    try {
      _logger.i('Removing book $bookId from shelf $shelfId');

      final response = await _apiService.post(
        '/shelf/remove/$shelfId/$bookId',
        null,
        {},
        AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        _logger.i('Successfully removed book from shelf');
        return true;
      } else {
        _logger.e('Failed to remove book from shelf: ${response.statusCode}');
        throw Exception(
          'Failed to remove book from shelf (${response.statusCode})',
        );
      }
    } catch (e) {
      _logger.e('Error removing book from shelf: $e');
      throw Exception('Error removing book from shelf: $e');
    }
  }

  /// Get download stream with progress tracking for large files
  Future<StreamedResponse> getDownloadStreamWithProgress(
    String bookId,
    String format,
  ) async {
    try {
      _logger.i(
        'Getting download stream with progress - BookId: $bookId, Format: $format',
      );

      final response = await _apiService.getStream(
        '/download/$bookId/$format/$bookId.$format',
        AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        _logger.i('Successfully got download stream with progress tracking');
        return response;
      } else {
        _logger.e('Failed to get download stream: ${response.statusCode}');
        throw Exception(
          'Failed to get download stream (${response.statusCode})',
        );
      }
    } catch (e) {
      _logger.e('Error getting download stream with progress: $e');
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
      _logger.i('Checking if format $format is available for book $bookId');

      final response = await _apiService.get(
        '/ajax/book/$bookId',
        AuthMethod.basic,
      );

      if (response.statusCode == 200) {
        final bookJson = json.decode(response.body);
        final formats = List<String>.from(bookJson['formats'] ?? []);

        final isAvailable = formats.any(
          (f) => f.toLowerCase() == format.toLowerCase(),
        );

        _logger.i('Format $format availability for book $bookId: $isAvailable');
        return isAvailable;
      } else {
        _logger.e(
          'Failed to check format availability: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      _logger.e('Error checking format availability: $e');
      return false;
    }
  }

  /// Get book file size for a specific format
  Future<int?> getBookFileSize(String bookId, String format) async {
    try {
      _logger.i('Getting file size for book $bookId, format $format');

      final response = await _apiService.get(
        '/ajax/book/$bookId',
        AuthMethod.basic,
      );

      if (response.statusCode == 200) {
        final bookJson = json.decode(response.body);
        final formatSizes = Map<String, int>.from(
          bookJson['format_sizes'] ?? {},
        );

        final size = formatSizes[format.toUpperCase()];

        _logger.i('File size for book $bookId ($format): ${size ?? 'unknown'}');
        return size;
      } else {
        _logger.e('Failed to get file size: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting file size: $e');
      return null;
    }
  }
}
