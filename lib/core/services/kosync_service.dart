import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Outcome of a call against the `/kosync` endpoints, so the UI can tell
/// "wrong password" apart from "this server has no KOReader sync".
enum KoSyncStatus { ok, unauthorized, unavailable, disabled, error }

class KoSyncResult {
  final KoSyncStatus status;
  final String? message;

  const KoSyncResult(this.status, {this.message});

  bool get isOk => status == KoSyncStatus.ok;
}

/// A reading position as the server hands it out.
///
/// [progress] is `null` for percentage-only rows — the encoding used by
/// producers that cannot express a position as a KOReader locator.
class KoSyncProgress {
  final String document;
  final double percentage;
  final String? progress;
  final String positionKind;
  final String? device;
  final DateTime? timestamp;
  final int? calibreBookId;
  final String? calibreBookTitle;

  const KoSyncProgress({
    required this.document,
    required this.percentage,
    this.progress,
    this.positionKind = 'locator',
    this.device,
    this.timestamp,
    this.calibreBookId,
    this.calibreBookTitle,
  });

  factory KoSyncProgress.fromJson(Map<String, dynamic> json) {
    // The wire format is a decimal fraction (0.4567 = 45.67%).
    final rawPercentage = json['percentage'];
    final fraction =
        rawPercentage is num
            ? rawPercentage.toDouble()
            : double.tryParse('$rawPercentage') ?? 0.0;

    final rawTimestamp = json['timestamp'];
    final seconds = rawTimestamp is num ? rawTimestamp.toInt() : null;

    return KoSyncProgress(
      document: json['document']?.toString() ?? '',
      percentage: (fraction * 100).clamp(0.0, 100.0),
      progress: json['progress'] as String?,
      positionKind: json['position_kind']?.toString() ?? 'locator',
      device: json['device']?.toString(),
      timestamp:
          seconds == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
      calibreBookId:
          json['calibre_book_id'] is num
              ? (json['calibre_book_id'] as num).toInt()
              : null,
      calibreBookTitle: json['calibre_book_title']?.toString(),
    );
  }
}

/// Client for the KOReader sync API that Calibre-Web NextGen (and CWA) expose
/// under `<server>/kosync`.
class KoSyncService {
  final ApiService apiService;
  final Logger logger;

  static const String enabledKey = 'kosync_enabled';

  /// Sent so the server also serves percentage-only rows (the web reader, a
  /// Kobo). Without it those rows are withheld and a book read outside
  /// KOReader looks like "no progress".
  static const String _positionKinds = 'locator,percentage';

  static const Map<String, String> _acceptHeaders = {
    'accept': 'application/vnd.koreader.v1+json',
  };

  KoSyncService({required this.apiService, required this.logger});

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? false;
  }

  /// KOReader's `partialMD5`: 1024 bytes sampled at 0, 1K, 4K, 16K, 64K, 256K,
  /// 1M, 4M, 16M, 64M, 256M and 1G, hashed as one stream.
  static String partialMd5(Uint8List bytes) {
    const int step = 1024;
    const int sampleSize = 1024;

    final samples = BytesBuilder(copy: false);
    for (int i = -1; i <= 10; i++) {
      final int maskedShift = (2 * i) & 0x1F;
      final int offset = (step << maskedShift) & 0xFFFFFFFF;
      if (offset >= bytes.length) break;

      final int end = min(offset + sampleSize, bytes.length);
      samples.add(Uint8List.sublistView(bytes, offset, end));
    }

    return md5.convert(samples.takeBytes()).toString();
  }

  /// Verifies credentials and that the endpoint exists at all.
  Future<KoSyncResult> testConnection() async {
    try {
      final response = await apiService.get(
        endpoint: '/kosync/users/auth',
        authMethod: AuthMethod.basic,
        extraHeaders: _acceptHeaders,
        checkStatus: false,
      );
      return _classify(response.statusCode, response.body);
    } catch (e) {
      logger.e('KOSync: auth check failed: $e');
      return KoSyncResult(KoSyncStatus.error, message: e.toString());
    }
  }

  /// Reads the stored position for [document], falling back to [fallbackDocument]
  /// when the first identifier resolves to nothing.
  Future<KoSyncProgress?> fetchProgress({
    required String document,
    String? fallbackDocument,
  }) async {
    final progress = await _fetchOne(document);
    if (progress != null) return progress;

    if (fallbackDocument != null &&
        fallbackDocument.isNotEmpty &&
        fallbackDocument != document) {
      logger.d('KOSync: no row for $document, retrying as $fallbackDocument');
      return _fetchOne(fallbackDocument);
    }
    return null;
  }

  Future<KoSyncProgress?> _fetchOne(String document) async {
    try {
      final response = await apiService.get(
        endpoint: '/kosync/syncs/progress/${Uri.encodeComponent(document)}',
        authMethod: AuthMethod.basic,
        queryParams: {'position_kinds': _positionKinds},
        extraHeaders: _acceptHeaders,
        checkStatus: false,
      );

      final result = _classify(response.statusCode, response.body);
      if (!result.isOk) {
        logger.w('KOSync: progress fetch failed (${result.status.name})');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      // A book with no progress answers `{}`; a withheld position names the
      // encodings it holds, which cannot happen here since we advertise both.
      if (decoded['percentage'] == null) return null;

      return KoSyncProgress.fromJson(decoded);
    } catch (e) {
      logger.e('KOSync: progress fetch for $document failed: $e');
      return null;
    }
  }

  /// Publishes [percentage] (0-100) as this user's position in [bookId].
  Future<bool> pushProgress({
    required int bookId,
    required double percentage,
    int spineIndex = -1,
  }) async {
    if (percentage <= 0 || percentage > 100) return false;

    try {
      final bookmark =
          spineIndex >= 0
              ? spineStartCfi(spineIndex)
              : await _fetchBookmark(bookId);
      if (bookmark == null || bookmark.isEmpty) {
        logger.w('KOSync: no bookmark for book $bookId, skipping push');
        return false;
      }

      final csrfToken = await _csrfToken();
      final response = await apiService.post(
        endpoint: '/api/v1/books/$bookId/bookmark',
        authMethod: AuthMethod.auto,
        body: {
          'format': 'epub',
          'bookmark': bookmark,
          'percentage': percentage,
        },
        extraHeaders: {
          if (csrfToken != null) 'X-CSRFToken': csrfToken,
          'Accept': 'application/json',
        },
        checkStatus: false,
      );

      // The route answers 204 on success.
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (!ok) {
        logger.w('KOSync: push rejected with HTTP ${response.statusCode}');
      } else {
        logger.i(
          'KOSync: pushed ${percentage.toStringAsFixed(1)}% for book $bookId',
        );
      }
      return ok;
    } catch (e) {
      logger.e('KOSync: push for book $bookId failed: $e');
      return false;
    }
  }

  /// A CFI pointing at the body of spine item [spineIndex]: `/6` is the spine
  /// in the package document, each itemref takes two steps, and `!/4` enters
  /// the content document's body.
  static String spineStartCfi(int spineIndex) =>
      'epubcfi(/6/${(spineIndex + 1) * 2}!/4)';

  Future<String?> _fetchBookmark(int bookId) async {
    final response = await apiService.get(
      endpoint: '/api/v1/books/$bookId/bookmark',
      authMethod: AuthMethod.auto,
      queryParams: {'format': 'epub'},
      checkStatus: false,
    );
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded['bookmark'] as String?;
  }

  Future<String?> _csrfToken() async {
    try {
      final response = await apiService.get(
        endpoint: '/api/v1/auth/csrf',
        authMethod: AuthMethod.auto,
        checkStatus: false,
      );
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final token = decoded['csrf_token'];
      return token is String && token.isNotEmpty ? token : null;
    } catch (e) {
      logger.w('KOSync: could not fetch CSRF token: $e');
      return null;
    }
  }

  KoSyncResult _classify(int statusCode, String body) {
    if (statusCode == 200) return const KoSyncResult(KoSyncStatus.ok);
    if (statusCode == 401) return const KoSyncResult(KoSyncStatus.unauthorized);
    if (statusCode == 503) return const KoSyncResult(KoSyncStatus.disabled);
    if (statusCode == 404) {
      return const KoSyncResult(KoSyncStatus.unavailable);
    }
    return KoSyncResult(
      KoSyncStatus.error,
      message:
          'HTTP $statusCode: ${body.length > 200 ? body.substring(0, 200) : body}',
    );
  }
}
