import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class HighlightModel {
  final String id;
  final String bookId;
  final int chapterIndex;
  final String paragraphKey; // hash of paragraph plain text to identify it
  final int startIndex; // selection start in paragraph plain text
  final int endIndex;
  final String selectedText;
  final int colorValue;

  HighlightModel({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.paragraphKey,
    required this.startIndex,
    required this.endIndex,
    required this.selectedText,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'chapterIndex': chapterIndex,
        'paragraphKey': paragraphKey,
        'startIndex': startIndex,
        'endIndex': endIndex,
        'selectedText': selectedText,
        'colorValue': colorValue,
      };

  factory HighlightModel.fromJson(Map<String, dynamic> json) => HighlightModel(
        id: json['id'],
        bookId: json['bookId'],
        chapterIndex: json['chapterIndex'],
        paragraphKey: json['paragraphKey'] ?? '',
        startIndex: json['startIndex'] ?? 0,
        endIndex: json['endIndex'] ?? 0,
        selectedText: json['selectedText'] ?? '',
        colorValue: json['colorValue'],
      );

  static String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  /// Create a stable key from paragraph text (first 50 chars + length).
  static String makeParagraphKey(String plainText) {
    final clean = plainText.replaceAll('\u00AD', '').trim();
    final prefix = clean.length > 50 ? clean.substring(0, 50) : clean;
    return '${prefix.hashCode}_${clean.length}';
  }
}

class HighlightStorage {
  static const _key = 'cosmos_highlights_v2';
  static final _gs = GetStorage();

  static List<HighlightModel> getParagraphHighlights(
      String bookId, int chapterIndex, String paragraphKey) {
    return _readAll()
        .where((h) =>
            h.bookId == bookId &&
            h.chapterIndex == chapterIndex &&
            h.paragraphKey == paragraphKey)
        .toList();
  }

  static List<HighlightModel> getBookHighlights(String bookId) {
    return _readAll().where((h) => h.bookId == bookId).toList();
  }

  static void addOrUpdate(HighlightModel highlight) {
    final all = _readAll();
    // Check for existing highlight at same position → update color
    final idx = all.indexWhere((h) =>
        h.bookId == highlight.bookId &&
        h.chapterIndex == highlight.chapterIndex &&
        h.paragraphKey == highlight.paragraphKey &&
        h.startIndex == highlight.startIndex &&
        h.endIndex == highlight.endIndex);
    if (idx != -1) {
      all[idx] = highlight;
    } else {
      all.add(highlight);
    }
    _writeAll(all);
  }

  static void removeHighlight(String id) {
    final all = _readAll();
    all.removeWhere((h) => h.id == id);
    _writeAll(all);
  }

  static void removeAllForBook(String bookId) {
    final all = _readAll();
    all.removeWhere((h) => h.bookId == bookId);
    _writeAll(all);
  }

  static List<HighlightModel> _readAll() {
    try {
      final raw = _gs.read<String>(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((j) => HighlightModel.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static void _writeAll(List<HighlightModel> highlights) {
    _gs.write(_key, jsonEncode(highlights.map((h) => h.toJson()).toList()));
  }
}
