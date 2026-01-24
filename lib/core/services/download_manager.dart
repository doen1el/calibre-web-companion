import 'dart:convert';
import 'dart:io';
import 'package:docman/docman.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadManager {
  final SharedPreferences _prefs;
  final Logger _logger;

  Map<String, String> _downloadedBooks = {};
  static const String _storageKey = 'downloaded_books_map';

  DownloadManager({required SharedPreferences prefs, required Logger logger})
    : _prefs = prefs,
      _logger = logger;

  Future<void> initialize() async {
    final String? jsonString = _prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        _downloadedBooks = decoded.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      } catch (e) {
        _logger.e('Error decoding downloaded books map: $e');
        _downloadedBooks = {};
      }
    }

    await _verifyFilesExist();
  }

  Future<bool> _doesFileExist(String path) async {
    try {
      final doc = await DocumentFile.fromUri(path);
      return doc?.exists ?? false;
    } catch (e) {
      _logger.w('Failed to check existence for $path: $e');
      return false;
    }
  }

  Future<void> _verifyFilesExist() async {
    final List<String> toRemove = [];

    for (var entry in _downloadedBooks.entries) {
      final exists = await _doesFileExist(entry.value);

      if (!exists) {
        _logger.i(
          'File for book ${entry.key} not found at ${entry.value}. Removing from list.',
        );
        toRemove.add(entry.key);
      }
    }

    if (toRemove.isNotEmpty) {
      for (var uuid in toRemove) {
        _downloadedBooks.remove(uuid);
      }
      await _save();
    }

    _logger.i(
      'DownloadManager initialized. ${_downloadedBooks.length} books verified.',
    );
  }

  Future<bool> checkFileExistence(String uuid) async {
    final path = _downloadedBooks[uuid];
    if (path == null) return false;

    final exists = await _doesFileExist(path);
    if (!exists) {
      _logger.i('Runtime check: File for $uuid missing. Unregistering.');
      await unregisterDownload(uuid);
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    await _prefs.setString(_storageKey, json.encode(_downloadedBooks));
  }

  bool isBookDownloaded(String uuid) {
    return _downloadedBooks.containsKey(uuid);
  }

  String? getBookPath(String uuid) {
    return _downloadedBooks[uuid];
  }

  Future<void> registerDownload(String uuid, String path) async {
    _downloadedBooks[uuid] = path;
    await _save();
    _logger.i('Registered download for book $uuid at $path');
  }

  Future<void> unregisterDownload(String uuid) async {
    if (_downloadedBooks.containsKey(uuid)) {
      _downloadedBooks.remove(uuid);
      await _save();
    }
  }
}
