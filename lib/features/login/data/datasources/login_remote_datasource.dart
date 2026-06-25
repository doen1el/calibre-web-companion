import 'dart:convert';
import 'dart:io';
// ignore: implementation_imports
import 'package:http/src/response.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/exceptions/redirect_exception.dart';
import 'package:calibre_web_companion/features/login/data/models/login_credentials.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';

class LoginRemoteDataSource {
  final ApiService apiService;
  final Logger logger;

  LoginRemoteDataSource({required this.apiService, required this.logger});

  Future<bool> login(
    LoginCredentials credentials,
    ServerType serverType,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedServerType =
          serverType == ServerType.booklore ? 'grimmory' : serverType.name;

      await prefs.setString('base_url', credentials.baseUrl);
      await prefs.setString('username', credentials.username);
      await prefs.setString('password', credentials.password);
      await prefs.setString('server_type', storedServerType);

      bool isLoggedIn = false;

      if (serverType == ServerType.calibre) {
        await apiService.initialize();
        isLoggedIn = await _loginCalibre(credentials);
      } else if (serverType == ServerType.opds ||
          serverType == ServerType.booklore) {
        try {
          final uri = Uri.parse(credentials.baseUrl);
          final origin = uri.origin;
          final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');

          await prefs.setString('base_url', origin);
          await apiService.initialize();

          await _loginOpds(credentials, path);

          await prefs.setString('base_url', credentials.baseUrl);
          await apiService.initialize();

          isLoggedIn = true;
        } catch (e) {
          logger.w('Error parsing OPDS URL, falling back: $e');
          await apiService.initialize();
          isLoggedIn = await _loginOpds(credentials, '');
        }
      } else {
        await apiService.initialize();
        isLoggedIn = await _loginCalibreWeb(credentials);
      }

      if (isLoggedIn) {
        await _saveAccountToHistory(credentials, serverType);
      }

      return isLoggedIn;
    } on RedirectException {
      rethrow;
    } catch (e) {
      logger.e("Error during login: $e");
      throw Exception('Connection error: ${e.toString().split(': ').last}');
    }
  }

  Future<bool> _loginOpds(LoginCredentials credentials, String endpoint) async {
    logger.i('Attempting OPDS login to endpoint: "$endpoint"...');

    final hasCredentials =
        credentials.username.isNotEmpty || credentials.password.isNotEmpty;

    final response = await apiService.get(
      endpoint: endpoint,
      authMethod: hasCredentials ? AuthMethod.basic : AuthMethod.none,
      followRedirects: true,
    );

    if (response.statusCode == 200) {
      logger.i('OPDS Login successful');
      return true;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      logger.w('OPDS Login failed - invalid credentials or auth required');
      throw Exception('Invalid username or password');
    } else {
      throw Exception('Server returned ${response.statusCode}');
    }
  }

  Future<bool> _loginCalibre(LoginCredentials credentials) async {
    logger.i('Attempting Calibre content server login...');

    final response = await apiService.get(
      endpoint: '/ajax/library-info',
      authMethod: AuthMethod.auto,
      followRedirects: true,
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      logger.w('Calibre login failed - invalid credentials or auth required');
      throw Exception('Invalid username or password');
    }

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final libraryMap =
          (decoded['library_map'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          <String, String>{};
      final defaultLibrary = decoded['default_library']?.toString();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('calibre_library_map', jsonEncode(libraryMap));

      final selectedLibrary =
          (defaultLibrary != null && libraryMap.containsKey(defaultLibrary))
              ? defaultLibrary
              : (libraryMap.keys.isNotEmpty ? libraryMap.keys.first : null);

      if (selectedLibrary != null) {
        await prefs.setString('calibre_library_id', selectedLibrary);
      } else {
        await prefs.remove('calibre_library_id');
      }

      logger.i(
        'Calibre login successful. Libraries: ${libraryMap.length}, '
        'selected: $selectedLibrary',
      );
      return true;
    } catch (e) {
      logger.e('Failed to parse Calibre library-info: $e');
      throw Exception('Unexpected response from Calibre server');
    }
  }

  Future<bool> _loginCalibreWeb(LoginCredentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    if (credentials.username.isEmpty && credentials.password.isEmpty) {
      logger.i('Attempting SSO login by triggering a redirect...');
      await apiService.get(endpoint: '/', followRedirects: false);
      logger.i('User is already logged in.');
      return true;
    }

    Response response;

    if (credentials.username.isEmpty && credentials.password.isEmpty) {
      response = await apiService.post(
        endpoint: '/login',
        body: credentials.toFormData(),
        followRedirects: false,
      );
    } else {
      response = await apiService.post(
        endpoint: '/login',
        body: credentials.toFormData(),
        authMethod: AuthMethod.none,
        contentType: 'application/x-www-form-urlencoded',
        useCsrf: true,
      );
    }

    if (response.statusCode == 200 || response.statusCode == 302) {
      final isSuccess = !response.body.contains('flash_danger');

      if (isSuccess) {
        if (response.headers.containsKey('set-cookie')) {
          final cookie = response.headers['set-cookie']!;
          await prefs.setString('calibre_web_session', cookie);
          await apiService.initialize();
          logger.i('Session cookie saved');
        } else {
          logger.w('No cookie received in login response');
        }
        logger.i('Login successful');
        return true;
      } else {
        logger.w('Login failed - invalid credentials');
        throw Exception('Invalid username or password');
      }
    }

    logger.e(
      'Login failed: ${response.reasonPhrase ?? response.body} ${response.statusCode}',
    );
    throw Exception(response.reasonPhrase ?? response.body);
  }

  Future<bool> canAccessWebsite() async {
    logger.i('Checking if user can access website...');
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('base_url');
    final serverType = await getStoredServerType();

    if (serverType == ServerType.booklore) {
      final response = await apiService.get(
        endpoint: '/catalog',
        authMethod: AuthMethod.basic,
      );

      if (response.statusCode == 200) {
        logger.i('Grimmory access check successful.');
        return true;
      } else {
        logger.w(
          'Grimmory access check failed with status: ${response.statusCode}',
        );
        return false;
      }
    }

    if (serverType == ServerType.calibre) {
      await apiService.initialize();
      final response = await apiService.get(
        endpoint: '/ajax/library-info',
        authMethod: AuthMethod.auto,
      );

      if (response.statusCode == 200) {
        logger.i('Calibre access check successful.');
        return true;
      } else {
        logger.w(
          'Calibre access check failed with status: ${response.statusCode}',
        );
        return false;
      }
    }

    final cookie =
        prefs.getString('calibre_web_cookie') ??
        prefs.getString('calibre_web_session');

    if (baseUrl == null || cookie == null || cookie.isEmpty) {
      return false;
    }

    await apiService.initialize();

    await Future.delayed(const Duration(milliseconds: 100));

    int attempts = 0;
    while (attempts < 2) {
      try {
        final response = await apiService.get(
          endpoint: '/ajax/listbooks',
          authMethod: AuthMethod.cookie,
          queryParams: const {'limit': '1'},
          followRedirects: false,
        );

        if (response.statusCode == 200) {
          if (response.body.trim().startsWith('<!DOCTYPE') ||
              response.body.contains('<html')) {
            logger.w(
              'Session check failed: Received HTML (Login Page) instead of JSON.',
            );
            return false;
          }

          logger.i('Session is valid.');
          return true;
        } else if (response.statusCode == 302 || response.statusCode == 301) {
          logger.w(
            'Session check failed: Redirect detected (Status ${response.statusCode}).',
          );
          return false;
        }

        logger.w('Session check failed with status: ${response.statusCode}');

        if (response.statusCode == 401 || response.statusCode == 403) {
          return false;
        }

        attempts++;
        if (attempts < 2) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        attempts++;
        logger.w('Session validation attempt $attempts failed: $e');

        if (attempts >= 2) rethrow;
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
    return false;
  }

  Future<bool> hasStoredAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('base_url');
    return baseUrl != null && baseUrl.isNotEmpty;
  }

  Future<void> clearSessionForAccountSwitch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('calibre_web_session');
    await prefs.remove('calibre_web_cookie');
    await prefs.remove('user_agent');
    await prefs.remove('calibre_library_id');
    await prefs.remove('calibre_library_map');
    await apiService.reset();
  }

  Future<void> _saveAccountToHistory(
    LoginCredentials credentials,
    ServerType type,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('saved_accounts') ?? [];

    history.removeWhere((item) {
      try {
        final Map<String, dynamic> json = jsonDecode(item);
        return json['baseUrl'] == credentials.baseUrl &&
            json['username'] == credentials.username;
      } catch (_) {
        return false;
      }
    });

    final entry = credentials.toJson();
    entry['serverType'] = type == ServerType.booklore ? 'grimmory' : type.name;

    history.insert(0, jsonEncode(entry));

    await prefs.setStringList('saved_accounts', history);
  }

  Future<List<LoginCredentials>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('saved_accounts') ?? [];

    final currentBaseUrl = prefs.getString('base_url');
    final currentUsername = prefs.getString('username');
    final currentPassword = prefs.getString('password');
    final currentServerTypeStr = prefs.getString('server_type');

    if (currentBaseUrl != null && currentBaseUrl.isNotEmpty) {
      bool isAlreadySaved = false;

      for (String item in history) {
        try {
          final Map<String, dynamic> json = jsonDecode(item);
          if (json['baseUrl'] == currentBaseUrl &&
              json['username'] == (currentUsername ?? '')) {
            isAlreadySaved = true;
            break;
          }
        } catch (_) {}
      }

      if (!isAlreadySaved) {
        final newEntry = {
          'baseUrl': currentBaseUrl,
          'username': currentUsername ?? '',
          'password': currentPassword ?? '',
          'serverType': currentServerTypeStr ?? ServerType.calibreWeb.name,
        };

        history.insert(0, jsonEncode(newEntry));

        await prefs.setStringList('saved_accounts', history);
        logger.i('Automatically migrated current account to saved history.');
      }
    }

    return history
        .map((item) {
          try {
            return LoginCredentials.fromJson(jsonDecode(item));
          } catch (e) {
            return null;
          }
        })
        .whereType<LoginCredentials>()
        .toList();
  }

  Future<void> removeAccount(LoginCredentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('saved_accounts') ?? [];

    history.removeWhere((item) {
      try {
        final Map<String, dynamic> json = jsonDecode(item);
        return json['baseUrl'] == credentials.baseUrl &&
            json['username'] == credentials.username;
      } catch (_) {
        return false;
      }
    });

    await prefs.setStringList('saved_accounts', history);
  }

  Future<LoginCredentials?> getStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('base_url');
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    if (baseUrl != null && username != null && password != null) {
      return LoginCredentials(
        baseUrl: baseUrl,
        username: username,
        password: password,
      );
    }

    return null;
  }

  Future<EndpointStatus> probeEndpoint(
    String url,
    ServerType serverType,
  ) async {
    final trimmed = url.trim();
    final afterScheme = trimmed.replaceFirst(RegExp(r'^https?://'), '');

    if (!afterScheme.contains(RegExp(r'[a-zA-Z0-9]')) ||
        !afterScheme.contains('.')) {
      return EndpointStatus.idle;
    }

    var base = trimmed;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);

    final String probeUrl;
    switch (serverType) {
      case ServerType.calibre:
        probeUrl = '$base/ajax/library-info';
        break;
      case ServerType.calibreWeb:
        probeUrl = '$base/';
        break;
      case ServerType.booklore:
        probeUrl = base.endsWith('/api/v1/opds') ? base : '$base/api/v1/opds';
        break;
      case ServerType.opds:
        probeUrl = base;
        break;
    }

    final uri = Uri.tryParse(probeUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return EndpointStatus.idle;
    }

    HttpClient? client;
    try {
      final prefs = await SharedPreferences.getInstance();
      final allowSelfSigned = prefs.getBool('allow_self_signed') ?? false;

      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      if (allowSelfSigned) {
        client.badCertificateCallback = (cert, host, port) => true;
      }

      final request = await client.getUrl(uri);
      request.followRedirects = true;
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final code = response.statusCode;
      await response.drain<void>();

      if (code == 401 || code == 403) return EndpointStatus.authRequired;
      if (code >= 200 && code < 400) return EndpointStatus.reachable;
      return EndpointStatus.unreachable;
    } catch (e) {
      logger.w('Endpoint probe failed for $probeUrl: $e');
      return EndpointStatus.unreachable;
    } finally {
      client?.close();
    }
  }

  Future<ServerType> getStoredServerType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString('server_type');
    if (typeStr == ServerType.opds.name) {
      return ServerType.opds;
    } else if (typeStr == ServerType.booklore.name || typeStr == 'grimmory') {
      return ServerType.booklore;
    } else if (typeStr == ServerType.calibre.name) {
      return ServerType.calibre;
    }
    return ServerType.calibreWeb;
  }

  Future<void> finalizeSsoSession({
    required String cookieHeader,
    required String userAgent,
    required String baseUrl,
    String? username,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('base_url', baseUrl);
    await prefs.setString('user_agent', userAgent);
    await prefs.setString('calibre_web_cookie', cookieHeader);
    await prefs.remove('calibre_web_session');

    if (username != null && username.isNotEmpty) {
      await prefs.setString('username', username);
    }
    if (password != null && password.isNotEmpty) {
      await prefs.setString('password', password);
    }

    await apiService.initialize();

    try {
      final response = await apiService.get(
        endpoint: '/ajax/listbooks',
        authMethod: AuthMethod.cookie,
        queryParams: const {'limit': '1'},
      );

      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.contains('<html')) {
        throw Exception('Session probe failed');
      }

      logger.i('SSO Session successfully validated.');
    } catch (e) {
      await prefs.remove('calibre_web_cookie');
      logger.e('SSO Validation failed: $e');
      throw Exception('SSO Validation failed: $e');
    }
  }
}
