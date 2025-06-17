import 'package:logger/logger.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/book_details/data/models/tag_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_model.dart';

class TagService {
  final ApiService apiService;
  final Logger logger;

  // Cache für Tag-Namen zu IDs
  final Map<String, int> _tagNameToIdMap = {};
  bool _isInitialized = false;

  TagService({required this.apiService, required this.logger});

  /// Lädt alle verfügbaren Tags mit ihren IDs
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      logger.i('Lade alle Tag-Kategorien');

      // Alle Kategorieseiten durchlaufen
      String? nextPageUrl = '/opds/category/letter/00';

      while (nextPageUrl != null) {
        final jsonData = await apiService.getXmlAsJson(
          endpoint: nextPageUrl,
          authMethod: AuthMethod.basic,
        );

        // Extrahiere Einträge
        final dynamic entryData = jsonData['feed']["entry"];
        final List<dynamic> items = entryData is List ? entryData : [entryData];

        // Verarbeite jeden Eintrag
        for (var item in items) {
          final categoryModel = CategoryModel.fromJson(item);

          // Extrahiere ID aus dem Link (z.B. "/opds/category/19" -> "19")
          final String idStr = categoryModel.id.split('/').last;
          final int? id = int.tryParse(idStr);

          if (id != null) {
            _tagNameToIdMap[categoryModel.title] = id;
            logger.d('Tag geladen: ${categoryModel.title} (ID: $id)');
          }
        }

        // Prüfe, ob es eine weitere Seite gibt
        nextPageUrl =
            jsonData['feed']?['link']?.firstWhere(
              (link) => link['@rel'] == 'next',
              orElse: () => null,
            )?['@href'];
      }

      logger.i('${_tagNameToIdMap.length} Tags geladen');
      _isInitialized = true;
    } catch (e) {
      logger.e('Fehler beim Laden der Tags: $e');
      // Fehler nicht weiterleiten, um die App nicht zu blockieren
    }
  }

  /// Konvertiert eine Liste von Tag-Namen in TagModel-Objekte mit IDs
  List<TagModel> convertTagsToModels(List<String> tagNames) {
    return tagNames.map((name) {
      // ID aus dem Cache holen oder 0 als Fallback
      final id = _tagNameToIdMap[name] ?? 0;
      return TagModel(id: id, name: name);
    }).toList();
  }

  /// Gibt die ID für einen Tag-Namen zurück
  int? getTagId(String tagName) {
    return _tagNameToIdMap[tagName];
  }

  /// Prüft ob der Service initialisiert wurde
  bool get isInitialized => _isInitialized;
}
