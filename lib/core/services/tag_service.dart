import 'package:logger/logger.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/book_details/data/models/tag_model.dart';

class TagService {
  final ApiService _apiService;
  final Logger logger;

  Map<String, int> _tagNameToIdMap = {};
  bool _isInitialized = false;

  TagService({required ApiService apiService, required this.logger})
    : _apiService = apiService;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _tagNameToIdMap = await fetchCategoryMappings();
    _isInitialized = true;
  }

  Future<Map<String, int>> fetchCategoryMappings() async {
    logger.i('Fetching category mappings');
    final categoriesMap = <String, int>{};

    try {
      final response = await _apiService.get(
        endpoint: '/category',
        authMethod: AuthMethod.cookie,
      );

      if (response.statusCode == 200) {
        final html = response.body;

        final RegExp categoryRegex = RegExp(
          r'''<a\s+id="list_\d+"\s+href="/category/stored/(\d+)">\s*(\w[^<]+)''',
          caseSensitive: false,
          multiLine: true,
          dotAll: true,
        );

        final matches = categoryRegex.allMatches(html);
        for (var match in matches) {
          if (match.groupCount >= 2) {
            final categoryId = int.tryParse(match.group(1)!) ?? 0;
            final categoryName = match.group(2)!.trim();

            if (categoryId > 0 && categoryName.isNotEmpty) {
              categoriesMap[categoryName] = categoryId;
            }
          }
        }

        logger.i('Found ${categoriesMap.length} categories with IDs');
      } else {
        logger.w('Failed to fetch category page: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error fetching category mappings: $e');
    }

    return categoriesMap;
  }

  List<TagModel> convertTagsToModels(List<String> tagNames) {
    return tagNames.map((name) {
      final id = _tagNameToIdMap[name] ?? 0;
      return TagModel(id: id, name: name);
    }).toList();
  }

  int? getTagId(String tagName) {
    return _tagNameToIdMap[tagName];
  }

  void addTagMapping(String tagName, int tagId) {
    _tagNameToIdMap[tagName] = tagId;
  }

  void removeTagMapping(String tagName) {
    _tagNameToIdMap.remove(tagName);
  }

  Map<String, int> get allTags => Map.unmodifiable(_tagNameToIdMap);
}
