import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/offline/data/models/offline_book_model.dart';

class OfflineLibraryRepository {
  final SharedPreferences _prefs;
  final Logger _logger;

  static const String _storageKey = 'offline_library';
  static const String _coverDirName = 'offline_covers';

  OfflineLibraryRepository({
    required SharedPreferences prefs,
    required Logger logger,
  }) : _prefs = prefs,
       _logger = logger;

  Map<String, dynamic> _readMap() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (e) {
      _logger.w('Could not decode offline library: $e');
      return {};
    }
  }

  Future<void> _writeMap(Map<String, dynamic> map) async {
    await _prefs.setString(_storageKey, json.encode(map));
  }

  List<OfflineBookModel> getAll() {
    final map = _readMap();
    final books =
        map.values
            .whereType<Map>()
            .map((e) => OfflineBookModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    books.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return books;
  }

  OfflineBookModel? getBook(String uuid) {
    final map = _readMap();
    final entry = map[uuid];
    if (entry is Map) {
      return OfflineBookModel.fromJson(Map<String, dynamic>.from(entry));
    }
    return null;
  }

  Future<void> saveBook(OfflineBookModel book, {Uint8List? coverBytes}) async {
    var toStore = book;
    if (coverBytes != null && coverBytes.isNotEmpty) {
      final coverPath = await _writeCover(book.uuid, coverBytes);
      if (coverPath != null) toStore = book.copyWith(coverPath: coverPath);
    }
    final map = _readMap();
    map[book.uuid] = toStore.toJson();
    await _writeMap(map);
    _logger.i('Saved offline metadata for "${book.title}"');
  }

  Future<void> remove(String uuid) async {
    final map = _readMap();
    final existing = map[uuid];
    if (existing is Map) {
      final coverPath = existing['coverPath']?.toString();
      if (coverPath != null && coverPath.isNotEmpty) {
        try {
          final f = File(coverPath);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
    }
    map.remove(uuid);
    await _writeMap(map);
  }

  bool isSaved(String uuid) => _readMap().containsKey(uuid);

  Future<String?> _writeCover(String uuid, Uint8List bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${dir.path}/$_coverDirName');
      if (!coverDir.existsSync()) coverDir.createSync(recursive: true);
      final safeName = uuid.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final file = File('${coverDir.path}/$safeName.img');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      _logger.w('Could not cache cover for $uuid: $e');
      return null;
    }
  }
}
