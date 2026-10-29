import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderCacheEntry {
  final String uuid;
  final String format;
  final String path;
  final int sizeBytes;
  final DateTime lastUsed;

  const ReaderCacheEntry({
    required this.uuid,
    required this.format,
    required this.path,
    required this.sizeBytes,
    required this.lastUsed,
  });
}

// Keeps books opened in the internal reader on the device, so reading them
// again neither re-streams nor needs the server. Oldest-used go first once the
// limit is exceeded.
class ReaderCacheService {
  final SharedPreferences _prefs;
  final Logger _logger;
  final Future<Directory> Function() _baseDirectory;

  static const String enabledKey = 'reader_cache_enabled';
  static const String limitKey = 'reader_cache_limit_mb';
  static const int defaultLimitMb = 500;
  static const List<int> limitOptionsMb = [100, 250, 500, 1000, 2000, 5000];

  static const String _dirName = 'reader_cache';

  ReaderCacheService({
    required SharedPreferences prefs,
    required Logger logger,
    Future<Directory> Function()? baseDirectory,
  }) : _prefs = prefs,
       _logger = logger,
       _baseDirectory = baseDirectory ?? getApplicationSupportDirectory;

  bool get isEnabled => _prefs.getBool(enabledKey) ?? true;

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(enabledKey, value);
    if (!value) await clear();
  }

  int get limitMb => _prefs.getInt(limitKey) ?? defaultLimitMb;

  Future<void> setLimitMb(int value) async {
    await _prefs.setInt(limitKey, value);
    await _evict();
  }

  Future<Directory> _dir() async {
    final base = await _baseDirectory();
    final dir = Directory('${base.path}/$_dirName');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  // The uuid is kept readable in the name so entries() can map files back.
  String _fileName(String uuid, String format) {
    final safeUuid = uuid.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '_');
    return '$safeUuid.${format.toLowerCase()}';
  }

  Future<File?> find(String uuid, String format) async {
    try {
      final file = File('${(await _dir()).path}/${_fileName(uuid, format)}');
      if (!file.existsSync()) return null;
      await file.setLastModified(DateTime.now());
      return file;
    } catch (e) {
      _logger.w('Reader cache lookup for $uuid failed: $e');
      return null;
    }
  }

  Future<String?> store(String uuid, String format, Uint8List bytes) async {
    if (!isEnabled || bytes.isEmpty) return null;
    if (bytes.length > limitMb * 1024 * 1024) return null;

    try {
      final file = File('${(await _dir()).path}/${_fileName(uuid, format)}');
      await file.writeAsBytes(bytes, flush: true);
      await _evict(keep: file.path);
      _logger.i('Cached "$uuid.$format" for the reader (${bytes.length} B)');
      return file.path;
    } catch (e) {
      _logger.w('Could not cache $uuid for the reader: $e');
      return null;
    }
  }

  Future<List<ReaderCacheEntry>> entries() async {
    try {
      final files = (await _dir()).listSync().whereType<File>();
      final result = <ReaderCacheEntry>[];
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        final dot = name.lastIndexOf('.');
        if (dot <= 0) continue;
        final stat = file.statSync();
        result.add(
          ReaderCacheEntry(
            uuid: name.substring(0, dot),
            format: name.substring(dot + 1),
            path: file.path,
            sizeBytes: stat.size,
            lastUsed: stat.modified,
          ),
        );
      }
      result.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return result;
    } catch (e) {
      _logger.w('Could not list reader cache: $e');
      return const [];
    }
  }

  Future<int> usedBytes() async {
    final all = await entries();
    return all.fold<int>(0, (sum, e) => sum + e.sizeBytes);
  }

  Future<void> remove(String uuid) async {
    for (final entry in await entries()) {
      if (entry.uuid == uuid) {
        try {
          File(entry.path).deleteSync();
        } catch (_) {}
      }
    }
  }

  Future<void> clear() async {
    try {
      final dir = await _dir();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (e) {
      _logger.w('Could not clear reader cache: $e');
    }
  }

  Future<void> _evict({String? keep}) async {
    final limit = limitMb * 1024 * 1024;
    final all = await entries();
    var total = all.fold<int>(0, (sum, e) => sum + e.sizeBytes);

    for (final entry in all.reversed) {
      if (total <= limit) break;
      if (entry.path == keep) continue;
      try {
        File(entry.path).deleteSync();
        total -= entry.sizeBytes;
        _logger.i('Evicted ${entry.uuid} from the reader cache');
      } catch (_) {}
    }
  }
}
