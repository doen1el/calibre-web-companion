import 'dart:convert';

import 'package:logger/logger.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';

enum VocabularyType { authors, series, tags, publishers }

class VocabularyRemoteDataSource {
  final ApiService apiService;
  final Logger logger;

  VocabularyRemoteDataSource({required this.apiService, Logger? logger})
    : logger = logger ?? Logger();

  String _endpoint(VocabularyType type) {
    switch (type) {
      case VocabularyType.authors:
        return '/get_authors_json';
      case VocabularyType.series:
        return '/get_series_json';
      case VocabularyType.tags:
        return '/get_tags_json';
      case VocabularyType.publishers:
        return '/get_publishers_json';
    }
  }

  Future<List<String>> suggest(VocabularyType type, String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final response = await apiService.get(
        endpoint: _endpoint(type),
        authMethod: AuthMethod.cookie,
        queryParams: {'q': query},
      );

      if (response.statusCode != 200) {
        logger.w('Vocabulary ${type.name} lookup -> ${response.statusCode}');
        return const [];
      }

      final body = response.body.trimLeft();
      if (body.startsWith('<')) {
        logger.w(
          'Vocabulary ${type.name} lookup returned HTML (not logged in?)',
        );
        return const [];
      }

      final decoded = json.decode(body);
      if (decoded is! List) return const [];

      final results =
          decoded
              .map((e) {
                if (e is String) return e;
                if (e is Map) {
                  return (e['name'] ?? e['text'] ?? e['title'] ?? '')
                      .toString();
                }
                return '';
              })
              .where((s) => s.isNotEmpty)
              .toList();

      final seen = <String>{};
      return results.where((s) => seen.add(s)).toList();
    } catch (e) {
      logger.w('Vocabulary ${type.name} lookup error: $e');
      return const [];
    }
  }
}
