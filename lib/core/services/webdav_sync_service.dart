import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

class WebDavSyncService {
  final Logger logger;
  webdav.Client? _client;

  Future<void> _queue = Future.value();

  static const String _syncFileName =
      'calibre_web_companion_reading_progress.json';

  WebDavSyncService({required this.logger});

  // A ready client from the saved settings, or null when sync is off.
  static WebDavSyncService? fromPrefs(SharedPreferences prefs, Logger logger) {
    if (!(prefs.getBool('webdav_enabled') ?? false)) return null;
    final url = prefs.getString('webdav_url') ?? '';
    if (url.isEmpty) return null;
    return WebDavSyncService(logger: logger)..init(
      url,
      prefs.getString('webdav_username') ?? '',
      prefs.getString('webdav_password') ?? '',
      allowSelfSigned: prefs.getBool('allow_self_signed') ?? false,
    );
  }

  void init(
    String url,
    String user,
    String password, {
    bool allowSelfSigned = false,
  }) {
    if (url.isEmpty) return;

    final client = webdav.newClient(
      url,
      user: user,
      password: password,
      debug: false,
    );

    if (allowSelfSigned) {
      client.c.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final httpClient = HttpClient();
          httpClient.badCertificateCallback = (cert, host, port) => true;
          return httpClient;
        },
      );
    }

    client.c.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (response.requestOptions.method == 'OPTIONS' &&
              response.statusCode == 204) {
            response.statusCode = 200;
          }
          // webdav_client reads the challenge with headers.value(), which
          // throws when a server (e.g. OpenCloud) sends several of them.
          final challenges = response.headers.map['www-authenticate'];
          if (challenges != null && challenges.length > 1) {
            response.headers.set(
              'www-authenticate',
              _pickChallenge(challenges),
            );
          }
          handler.next(response);
        },
      ),
    );

    client.setConnectTimeout(15000);
    client.setSendTimeout(30000);
    client.setReceiveTimeout(30000);

    _client = client;
  }

  static String _pickChallenge(List<String> challenges) {
    for (final scheme in ['digest', 'basic']) {
      for (final c in challenges) {
        if (c.trimLeft().toLowerCase().startsWith(scheme)) return c;
      }
    }
    return challenges.first;
  }

  Future<T> _locked<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  Future<void> testConnection() {
    final client = _client;
    if (client == null) {
      throw Exception('WebDAV client not initialized');
    }
    return _locked(() async {
      try {
        await client.readDir('/');
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) rethrow;
        await client.ping();
      }
    });
  }

  Future<Map<String, dynamic>?> _read(
    webdav.Client client, [
    String fileName = _syncFileName,
  ]) async {
    try {
      final List<int> data = await client.read(fileName);
      if (data.isEmpty) return {};
      return jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        logger.i('WebDAV sync file $fileName does not exist yet');
        return {};
      }
      logger.w('Could not read WebDAV sync file: $e');
      return null;
    } catch (e) {
      logger.w('Could not parse WebDAV sync file: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchProgress() async {
    final client = _client;
    if (client == null) return {};
    return await _locked<Map<String, dynamic>?>(() => _read(client)) ?? {};
  }

  Future<void> saveProgress(
    String bookUuid,
    String locatorJson,
    int timestamp,
  ) async {
    final client = _client;
    if (client == null) return;

    return _locked(() async {
      final currentData = await _read(client);
      if (currentData == null) {
        logger.w('Skipping WebDAV write: remote state unreadable');
        return;
      }

      currentData[bookUuid] = {'locator': locatorJson, 'timestamp': timestamp};

      try {
        await client.write(_syncFileName, utf8.encode(jsonEncode(currentData)));
        logger.i('Progress synced to WebDAV for $bookUuid');
      } catch (e) {
        logger.e('Error saving WebDAV progress: $e');
      }
    });
  }

  Future<Map<String, dynamic>?> readJsonFile(String fileName) async {
    final client = _client;
    if (client == null) return null;
    return _locked(() => _read(client, fileName));
  }

  // Read-modify-write under the lock, so two updates from this app cannot
  // overwrite each other. [update] returns null to leave the file untouched.
  // Returns false when the remote file could not be read or written.
  Future<bool> updateJsonFile(
    String fileName,
    Map<String, dynamic>? Function(Map<String, dynamic> current) update,
  ) async {
    final client = _client;
    if (client == null) return false;
    return _locked(() async {
      final current = await _read(client, fileName);
      if (current == null) return false;
      final next = update(current);
      if (next == null) return true;
      try {
        await client.write(fileName, utf8.encode(jsonEncode(next)));
        return true;
      } catch (e) {
        logger.e('Error writing WebDAV file $fileName: $e');
        return false;
      }
    });
  }
}
