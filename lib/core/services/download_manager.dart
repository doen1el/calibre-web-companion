import 'dart:convert';
import 'dart:io';

import 'package:docman/docman.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadManager {
  final SharedPreferences _prefs;
  final Logger _logger;

  // uuid -> {lower-cased extension -> path}; legacy uuid -> path is migrated.
  Map<String, Map<String, String>> _downloadedBooks = {};
  static const String _storageKey = 'downloaded_books_map';

  DownloadManager({required SharedPreferences prefs, required Logger logger})
    : _prefs = prefs,
      _logger = logger;

  Future<void> initialize() async {
    final String? jsonString = _prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        final Map<String, Map<String, String>> books = {};
        decoded.forEach((uuid, value) {
          if (value is Map) {
            books[uuid] = value.map(
              (format, path) => MapEntry(format.toString(), path.toString()),
            );
          } else if (value is String) {
            // Legacy format: a single path per book.
            books[uuid] = {_formatOfPath(value): value};
          }
        });
        _downloadedBooks = books;
      } catch (e) {
        _logger.e('Error decoding downloaded books map: $e');
        _downloadedBooks = {};
      }
    }

    await _verifyFilesExist();
  }

  Future<bool> _doesFileExist(String path) async {
    try {
      if (Platform.isAndroid) {
        final doc = await DocumentFile.fromUri(path);
        return doc?.exists ?? false;
      } else {
        return File(path).existsSync();
      }
    } catch (e) {
      _logger.w('Failed to check existence for $path: $e');
      return false;
    }
  }

  Future<void> _verifyFilesExist() async {
    var changed = false;
    final removedBooks = <String>[];

    for (final uuid in List.of(_downloadedBooks.keys)) {
      final formats = _downloadedBooks[uuid]!;
      final remaining = <String, String>{};
      for (final format in List.of(formats.keys)) {
        final path = formats[format]!;
        if (await _doesFileExist(path)) {
          remaining[format] = path;
        } else {
          changed = true;
          _logger.i(
            'File for book $uuid ($format) not found at $path. '
            'Removing from list.',
          );
        }
      }
      if (remaining.isEmpty) {
        removedBooks.add(uuid);
        changed = true;
      } else if (remaining.length != formats.length) {
        _downloadedBooks[uuid] = remaining;
      }
    }

    for (final uuid in removedBooks) {
      _downloadedBooks.remove(uuid);
    }

    if (changed) {
      await _save();
    }

    _logger.i(
      'DownloadManager initialized. ${_downloadedBooks.length} books verified.',
    );
  }

  Future<bool> checkFileExistence(String uuid) async {
    final formats = _downloadedBooks[uuid];
    if (formats == null) return false;

    final remaining = <String, String>{};
    for (final format in List.of(formats.keys)) {
      final path = formats[format]!;
      if (await _doesFileExist(path)) {
        remaining[format] = path;
      } else {
        _logger.i(
          'Runtime check: $format file for $uuid missing at $path. Unregistering.',
        );
      }
    }

    if (remaining.isEmpty) {
      await unregisterDownload(uuid);
      return false;
    }
    if (remaining.length != formats.length) {
      _downloadedBooks[uuid] = remaining;
      await _save();
    }
    return true;
  }

  Future<void> _save() async {
    await _prefs.setString(_storageKey, json.encode(_downloadedBooks));
  }

  bool isBookDownloaded(String uuid) {
    return _downloadedBooks.containsKey(uuid);
  }

  /// With [format], only that format's path — never another format's file.
  String? getBookPath(String uuid, {String? format}) {
    final formats = _downloadedBooks[uuid];
    if (formats == null || formats.isEmpty) return null;
    if (format != null) return formats[format.toLowerCase()];
    return formats.values.first;
  }

  Set<String> downloadedFormats(String uuid) {
    final formats = _downloadedBooks[uuid];
    return formats == null
        ? const <String>{}
        : formats.keys.map((f) => f.toLowerCase()).toSet();
  }

  List<String> allBookPaths(String uuid) =>
      List.unmodifiable(_downloadedBooks[uuid]?.values ?? const <String>[]);

  Map<String, String> get allDownloads => _downloadedBooks.map(
    (uuid, formats) => MapEntry(uuid, formats.values.first),
  );

  Future<void> registerDownload(String uuid, String path) async {
    final format = _formatOfPath(path);
    final formats = Map<String, String>.from(_downloadedBooks[uuid] ?? {});
    formats[format] = path;
    _downloadedBooks[uuid] = formats;
    await _save();
    _logger.i('Registered download for book $uuid ($format) at $path');
  }

  Future<void> unregisterDownload(String uuid) async {
    if (_downloadedBooks.containsKey(uuid)) {
      _downloadedBooks.remove(uuid);
      await _save();
    }
  }

  static String _formatOfPath(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return 'unknown';
    return name.substring(dot + 1).toLowerCase();
  }
}
