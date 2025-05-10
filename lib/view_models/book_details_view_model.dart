import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/utils/json_service.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:calibre_web_companion/view_models/settings_view_mode.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';

class BookDetailsViewModel extends ChangeNotifier {
  final JsonService _jsonService = JsonService();

  BookItem? _currentBook;
  BookItem? get currentBook => _currentBook;

  final _bookReloadController = StreamController<String>.broadcast();
  Stream<String> get bookReloadStream => _bookReloadController.stream;

  bool _isReloading = false;
  bool get isReloading => _isReloading;

  Logger logger = Logger();
  String? errorMessage;

  bool isDownloading = false;
  int downloaded = 0;

  bool _isBookRead = false;
  bool get isBookRead => _isBookRead;

  bool _isReadToggleLoading = false;
  bool get isReadToggleLoading => _isReadToggleLoading;

  bool _isArchived = false;
  bool get isArchived => _isArchived;

  bool _isArchivedLoading = false;
  bool get isArchivedLoading => _isArchivedLoading;

  int _progress = 0;
  int get progress => _progress;

  bool _isOpeningInReader = false;
  bool get isOpeningInReader => _isOpeningInReader;

  @override
  void dispose() {
    _bookReloadController.close();
    super.dispose();
  }

  /// Fetch the book details from the server
  ///
  /// Parameters:
  ///
  /// - `bookUuid`: The unique identifier of the book
  Future<void> fetchBook({required String bookUuid}) async {
    BookItem book = await _jsonService.fetchBook(bookUuid: bookUuid);

    logger.i("Series: ${book.series} - ${book.seriesIndex} - ${book.uuid}");

    // Set current book and notify
    _currentBook = book;

    await checkIfBookIsRead(book.id);

    await checkIfBookIsBookArchived(book.id);

    // Notify listeners of the update
    notifyListeners();
  }

  /// Reload the book from the server and show loading indicator
  ///
  /// Parameters:
  ///
  /// - `bookUuid`: The unique identifier of the book
  Future<BookItem?> reloadBook({required String bookUuid}) async {
    try {
      logger.i('Reloading book: $bookUuid');
      _isReloading = true;
      notifyListeners();

      // Wait for a short delay to show loading indicator
      await Future.delayed(Duration(milliseconds: 300));

      // Fetch the book details
      await fetchBook(bookUuid: bookUuid);

      // Trigger a reload event
      _bookReloadController.add(bookUuid);

      return _currentBook;
    } catch (e) {
      logger.e('Error reloading book: $e');
      errorMessage = 'Error reloading: $e';
      return null;
    } finally {
      _isReloading = false;
      notifyListeners();
    }
  }

  /// Fetch the book details from the server
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  /// - `title`: The title of the book
  /// - `format`: The format of the book (e.g. epub, pdf)
  /// - `selectedDirectory`: The directory to save the book
  /// - `schema`: The download schema (flat or nested)
  /// - `book`: The book item object
  Future<String> downloadBook(
    BookItem book,
    String title,
    DownloadSchema schema,
    String selectedDirectory, {
    String format = 'epub',
  }) async {
    try {
      format = format.toLowerCase();
      logger.i('Downloading book - BookId: ${book.id}, Format: $format');
      isDownloading = true;
      downloaded = 0;
      notifyListeners();

      final apiService = ApiService();

      // Create the file path based on the selected schema
      String filePath = await _createPathBasedOnSchema(
        selectedDirectory,
        book,
        format,
        schema,
      );

      // Check if the file already exists
      final file = File(filePath);
      if (await file.exists()) {
        logger.i('File already exists: $filePath');
        return filePath;
      }

      try {
        // Create directory structure if needed
        await Directory(path.dirname(filePath)).create(recursive: true);

        // Get stream response using ApiService
        final response = await apiService.getStream(
          '/download/${book.id}/$format/${book.id}.$format',
          AuthMethod.cookie,
        );

        final contentLength = response.contentLength ?? -1;
        logger.i(
          'Download response status: ${response.statusCode}, Content length: $contentLength',
        );

        final sink = file.openWrite();
        int receivedBytes = 0;

        try {
          await for (final chunk in response.stream) {
            receivedBytes += chunk.length;
            sink.add(chunk);

            downloaded = receivedBytes;
            if (contentLength > 0) {
              _progress = (receivedBytes / contentLength * 100).round();
              logger.d(
                'Download progress: $_progress%, $receivedBytes/$contentLength bytes',
              );
            }
            notifyListeners();
          }
        } finally {
          await sink.flush();
          await sink.close();
        }

        logger.i('Download complete: $filePath with $receivedBytes bytes');
        return filePath;
      } catch (e) {
        logger.e('Error while downloading book: $e');
        errorMessage = 'Download error: $e';
        return "";
      }
    } catch (e) {
      logger.e('Exception while downloading book: $e');
      errorMessage = 'Error: $e';
      return "";
    } finally {
      isDownloading = false;
      _progress = 0;
      notifyListeners();
    }
  }

  /// Creates a file path based on the selected schema
  ///
  /// Parameters:
  ///
  /// - `baseDirectory`: The base directory selected by the user
  /// - `book`: The book item to download
  /// - `format`: The format of the book (e.g. epub, pdf)
  /// - `schema`: The organization schema to use
  Future<String> _createPathBasedOnSchema(
    String baseDirectory,
    BookItem book,
    String format,
    DownloadSchema schema,
  ) async {
    // Sanitize the file name to prevent invalid characters
    final safeTitle = book.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final safeAuthor = book.author.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = '$safeTitle.$format';
    String? safeSeries;

    if (book.series != null && book.series!.isNotEmpty) {
      safeSeries = book.series!.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    }

    String filePath;
    Directory directory;

    switch (schema) {
      case DownloadSchema.flat:
        // Just return the base directory with the file
        filePath = path.join(baseDirectory, fileName);

      case DownloadSchema.authorOnly:
        // Create author directory
        final authorDir = path.join(baseDirectory, safeAuthor);
        directory = Directory(authorDir);
        await directory.create(recursive: true);
        filePath = path.join(authorDir, fileName);

      case DownloadSchema.authorBook:
        // Create author/book directory
        final bookDir = path.join(baseDirectory, safeAuthor, safeTitle);
        directory = Directory(bookDir);
        await directory.create(recursive: true);
        filePath = path.join(bookDir, fileName);

      case DownloadSchema.authorSeriesBook:
        // Create author/series/book directory if series exists
        if (safeSeries != null) {
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
          // If no series, fall back to author/book
          final bookDir = path.join(baseDirectory, safeAuthor, safeTitle);
          directory = Directory(bookDir);
          await directory.create(recursive: true);
          filePath = path.join(bookDir, fileName);
        }
    }

    logger.d('Created path based on schema $schema: $filePath');
    return filePath;
  }

  /// Download book bytes from the server
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  /// - `format`: The format of the book (e.g. epub, pdf)
  Future<Uint8List?> downloadBookBytes(
    String bookId, {
    required String format,
  }) async {
    try {
      final apiService = ApiService();
      logger.i('Downloading book bytes - BookId: $bookId, Format: $format');

      final response = await apiService.getStream(
        '/download/$bookId/$format/$bookId.$format',
        AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        logger.i('Successfully downloaded book bytes');
        return await response.stream.toBytes();
      } else {
        logger.e('Error downloading book bytes: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('Exception downloading book bytes: $e');
      return null;
    }
  }

  /// Extracts CSRF token from HTML content
  ///
  /// Parameters:
  ///
  /// - `htmlBody`: The HTML content of the response
  /// - `logger`: The logger instance
  String? extractCsrfToken(String htmlBody, Logger logger) {
    // Try input field pattern first
    final csrfRegex = RegExp(
      r'<input[^>]*name="csrf_token"[^>]*value="([^"]+)"',
    );
    final csrfMatch = csrfRegex.firstMatch(htmlBody);

    if (csrfMatch != null && csrfMatch.groupCount >= 1) {
      final token = csrfMatch.group(1);
      logger.i('Extracted CSRF token from input field: $token');
      return token;
    }

    // Try meta tag pattern
    final metaRegex = RegExp(
      r'<meta[^>]*name="csrf-token"[^>]*content="([^"]+)"',
    );
    final metaMatch = metaRegex.firstMatch(htmlBody);

    if (metaMatch != null && metaMatch.groupCount >= 1) {
      final token = metaMatch.group(1);
      logger.i('Extracted CSRF token from meta tag: $token');
      return token;
    }

    logger.e('Failed to extract CSRF token from HTML');
    return null;
  }

  /// Extracts session cookie from response headers
  ///
  /// Parameters:
  ///
  /// - `response`: The HTTP response object
  /// - `initialCookie`: The initial session cookie
  /// - `logger`: The logger instance
  String extractSessionCookie(
    http.Response response,
    String initialCookie,
    Logger logger,
  ) {
    if (response.headers.containsKey('set-cookie')) {
      final setCookieHeader = response.headers['set-cookie']!;
      logger.d('Received Set-Cookie header: $setCookieHeader');

      final sessionMatch = RegExp(
        r'session=([^;]+)',
      ).firstMatch(setCookieHeader);
      if (sessionMatch != null && sessionMatch.groupCount >= 1) {
        final sessionCookie = 'session=${sessionMatch.group(1)}';
        logger.i('Extracted new session cookie: $sessionCookie');
        return sessionCookie;
      }
    }

    // Return original cookie if no new session cookie found
    return initialCookie;
  }

  /// Send book via email
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  /// - `format`: The format of the book (e.g. epub, pdf)
  /// - `conversion`: The conversion type (0 = original, 1 = MOBI, 2 = AZW3)
  Future<bool> sendViaEmail(
    String bookId,
    String format,
    int conversion,
  ) async {
    try {
      logger.i(
        'Starting email send process for bookId: $bookId, format: $format, conversion: $conversion',
      );

      final apiService = ApiService();
      final path = '/send/$bookId/$format/$conversion';

      // Use ApiService post with CSRF protection
      final response = await apiService.post(
        path,
        null, // No query parameters
        {}, // Empty body, CSRF token will be added automatically
        AuthMethod.cookie,
        useCsrf: true,
      );

      if (response.statusCode == 200) {
        logger.i('Successfully sent book via email');
        return true;
      } else {
        logger.e('Failed to send book via email: ${response.statusCode}');
        errorMessage = 'Failed to send email (${response.statusCode})';
        return false;
      }
    } catch (e) {
      logger.e('Error sending book via email: $e');
      errorMessage = 'Error: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Toggle the read status of a book
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  Future<bool> toggleReadStatus(String bookId) async {
    try {
      _isReadToggleLoading = true;
      notifyListeners();
      logger.i('Starting toggling read status for bookId: $bookId');

      final apiService = ApiService();
      final path = '/ajax/toggleread/$bookId';

      // Use ApiService post with CSRF protection
      final response = await apiService.post(
        path,
        null, // No query parameters
        {}, // Empty body, CSRF token will be added automatically
        AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode == 200) {
        logger.i('Successfully toggled read status');
        await checkIfBookIsRead(bookId);
        return true;
      } else {
        logger.e('Failed to toggle read status: ${response.statusCode}');
        errorMessage = 'Failed to toggle read status (${response.statusCode})';
        return false;
      }
    } catch (e) {
      logger.e('Error toggling read status: $e');
      errorMessage = 'Error: $e';
      return false;
    } finally {
      _isReadToggleLoading = false;
      notifyListeners();
    }
  }

  /// Check if the book is read
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  Future<void> checkIfBookIsRead(String bookId) async {
    try {
      BookListViewModel bookListViewModel = BookListViewModel();
      await bookListViewModel.loadBooks(BookListType.readbooks);

      _isBookRead = false;

      if (bookListViewModel.bookFeed != null &&
          bookListViewModel.bookFeed!.items.isNotEmpty) {
        _isBookRead = bookListViewModel.bookFeed!.items.any(
          (book) => book.id == bookId,
        );
        logger.i('Book read status: $_isBookRead (ID: $bookId)');
      } else {
        logger.i('No read books found or feed is empty');
      }
    } catch (e) {
      logger.e('Error checking if book is read: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Toggle the archived status of a book
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  Future<bool> toggleArchivedStatus(String bookId) async {
    try {
      _isArchivedLoading = true;
      notifyListeners();
      logger.i('Starting toggling archived status for bookId: $bookId');

      final apiService = ApiService();
      final path = '/ajax/togglearchived/$bookId';

      // Use ApiService post with CSRF protection
      final response = await apiService.post(
        path,
        null, // No query parameters
        {}, // Empty body, CSRF token will be added automatically
        AuthMethod.cookie,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode == 200) {
        logger.i('Successfully toggled archived status');
        _isArchived = !_isArchived;
        return true;
      } else {
        logger.e('Failed to toggle archived status: ${response.statusCode}');
        errorMessage =
            'Failed to toggle archived status (${response.statusCode})';
        return false;
      }
    } catch (e) {
      logger.e('Error toggling archived status: $e');
      errorMessage = 'Error: $e';
      return false;
    } finally {
      _isArchivedLoading = false;
      notifyListeners();
    }
  }

  /// Open the book in the browser
  ///
  /// Parameters:
  ///
  /// - `book`: The book item to open
  Future<void> openInBrowser(BookItem book) async {
    final apiService = ApiService();
    final baseUrl = apiService.getBaseUrl();

    if (baseUrl.isEmpty) {
      logger.w('No server URL found');
      errorMessage = 'Server URL missing';
      return;
    }

    final Uri url = Uri.parse('$baseUrl/book/${book.id}');

    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
      logger.i("Opened book in browser: $url");
    } catch (e) {
      logger.e('Error opening book in browser: $e');
      errorMessage = 'Error: $e';
    }
  }

  /// Check if the book is archived
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  /// Check if the book is archived
  ///
  /// Parameters:
  ///
  /// - `bookId`: The unique identifier of the book
  Future<bool> checkIfBookIsBookArchived(String bookId) async {
    try {
      final apiService = ApiService();
      logger.d("Checking if book $bookId is archived");

      final response = await apiService.get(
        '/archived/stored/',
        AuthMethod.cookie,
      );

      logger.d("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final pattern = 'href="/book/$bookId"';
        final isArchived = response.body.contains(pattern);

        _isArchived = isArchived;
        logger.i("Book $bookId archived status: $isArchived");
        return isArchived;
      } else {
        logger.w("Failed to check archived status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      logger.e('Error checking if book is archived: $e');
      errorMessage = 'Error checking archive status: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Open the book in the reader
  ///
  /// Parameters:
  ///
  /// - `book`: The book item to open
  /// - `selectedDirectory`: The directory to save the book
  /// - `schema`: The download schema (flat or nested)
  Future<bool> openInReader(
    BookItem book,
    String selectedDirectory,
    DownloadSchema schema,
  ) async {
    try {
      setOpeningInReader(true);

      String filePath = await downloadBook(
        book,
        book.title,
        schema,
        selectedDirectory,
      );

      if (filePath.isEmpty) {
        logger.e('Error downloading file for reader');
        errorMessage = 'Error downloading file';
        return false;
      }

      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        logger.e('Error while opening the file: ${result.message}');
        errorMessage = 'Error while opening: ${result.message}';
        return false;
      }

      logger.i('Opened book successfully');
      return true;
    } catch (e) {
      logger.e('Error while opening the book: $e');
      errorMessage = 'Error: $e';
      return false;
    } finally {
      setOpeningInReader(false);
    }
  }

  void setOpeningInReader(bool value) {
    _isOpeningInReader = value;
    notifyListeners();
  }
}
