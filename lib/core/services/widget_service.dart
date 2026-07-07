import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/image_cache_manager.dart';
import 'package:calibre_web_companion/features/offline/data/repositories/offline_library_repository.dart';
import 'package:calibre_web_companion/features/settings/data/models/predefined_colors.dart';

enum WidgetTapTarget { bookDetails, internalReader, externalReader, appOnly }

extension WidgetTapTargetX on WidgetTapTarget {
  String get key {
    switch (this) {
      case WidgetTapTarget.bookDetails:
        return 'book_details';
      case WidgetTapTarget.internalReader:
        return 'internal_reader';
      case WidgetTapTarget.externalReader:
        return 'external_reader';
      case WidgetTapTarget.appOnly:
        return 'app_only';
    }
  }

  static WidgetTapTarget fromKey(String? key) {
    switch (key) {
      case 'internal_reader':
        return WidgetTapTarget.internalReader;
      case 'external_reader':
        return WidgetTapTarget.externalReader;
      case 'app_only':
        return WidgetTapTarget.appOnly;
      case 'book_details':
      default:
        return WidgetTapTarget.bookDetails;
    }
  }
}

class WidgetService {
  final SharedPreferences prefs;
  final Logger logger;
  final OfflineLibraryRepository offlineRepository;

  WidgetService({
    required this.prefs,
    required this.logger,
    required this.offlineRepository,
  });

  static const String _currentBookProvider = 'CurrentBookWidgetProvider';
  static const String _statsProvider = 'LibraryStatsWidgetProvider';

  static const String kTapTargetKey = 'widget_tap_target';
  static const String _kCurrentBookKey = 'widget_current_book';

  bool get _supported => Platform.isAndroid;

  WidgetTapTarget get tapTarget =>
      WidgetTapTargetX.fromKey(prefs.getString(kTapTargetKey));

  Future<void> setTapTarget(WidgetTapTarget target) async {
    await prefs.setString(kTapTargetKey, target.key);
  }

  Map<String, dynamic>? get currentBookRaw {
    final raw = prefs.getString(_kCurrentBookKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> recordCurrentBook({
    required String uuid,
    required int id,
    required String title,
    required String authors,
    String? coverUrl,
    String format = 'epub',
    double? progress,
  }) async {
    if (uuid.isEmpty) return;

    double resolvedProgress = (progress ?? 0.0).clamp(0.0, 1.0);
    if (progress == null) {
      final existing = currentBookRaw;
      if (existing != null && existing['uuid'] == uuid) {
        resolvedProgress = ((existing['progress'] as num?)?.toDouble() ?? 0.0)
            .clamp(0.0, 1.0);
      }
    }

    final record = <String, dynamic>{
      'uuid': uuid,
      'id': id,
      'title': title,
      'authors': authors,
      'coverUrl': coverUrl ?? '',
      'format': format,
      'progress': resolvedProgress,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_kCurrentBookKey, jsonEncode(record));
    await _pushCurrentBook(record, refreshCover: true);
  }

  Future<void> updateProgress(String uuid, double progress) async {
    final raw = currentBookRaw;
    if (raw == null || raw['uuid'] != uuid) return;
    final clamped = progress.clamp(0.0, 1.0);
    raw['progress'] = clamped;
    await prefs.setString(_kCurrentBookKey, jsonEncode(raw));
    if (!_supported) return;
    try {
      await HomeWidget.saveWidgetData<String>(
        'cb_progress',
        (clamped * 100).round().toString(),
      );
      await HomeWidget.updateWidget(androidName: _currentBookProvider);
    } catch (e) {
      logger.w('Failed to update widget progress: $e');
    }
  }

  Future<void> clearCurrentBook() async {
    await prefs.remove(_kCurrentBookKey);
    if (!_supported) return;
    try {
      await HomeWidget.saveWidgetData<String>('cb_uuid', '');
      await HomeWidget.updateWidget(androidName: _currentBookProvider);
    } catch (e) {
      logger.w('Failed to clear current book widget: $e');
    }
  }

  Future<void> _pushCurrentBook(
    Map<String, dynamic> record, {
    required bool refreshCover,
  }) async {
    if (!_supported) return;
    try {
      String coverPath = prefs.getString('widget_current_cover_path') ?? '';
      if (refreshCover) {
        final materialized = await _materializeCover(
          record['uuid'] as String,
          (record['id'] as num?)?.toInt() ?? 0,
          (record['coverUrl'] as String?) ?? '',
        );
        coverPath = materialized ?? '';
        await prefs.setString('widget_current_cover_path', coverPath);
      }

      final progress = ((record['progress'] as num?)?.toDouble() ?? 0.0);
      await HomeWidget.saveWidgetData<String>(
        'cb_uuid',
        record['uuid'] as String,
      );
      await HomeWidget.saveWidgetData<String>(
        'cb_title',
        record['title'] as String? ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        'cb_authors',
        record['authors'] as String? ?? '',
      );
      await HomeWidget.saveWidgetData<String>('cb_cover', coverPath);
      await HomeWidget.saveWidgetData<String>(
        'cb_progress',
        (progress * 100).round().toString(),
      );
      await HomeWidget.updateWidget(androidName: _currentBookProvider);
    } catch (e) {
      logger.w('Failed to push current book widget: $e');
    }
  }

  Future<void> pushStats({
    required int books,
    required int authors,
    required int categories,
    required int series,
  }) async {
    if (!_supported) return;
    try {
      await HomeWidget.saveWidgetData<String>('st_books', books.toString());
      await HomeWidget.saveWidgetData<String>('st_authors', authors.toString());
      await HomeWidget.saveWidgetData<String>(
        'st_categories',
        categories.toString(),
      );
      await HomeWidget.saveWidgetData<String>('st_series', series.toString());
      await HomeWidget.updateWidget(androidName: _statsProvider);
    } catch (e) {
      logger.w('Failed to push stats widget: $e');
    }
  }

  Future<void> pushThemeColors() async {
    final seed = _resolveSeedColor();
    final light = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    final dark = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    final palette = <String, Color>{
      'th_bg_light': light.secondaryContainer,
      'th_bg_dark': dark.secondaryContainer,
      'th_on_bg_light': light.onSecondaryContainer,
      'th_on_bg_dark': dark.onSecondaryContainer,
      'th_tile_light': light.primaryContainer,
      'th_tile_dark': dark.primaryContainer,
      'th_on_tile_light': light.onPrimaryContainer,
      'th_on_tile_dark': dark.onPrimaryContainer,
      'th_accent_light': light.primary,
      'th_accent_dark': dark.primary,
      'th_on_accent_light': light.onPrimary,
      'th_on_accent_dark': dark.onPrimary,
    };

    for (final entry in palette.entries) {
      await prefs.setString(entry.key, _hex(entry.value));
    }

    if (!_supported) return;
    try {
      for (final entry in palette.entries) {
        await HomeWidget.saveWidgetData<String>(entry.key, _hex(entry.value));
      }
      await HomeWidget.updateWidget(androidName: _currentBookProvider);
      await HomeWidget.updateWidget(androidName: _statsProvider);
    } catch (e) {
      logger.w('Failed to push widget theme colors: $e');
    }
  }

  Color _resolveSeedColor() {
    final key = prefs.getString('theme_color_key') ?? 'lightGreen';
    return PredefinedColors.predefinedColors[key] ?? Colors.lightGreen;
  }

  String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';

  Stream<Uri?> get widgetClicks => HomeWidget.widgetClicked;

  Future<Uri?> initialWidgetLaunch() =>
      HomeWidget.initiallyLaunchedFromHomeWidget();

  Future<String?> _materializeCover(
    String uuid,
    int id,
    String coverUrl,
  ) async {
    try {
      final offlinePath = offlineRepository.getBook(uuid)?.coverPath;
      if (offlinePath != null && offlinePath.isNotEmpty) {
        final file = File(offlinePath);
        if (await file.exists() && await file.length() > 0) {
          return _copyToWidgetDir(uuid, file);
        }
      }
    } catch (e) {
      logger.w('Widget offline cover lookup failed: $e');
    }

    final url = _buildCoverImageUrl(id, coverUrl);
    if (url != null) {
      try {
        final cached = await CustomCacheManager().getSingleFile(url);
        if (await cached.exists() && await cached.length() > 0) {
          return _copyToWidgetDir(uuid, cached);
        }
      } catch (e) {
        logger.w('Widget cover fetch failed for "$url": $e');
      }
    }

    logger.w('No usable widget cover for $uuid (coverUrl="$coverUrl", id=$id)');
    return null;
  }

  String? _buildCoverImageUrl(int id, String coverUrl) {
    final baseUrl = ApiService().getBaseUrl();
    if (baseUrl.isEmpty) return null;

    if (coverUrl.isNotEmpty) {
      var clean = coverUrl.split('/api/v1/opds/').last;
      if (clean.startsWith('/')) clean = clean.substring(1);
      return '$baseUrl/$clean';
    }
    if (id <= 0) return null;

    final isCalibre = prefs.getString('server_type') == 'calibre';
    if (isCalibre) {
      final libraryId = prefs.getString('calibre_library_id');
      final segment =
          (libraryId != null && libraryId.isNotEmpty) ? '/$libraryId' : '';
      return '$baseUrl/get/cover/$id$segment';
    }
    return '$baseUrl/opds/cover/$id';
  }

  Future<String?> _copyToWidgetDir(String uuid, File source) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final widgetDir = Directory(p.join(supportDir.path, 'widget'));
      if (!await widgetDir.exists()) {
        await widgetDir.create(recursive: true);
      }

      final dest = File(
        p.join(widgetDir.path, 'cover_${uuid.hashCode.toUnsigned(32)}.png'),
      );
      await source.copy(dest.path);
      return dest.path;
    } catch (e) {
      logger.w('Failed to copy widget cover: $e');
      return null;
    }
  }
}
