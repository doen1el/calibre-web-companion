import 'dart:async';
import 'dart:typed_data';
import 'package:docman/docman.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:logger/logger.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/core/services/tag_service.dart';

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
        authMethod: AuthMethod.auto,
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
    DocumentFile selectedDirectory,
    DownloadSchema schema, {
    String format = 'epub',
    Function(int)? progressCallback,
  }) async {
    return downloadBookToPath(
      book: book,
      selectedDirectory: selectedDirectory,
      schema: schema,
      format: format,
      progressCallback: progressCallback,
    );
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
    Uint8List? coverImageBytes,
    String? coverFileName,
  }) async {
    try {
      final body = {
        'title': title,
        'authors': authors,
        'comments': comments,
        'tags': tags,
        'detail_view': 'on',
      };

      if (coverImageBytes != null && coverFileName != null) {
        logger.i('Updating book metadata with cover for book: $bookId');

        final multipartFile = http.MultipartFile.fromBytes(
          'btn-upload-cover',
          coverImageBytes,
          filename: coverFileName,
          contentType: MediaType('image', 'jpeg'),
        );

        final response = await apiService.post(
          endpoint: '/admin/book/$bookId',
          body: body,
          files: [multipartFile],
          authMethod: AuthMethod.cookie,
          useCsrf: true,
          contentType: 'multipart/form-data',
        );

        if (response.statusCode == 302) {
          logger.i('Successfully updated book metadata with cover');
          return true;
        } else {
          logger.e(
            'Failed to update book metadata with cover: ${response.statusCode}, ${response.body}',
          );
          return false;
        }
      } else {
        final response = await apiService.post(
          endpoint: '/admin/book/$bookId',
          body: body,
          authMethod: AuthMethod.cookie,
          useCsrf: true,
          contentType: 'application/x-www-form-urlencoded',
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
      }
    } catch (e) {
      logger.e('Error updating book metadata: $e');
      throw Exception('Failed to update book metadata: $e');
    }
  }

  Future<DocumentFile> _getOrCreateDirectory(
    DocumentFile parent,
    String name,
  ) async {
    final existing = await parent.find(name);
    if (existing != null && existing.isDirectory) {
      return existing;
    }
    return await parent.createDirectory(name) ?? parent;
  }

  Future<String> downloadBookToPath({
    required BookDetailsModel book,
    required DocumentFile selectedDirectory,
    required DownloadSchema schema,
    String format = 'epub',
    Function(int)? progressCallback,
    bool deleteOnError = true,
  }) async {
    try {
      logger.i(
        'Downloading book: ${book.title}, Format: $format, Schema: $schema, Directory: $selectedDirectory',
      );
      final safeTitle = book.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final safeAuthor = book.authors.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = '$safeTitle.$format';

      DocumentFile targetDir = selectedDirectory;
      String? safeSeries;

      if (book.series.isNotEmpty) {
        safeSeries = book.series.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      }

      switch (schema) {
        case DownloadSchema.flat:
          break;
        case DownloadSchema.authorOnly:
          targetDir = await _getOrCreateDirectory(
            selectedDirectory,
            safeAuthor,
          );
          break;
        case DownloadSchema.authorBook:
          final authorDir = await _getOrCreateDirectory(
            selectedDirectory,
            safeAuthor,
          );
          targetDir = await _getOrCreateDirectory(authorDir, safeTitle);
          break;
        case DownloadSchema.authorSeriesBook:
          final authorDir = await _getOrCreateDirectory(
            selectedDirectory,
            safeAuthor,
          );
          if (safeSeries != null && safeSeries.isNotEmpty) {
            final seriesDir = await _getOrCreateDirectory(
              authorDir,
              safeSeries,
            );
            targetDir = await _getOrCreateDirectory(seriesDir, safeTitle);
          } else {
            targetDir = await _getOrCreateDirectory(authorDir, safeTitle);
          }
          break;
      }

      final existingFile = await targetDir.find(fileName.replaceAll(' ', '_'));

      if (existingFile != null && existingFile.isFile) {
        logger.w('File already exists: $fileName');
        return existingFile.uri.toString();
      }

      final response = await getDownloadStream(book.id.toString(), format);
      final contentLength = response.contentLength ?? -1;

      logger.i(
        'Download response status: ${response.statusCode}, Content length: $contentLength',
      );

      final List<int> bytes = [];
      int receivedBytes = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;

        if (contentLength > 0 && progressCallback != null) {
          final progress = (receivedBytes / contentLength * 100).round();
          progressCallback(progress);
        }
      }

      final Uint8List fileData = Uint8List.fromList(bytes);

      final createdFile = await targetDir.createFile(
        name: fileName,
        bytes: fileData,
      );

      if (createdFile == null) {
        logger.e('Failed to create file in SAF directory');
        throw Exception('Failed to create file in SAF directory');
      }

      logger.i(
        'Download complete: ${createdFile.uri} with $receivedBytes bytes',
      );
      return createdFile.uri;
    } catch (e) {
      logger.e('Exception while downloading book: $e');
      throw Exception('Error downloading book: $e');
    }
  }

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

  Future<bool> openInReader(
    BookDetailsModel book,
    DocumentFile selectedDirectory,
    DownloadSchema schema, {
    Function(int)? progressCallback,
  }) async {
    try {
      logger.i('Opening book in reader: ${book.title}');

      String format = 'epub';
      if (book.formats.isNotEmpty) {
        format = book.formats.first.toLowerCase();
      }

      final filePath = await downloadBookToPath(
        book: book,
        selectedDirectory: selectedDirectory,
        schema: schema,
        format: format,
        progressCallback: progressCallback,
      );

      DocumentFile? file =
          filePath.isNotEmpty ? await DocumentFile.fromUri(filePath) : null;

      if (file == null || !file.isFile) {
        logger.e('Downloaded file is not a valid file: $filePath');
        return false;
      }

      final cachedFile = await file.cache();
      if (cachedFile == null) {
        logger.e('Could not cache file for opening');
        return false;
      }

      final result = await OpenFile.open(cachedFile.path);

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

  Future<String> downloadBookForReader(
    BookDetailsModel book,
    DocumentFile selectedDirectory,
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

      url = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

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

      _updateProgressWithDelay(onProgressUpdate, [20, 40, 70, 90, 100]);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final success = response.statusCode == 200;

      if (success) {
        logger.i('Successfully uploaded to send2ereader');
      } else {
        logger.e(
          'Failed to upload: ${response.statusCode}, Body: $responseBody',
        );
      }

      return success;
    } catch (e) {
      logger.e('Error uploading to send2ereader: $e');
      return false;
    }
  }

  Future<void> _updateProgressWithDelay(
    Function(int)? progressCallback,
    List<int> progressSteps,
  ) async {
    if (progressCallback == null) return;

    for (final progress in progressSteps) {
      progressCallback(progress);
      if (progress < progressSteps.last) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }
}
