import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/opds_browser/data/models/opds_feed.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpdsBrowserDatasource {
  final ApiService apiService;
  final SharedPreferences preferences;

  OpdsBrowserDatasource({required this.apiService, required this.preferences});

  String get rootUrl => preferences.getString('base_url') ?? '';

  Future<OpdsFeed> fetchFeed(String url) async {
    final json = await apiService.getXmlAsJson(
      endpoint: url,
      authMethod: AuthMethod.basic,
    );
    return OpdsFeed.fromJson(json, url);
  }

  Future<String?> buildSearchUrl(OpdsFeed feed, String query) async {
    final href = feed.searchHref;
    if (href == null) return null;

    final template =
        feed.searchIsTemplate ? href : await _templateFromDescription(href);
    if (template == null) return null;

    final filled = template
        .replaceAll('{searchTerms}', Uri.encodeComponent(query))
        // Optional OpenSearch parameters like {startPage?} are left out.
        .replaceAll(RegExp(r'\{[^}]*\?\}'), '');
    return Uri.parse(feed.url).resolve(filled).toString();
  }

  Future<String?> _templateFromDescription(String descriptionUrl) async {
    final json = await apiService.getXmlAsJson(
      endpoint: descriptionUrl,
      authMethod: AuthMethod.basic,
    );
    final description = json['OpenSearchDescription'];
    if (description is! Map) return null;

    final urls = description['Url'];
    final candidates = (urls is List ? urls : [urls]).whereType<Map>().toList();
    final atom = candidates.where(
      (u) => (u['_type']?.toString() ?? '').contains('atom+xml'),
    );
    final chosen = atom.isNotEmpty ? atom.first : candidates.firstOrNull;
    return chosen?['_template']?.toString();
  }
}
