import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/shelf_view.dart/data/models/magic_rule_models.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_list_view_model.dart';
import 'package:calibre_web_companion/features/shelf_details/data/datasources/shelf_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/magic_shelf_model.dart';

class ShelfViewRemoteDataSource {
  final ApiService apiService;
  final Logger logger;
  final ShelfDetailsRemoteDataSource shelfDetailsRemoteDataSource;
  final SharedPreferences preferences;

  ShelfViewRemoteDataSource({
    required this.apiService,
    required this.logger,
    required this.shelfDetailsRemoteDataSource,
    required this.preferences,
  });

  Future<ShelfListViewModel> loadShelves() async {
    try {
      final serverType = preferences.getString('server_type');

      if (serverType == 'opds' ||
          serverType == 'grimmory' ||
          serverType == 'booklore') {
        return _loadOpdsShelves();
      }

      final res = await apiService.getXmlAsJson(
        endpoint: '/opds/shelfindex',
        authMethod: AuthMethod.auto,
      );
      return ShelfListViewModel.fromFeedJson(res);
    } catch (e) {
      logger.e("Error loading shelves: $e");
      throw Exception('Failed to load shelves: $e');
    }
  }

  Future<ShelfListViewModel> _loadOpdsShelves() async {
    final res = await apiService.getXmlAsJson(
      endpoint: '/shelves',
      authMethod: AuthMethod.basic,
    );
    return ShelfListViewModel.fromFeedJson(res);
  }

  Future<String> createShelf(String shelfName, {bool isPublic = false}) async {
    try {
      final Map<String, dynamic> body = {'title': shelfName};
      if (isPublic) {
        body['is_public'] = 'on';
      }

      final response = await apiService.post(
        endpoint: '/shelf/create',
        authMethod: AuthMethod.cookie,
        body: body,
        useCsrf: true,
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode != 302) {
        logger.e('Failed to create shelf: ${response.body}');
        throw Exception('Failed to create shelf: ${response.body}');
      }

      final shelfId = response.headers['location']!.split('/').last;

      return shelfId;
    } catch (e) {
      logger.e('Error creating shelf: $e');
      throw Exception('Failed to create shelf: $e');
    }
  }

  Future<void> removeBookFromShelf({
    required String bookId,
    required String shelfId,
  }) async {
    try {
      final response = await apiService.post(
        endpoint: '/shelf/remove/$shelfId/$bookId',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
        csrfTokenUrl: '/me',
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 302) {
        logger.e('Failed to remove book from shelf: ${response.body}');
        throw Exception('Failed to remove book from shelf: ${response.body}');
      }
    } catch (e) {
      logger.e('Error removing book from shelf: $e');
      throw Exception('Failed to remove book from shelf: $e');
    }
  }

  Future<void> addBookToShelf({
    required String bookId,
    required String shelfId,
  }) async {
    try {
      final response = await apiService.post(
        endpoint: '/shelf/add/$shelfId/$bookId',
        authMethod: AuthMethod.cookie,
        useCsrf: true,
        csrfTokenUrl: '/me',
        contentType: 'application/x-www-form-urlencoded',
      );

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 302) {
        logger.e('Failed to add book to shelf: ${response.body}');
        throw Exception('Failed to add book to shelf: ${response.body}');
      }
    } catch (e) {
      logger.e('Error adding book to shelf: $e');
      throw Exception('Failed to add book to shelf: $e');
    }
  }

  Future<List<ShelfViewModel>> findShelvesContainingBook(String bookId) async {
    try {
      List<ShelfViewModel> shelves = [];
      ShelfListViewModel shelf = await loadShelves();

      for (var s in shelf.shelves) {
        final ShelfDetailsModel shelfDetails =
            await shelfDetailsRemoteDataSource.getShelfDetails(s.id);

        for (var book in shelfDetails.books) {
          final String shelfBookId = book.id
              .toString()
              .toLowerCase()
              .replaceFirst('urn:uuid:', '');
          final String searchBookId = bookId
              .toString()
              .toLowerCase()
              .replaceFirst('urn:uuid:', '');

          if (shelfBookId == searchBookId) {
            logger.d('Found book in shelf: ${s.title}');
            shelves.add(ShelfViewModel(id: s.id, title: s.title));
          }
        }
      }

      return shelves;
    } catch (e) {
      logger.e('Error finding shelves containing book: $e');
      throw Exception('Failed to find shelves containing book: $e');
    }
  }

  bool getIsOpds() {
    return preferences.getString('server_type') == 'opds' ||
        preferences.getString('server_type') == 'grimmory' ||
        preferences.getString('server_type') == 'booklore';
  }

  Future<bool> supportsMagicShelves() async {
    if (getIsOpds()) return false;
    try {
      final response = await apiService.get(
        endpoint: '/opds/magicshelfindex',
        authMethod: AuthMethod.auto,
      );
      final supported = response.statusCode == 200;
      await preferences.setBool('supports_magic_shelves', supported);
      return supported;
    } catch (e) {
      logger.w('Magic shelf capability probe failed: $e');
      return preferences.getBool('supports_magic_shelves') ?? false;
    }
  }

  Future<MagicShelfListModel> loadMagicShelves() async {
    final res = await apiService.getXmlAsJson(
      endpoint: '/opds/magicshelfindex',
      authMethod: AuthMethod.auto,
    );

    await preferences.setBool('supports_magic_shelves', true);
    return MagicShelfListModel.fromFeedJson(res);
  }

  Future<List<MagicShelfModel>> findMagicShelvesContainingBook(
    String bookId,
  ) async {
    if (preferences.getBool('supports_magic_shelves') == false || getIsOpds()) {
      return const [];
    }
    final search = bookId.toLowerCase().replaceFirst('urn:uuid:', '');
    final result = <MagicShelfModel>[];
    try {
      final list = await loadMagicShelves();
      for (final shelf in list.shelves) {
        try {
          final details = await shelfDetailsRemoteDataSource.getShelfDetails(
            shelf.id,
            isMagic: true,
          );
          final contains = details.books.any((b) {
            final id = b.id.toString().toLowerCase().replaceFirst(
              'urn:uuid:',
              '',
            );
            return id == search;
          });
          if (contains) result.add(shelf);
        } catch (e) {
          logger.w('Magic shelf ${shelf.id} membership check failed: $e');
        }
      }
    } catch (e) {
      logger.e('Error finding magic shelves containing book: $e');
    }
    return result;
  }

  Future<MagicShelfFormData> getMagicShelfFormData({String? shelfId}) async {
    if (shelfId == null) {
      return const MagicShelfFormData(canBePublic: true);
    }

    final response = await apiService
        .get(
          endpoint: '/magicshelf/$shelfId/edit',
          authMethod: AuthMethod.cookie,
        )
        .timeout(const Duration(seconds: 25));
    final body = response.body;
    final doc = html_parser.parse(body);

    final name = doc.querySelector('#shelf-name')?.attributes['value'] ?? '';
    var icon = doc.querySelector('#shelf-icon')?.attributes['value'] ?? '🪄';
    if (icon.trim().isEmpty) icon = '🪄';
    final koboSync =
        doc
            .querySelector('#shelf-kobo-sync')
            ?.attributes
            .containsKey('checked') ??
        false;
    final publicEl = doc.querySelector('#shelf-is-public');
    final canBePublic = publicEl != null;
    final isPublic = publicEl?.attributes.containsKey('checked') ?? false;
    final isSystem = doc.querySelector('.system-template-notice') != null;

    final languages = <String, String>{};
    final langObj = _extractJsObject(body, 'var languages = ');
    if (langObj is Map) {
      langObj.forEach((k, v) => languages[k.toString()] = v.toString());
    }

    MagicGroup? rules;
    final rulesObj = _extractJsObject(body, 'var rules = ');
    if (rulesObj is Map) {
      rules = MagicGroup.fromJson(Map<String, dynamic>.from(rulesObj));
    }

    return MagicShelfFormData(
      name: name,
      icon: icon,
      koboSync: koboSync,
      isPublic: isPublic,
      isSystem: isSystem,
      canBePublic: canBePublic,
      languages: languages,
      rules: rules,
    );
  }

  dynamic _extractJsObject(String body, String prefix) {
    final start = body.indexOf(prefix);
    if (start < 0) return null;
    final braceStart = body.indexOf('{', start);
    if (braceStart < 0) return null;
    final semicolon = body.indexOf(';', start);
    if (semicolon >= 0 && semicolon < braceStart) return null;

    int depth = 0;
    bool inString = false;
    for (int i = braceStart; i < body.length; i++) {
      final ch = body[i];
      if (inString) {
        if (ch == '\\') {
          i++;
        } else if (ch == '"') {
          inString = false;
        }
      } else if (ch == '"') {
        inString = true;
      } else if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) {
          try {
            return jsonDecode(body.substring(braceStart, i + 1));
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }

  Future<void> _magicShelfAction(String endpoint) async {
    final response = await apiService.post(
      endpoint: endpoint,
      authMethod: AuthMethod.cookie,
      body: const <String, dynamic>{},
      contentType: 'application/json',
      useCsrf: true,
      csrfOnlyInHeader: true,
      csrfTokenUrl: '/me',
    );
    if (response.statusCode != 200) {
      String message = 'Action failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] is String) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  Future<void> deleteMagicShelf(String shelfId) =>
      _magicShelfAction('/magicshelf/$shelfId/delete');

  Future<String> duplicateMagicShelf(String shelfId) async {
    final response = await apiService.post(
      endpoint: '/magicshelf/$shelfId/duplicate',
      authMethod: AuthMethod.cookie,
      body: const <String, dynamic>{},
      contentType: 'application/json',
      useCsrf: true,
      csrfOnlyInHeader: true,
      csrfTokenUrl: '/me',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to duplicate shelf (${response.statusCode})');
    }
    try {
      final decoded = jsonDecode(response.body);
      return decoded['shelf_id']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<String> createMagicShelf({
    required String name,
    required Map<String, dynamic> rules,
    required String icon,
    bool koboSync = false,
    bool isPublic = false,
  }) async {
    final response = await apiService.post(
      endpoint: '/magicshelf',
      authMethod: AuthMethod.cookie,
      body: {
        'name': name,
        'rules': rules,
        'icon': icon,
        'kobo_sync': koboSync,
        'is_public': isPublic,
      },
      contentType: 'application/json',
      useCsrf: true,
      csrfOnlyInHeader: true,
      csrfTokenUrl: '/me',
    );
    final decoded = _decodeOrThrow(response.body, response.statusCode);
    return decoded['shelf_id']?.toString() ?? '';
  }

  Future<void> editMagicShelf({
    required String shelfId,
    required String name,
    required Map<String, dynamic> rules,
    required String icon,
    bool koboSync = false,
    bool isPublic = false,
  }) async {
    final response = await apiService.post(
      endpoint: '/magicshelf/$shelfId/edit',
      authMethod: AuthMethod.cookie,
      body: {
        'name': name,
        'rules': rules,
        'icon': icon,
        'kobo_sync': koboSync,
        'is_public': isPublic,
      },
      contentType: 'application/json',
      useCsrf: true,
      csrfOnlyInHeader: true,
      csrfTokenUrl: '/me',
    );
    _decodeOrThrow(response.body, response.statusCode);
  }

  Future<Map<String, dynamic>> previewMagicShelf(
    Map<String, dynamic> rules,
  ) async {
    final response = await apiService.post(
      endpoint: '/magicshelf/preview',
      authMethod: AuthMethod.cookie,
      body: {'rules': rules},
      contentType: 'application/json',
      useCsrf: true,
      csrfOnlyInHeader: true,
      csrfTokenUrl: '/me',
    );
    return _decodeOrThrow(response.body, response.statusCode);
  }

  Map<String, dynamic> _decodeOrThrow(String body, int statusCode) {
    Map<String, dynamic>? decoded;
    try {
      final d = jsonDecode(body);
      if (d is Map<String, dynamic>) decoded = d;
    } catch (_) {}

    if (statusCode != 200 || decoded == null || decoded['success'] != true) {
      final message =
          decoded?['message']?.toString() ?? 'Request failed ($statusCode)';
      throw Exception(message);
    }
    return decoded;
  }

  Future<void> hideMagicShelf(String shelfId) =>
      _magicShelfAction('/magicshelf/$shelfId/hide');

  Future<void> unhideMagicShelf(String shelfId) =>
      _magicShelfAction('/magicshelf/$shelfId/unhide');
}
