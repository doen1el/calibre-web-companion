import 'dart:typed_data';

import 'package:logger/logger.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/connectivity_service.dart';
import 'package:calibre_web_companion/core/services/download_manager.dart';
import 'package:calibre_web_companion/features/book_details/data/repositories/book_details_repository.dart';
import 'package:calibre_web_companion/features/offline/data/models/offline_book_model.dart';
import 'package:calibre_web_companion/features/offline/data/repositories/offline_library_repository.dart';

class OfflineBackfillService {
  final DownloadManager downloadManager;
  final OfflineLibraryRepository offlineRepository;
  final BookDetailsRepository bookDetailsRepository;
  final ConnectivityService connectivityService;
  final ApiService apiService;
  final Logger logger;

  OfflineBackfillService({
    required this.downloadManager,
    required this.offlineRepository,
    required this.bookDetailsRepository,
    required this.connectivityService,
    required this.apiService,
    required this.logger,
  });

  bool _completed = false;

  Future<void> run() async {
    if (_completed) return;

    final pending =
        downloadManager.allDownloads.entries
            .where((e) => !offlineRepository.isSaved(e.key))
            .toList();
    if (pending.isEmpty) {
      _completed = true;
      return;
    }

    if (!await connectivityService.isServerReachable()) return;

    logger.i(
      'Offline backfill: enriching ${pending.length} downloaded book(s)',
    );
    for (final entry in pending) {
      final uuid = entry.key;
      try {
        final json = await apiService.getJson(
          endpoint: '/ajax/book/$uuid',
          authMethod: AuthMethod.auto,
        );

        final title = (json['title']?.toString() ?? '').trim();
        if (title.isEmpty) continue;

        final authors =
            json['authors'] is List
                ? (json['authors'] as List).map((a) => a.toString()).join(', ')
                : (json['authors']?.toString() ?? '');
        final series = json['series']?.toString() ?? '';
        final seriesIndex =
            double.tryParse(json['series_index']?.toString() ?? '')?.toInt() ??
            0;

        final id = _extractId(json);
        Uint8List? cover;
        if (id != null) {
          cover = await bookDetailsRepository.fetchCoverBytes(id, null);
        }

        await offlineRepository.saveBook(
          OfflineBookModel(
            uuid: uuid,
            id: id ?? 0,
            title: title,
            authors: authors,
            series: series,
            seriesIndex: seriesIndex,
            filePath: entry.value,
            format: _formatFromPath(entry.value),
            savedAt: DateTime.now().millisecondsSinceEpoch,
          ),
          coverBytes: cover,
        );
      } catch (e) {
        logger.w('Offline backfill failed for $uuid: $e');
      }
    }
    _completed = true;
  }

  int? _extractId(Map<String, dynamic> json) {
    for (final key in ['id', 'application_id', 'book_id']) {
      final value = json[key];
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  String _formatFromPath(String path) {
    String name;
    try {
      name = Uri.decodeFull(path);
    } catch (_) {
      name = path;
    }
    name = name.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(dot + 1).toLowerCase() : 'epub';
  }
}
