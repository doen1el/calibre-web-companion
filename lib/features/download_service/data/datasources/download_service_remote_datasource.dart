import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_status.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_status_response.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_filter_model.dart';

class DownloadServiceRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;
  final Logger logger;

  DownloadServiceRemoteDataSource({
    required this.client,
    required this.sharedPreferences,
    required this.logger,
  });

  Future<String> _getBaseUrl() async {
    return sharedPreferences.getString('downloader_url') ?? '';
  }

  Map<String, String> _getHeaders() {
    final cookie = sharedPreferences.getString('downloader_cookie');
    final headers = {'Content-Type': 'application/json'};
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }

  Future<void> _login() async {
    final baseUrl = await _getBaseUrl();
    final username = sharedPreferences.getString('downloader_username');
    final password = sharedPreferences.getString('downloader_password');

    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      throw Exception('No credentials provided for downloader service');
    }

    logger.i('Attempting to login to downloader service...');

    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'remember_me': true,
      }),
    );

    if (response.statusCode == 200) {
      final rawCookie = response.headers['set-cookie'];
      if (rawCookie != null) {
        final cookieValue = rawCookie.split(';').first;
        await sharedPreferences.setString('downloader_cookie', cookieValue);
        logger.i('Login successful, cookie stored: $cookieValue');
      } else {
        logger.w('Login successful but no Set-Cookie header found');
      }
    } else {
      logger.e('Login failed: ${response.statusCode} ${response.body}');
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function(Map<String, String> headers) requestFn,
  ) async {
    try {
      final response = await requestFn(_getHeaders());

      if (response.statusCode == 401) {
        logger.w('Received 401, attempting re-login...');
        await _login();
        return await requestFn(_getHeaders());
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DownloadServiceBookModel>> searchBooks(
    String query, {
    DownloadFilterModel? filter,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();

      final uri = Uri.parse('$baseUrl/api/search').replace(
        queryParameters: {
          'query': query,
          if (filter != null) ..._buildFilterParams(filter),
        },
      );

      logger.i('Searching with URI: $uri');

      final response = await _executeWithRetry(
        (headers) => client.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        logger.d(response.body);
        final books =
            results
                .map(
                  (json) => DownloadServiceBookModel.fromSearchResponse(json),
                )
                .toList();
        logger.i('Found ${books.length} books matching "$query"');
        return books;
      } else {
        final errorMessage =
            'Failed to search books: ${response.statusCode} ${response.body}';
        logger.e(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Error searching books: $e';
      logger.e(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Map<String, dynamic> _buildFilterParams(DownloadFilterModel filter) {
    final params = <String, dynamic>{};

    if (filter.isbn != null && filter.isbn!.isNotEmpty) {
      params['isbn'] = filter.isbn;
    }
    if (filter.author != null && filter.author!.isNotEmpty) {
      params['author'] = filter.author;
    }
    if (filter.title != null && filter.title!.isNotEmpty) {
      params['title'] = filter.title;
    }
    if (filter.content != null && filter.content!.isNotEmpty) {
      params['content'] = filter.content;
    }

    if (filter.languages.isNotEmpty) {
      params['lang'] = filter.languages;
    }
    if (filter.formats.isNotEmpty) {
      params['format'] = filter.formats;
    }

    return params;
  }

  Future<bool> downloadBook(String bookId) async {
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/download?id=$bookId');

      logger.i('Making download request for $bookId');

      final response = await _executeWithRetry(
        (headers) => client.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        final status = json.decode(response.body);
        logger.i('Download status: $status');
        return true;
      } else {
        final errorMessage = 'Failed to download book: ${response.body}';
        logger.e(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Error downloading book: $e';
      logger.e(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<List<DownloadServiceBookModel>> getDownloadStatus() async {
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/status');

      final response = await _executeWithRetry(
        (headers) => client.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        final status = json.decode(response.body);
        logger.d(response.body);
        final downloadStatus = DownloadStatusResponse.fromJson(status);
        final books = downloadStatus.getAllBooks();

        logger.i('Found ${books.length} books with download status');

        final availableCount =
            books.where((b) => b.status == DownloaderStatus.available).length;
        final downloadingCount =
            books.where((b) => b.status == DownloaderStatus.downloading).length;
        final doneCount =
            books.where((b) => b.status == DownloaderStatus.done).length;
        final errorCount =
            books.where((b) => b.status == DownloaderStatus.error).length;
        final queuedCount =
            books.where((b) => b.status == DownloaderStatus.queued).length;

        logger.d(
          'Books by status: Available: $availableCount, Downloading: $downloadingCount, '
          'Done: $doneCount, Error: $errorCount, Queued: $queuedCount',
        );

        return books;
      } else {
        final errorMessage = 'Failed to get status: ${response.statusCode}';
        logger.e(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Error fetching download status: $e';
      logger.e(errorMessage);
      throw Exception(errorMessage);
    }
  }
}
