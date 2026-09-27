import 'dart:convert';

import 'package:calibre_web_companion/core/services/session_reauth_service.dart';
import 'package:calibre_web_companion/features/download_service/data/downloader_request_headers.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_config_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_filter_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_status.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_status_response.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, String> _getHeaders({bool includeCookie = true}) => {
    'Content-Type': 'application/json',
    ...buildDownloaderHeaders(
      sharedPreferences,
      includeDownloaderCookie: includeCookie,
    ),
  };

  bool get _hasCredentials =>
      (sharedPreferences.getString('downloader_username') ?? '').isNotEmpty &&
      (sharedPreferences.getString('downloader_password') ?? '').isNotEmpty;

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

    final headers = _getHeaders(includeCookie: false);

    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: headers,
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
    var response = await requestFn(_getHeaders());
    final useSso = downloaderUsesSsoSession(sharedPreferences);

    if (response.statusCode == 401 && (!useSso || _hasCredentials)) {
      logger.w('Received 401, attempting re-login...');
      try {
        await _login();
        response = await requestFn(_getHeaders());
      } catch (e) {
        // Behind a forward-auth proxy the 401 may come from the proxy, which
        // only the SSO web view below can satisfy.
        if (!useSso) rethrow;
        logger.w('Downloader re-login failed: $e');
      }
    }

    if (useSso && isInterceptedByAuthProxy(response)) {
      logger.w(
        'Downloader request intercepted by auth proxy; requesting SSO re-auth.',
      );
      if (await SessionReauthService().requestReauth()) {
        response = await requestFn(_getHeaders());
      }
    }

    return response;
  }

  dynamic _decodeJson(http.Response response) {
    if (looksLikeHtmlResponse(response)) {
      throw const DownloaderLoginPageException();
    }
    return json.decode(response.body);
  }

  Future<List<DownloadServiceBookModel>> searchBooks(
    String query, {
    DownloadFilterModel? filter,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();

      final queryParameters = <String, List<String>>{
        'source': ['direct_download'],
        'query': [query],
        'sort': ['relevance'],
        if (filter != null) ..._buildFilterParams(filter),
      };

      final queryString = queryParameters.entries
          .expand(
            (entry) => entry.value.map(
              (value) =>
                  '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value)}',
            ),
          )
          .join('&');

      final uri = Uri.parse('$baseUrl/api/releases?$queryString');

      logger.i('Searching with URI: $uri');

      final response = await _executeWithRetry(
        (headers) => client.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        final decoded = _decodeJson(response);
        final results = _extractSearchResults(decoded);
        logger.d(response.body);
        final books =
            results.map(DownloadServiceBookModel.fromSearchResponse).toList();
        logger.i('Found ${books.length} books matching "$query"');
        return books;
      } else {
        final errorMessage =
            'Failed to search books: ${response.statusCode} ${response.body}';
        logger.e(errorMessage);
        throw Exception(errorMessage);
      }
    } on DownloaderLoginPageException {
      logger.e('Downloader returned a login page (auth proxy?)');
      rethrow;
    } catch (e) {
      final errorMessage = 'Error searching books: $e';
      logger.e(errorMessage);
      throw Exception(errorMessage);
    }
  }

  List<Map<String, dynamic>> _extractSearchResults(dynamic decoded) {
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }

    if (decoded is Map<String, dynamic>) {
      final listCandidates = [
        decoded['results'],
        decoded['releases'],
        decoded['items'],
        decoded['data'],
      ];

      for (final candidate in listCandidates) {
        if (candidate is List) {
          return candidate.whereType<Map<String, dynamic>>().toList();
        }
      }
    }

    throw const FormatException('Unexpected search response format');
  }

  Map<String, List<String>> _buildFilterParams(DownloadFilterModel filter) {
    final params = <String, List<String>>{};

    if (filter.isbn != null && filter.isbn!.isNotEmpty) {
      params['isbn'] = [filter.isbn!];
    }
    if (filter.author != null && filter.author!.isNotEmpty) {
      params['author'] = [filter.author!];
    }
    if (filter.title != null && filter.title!.isNotEmpty) {
      params['title'] = [filter.title!];
    }
    if (filter.content != null && filter.content!.isNotEmpty) {
      params['content'] = [filter.content!];
    }

    if (filter.languages.isNotEmpty) {
      params['lang'] = filter.languages;
    }
    if (filter.formats.isNotEmpty) {
      params['format'] = filter.formats;
    }

    return params;
  }

  Future<bool> downloadBook(DownloadServiceBookModel book) async {
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/releases/download');

      final payload = {
        'source': 'direct_download',
        'source_id': book.id,
        'title': book.title,
        'author': book.author,
        'year': book.year,
        'format': book.format,
        'size': book.size,
        'preview': book.preview,
        'content_type': 'ebook',
        'search_mode': 'direct',
      };

      logger.i('Making download request for ${book.id}');

      final response = await _executeWithRetry(
        (headers) =>
            client.post(uri, headers: headers, body: jsonEncode(payload)),
      );

      if (response.statusCode == 200) {
        final status = _decodeJson(response);
        logger.i('Download status: $status');
        return true;
      } else {
        final errorMessage = 'Failed to download book: ${response.body}';
        logger.e(errorMessage);
        throw Exception(errorMessage);
      }
    } on DownloaderLoginPageException {
      logger.e('Downloader returned a login page (auth proxy?)');
      rethrow;
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
        final status = _decodeJson(response);
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
    } on DownloaderLoginPageException {
      logger.e('Downloader returned a login page (auth proxy?)');
      rethrow;
    } catch (e) {
      final errorMessage = 'Error fetching download status: $e';
      logger.e(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<DownloadConfigModel> getConfig() async {
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/config');

      final response = await _executeWithRetry(
        (headers) => client.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        final jsonMap = _decodeJson(response);
        return DownloadConfigModel.fromJson(jsonMap);
      } else {
        logger.w('Failed to load config: ${response.statusCode}');
        return const DownloadConfigModel();
      }
    } catch (e) {
      logger.e('Error fetching config: $e');
      return const DownloadConfigModel();
    }
  }

  Future<void> saveFilterSettings(
    List<String> languages,
    List<String> formats,
  ) async {
    try {
      final jsonString = jsonEncode({
        'languages': languages,
        'formats': formats,
      });
      await sharedPreferences.setString('dl_filter_settings', jsonString);
      logger.i('Saved filter settings: $jsonString');
    } catch (e) {
      logger.e('Error saving filter settings: $e');
    }
  }

  Future<DownloadFilterModel> getSavedFilterSettings() async {
    final appLanguage = sharedPreferences.getString('language_code') ?? 'en';

    try {
      final jsonString = sharedPreferences.getString('dl_filter_settings');

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(jsonString);

        final languages =
            map['languages'] != null
                ? List<String>.from(map['languages'])
                : <String>[appLanguage];

        final formats =
            map['formats'] != null
                ? List<String>.from(map['formats'])
                : DownloadFilterModel.allFormats;

        logger.i('Loaded saved filter: languages=$languages, formats=$formats');

        return DownloadFilterModel(languages: languages, formats: formats);
      }
    } catch (e) {
      logger.e('Error loading saved filter settings: $e');
    }

    return DownloadFilterModel(languages: [appLanguage]);
  }
}
