import 'package:equatable/equatable.dart';

class MetadataProvider extends Equatable {
  final String id;
  final String name;
  final bool active;

  const MetadataProvider({
    required this.id,
    required this.name,
    required this.active,
  });

  factory MetadataProvider.fromJson(Map<String, dynamic> json) {
    return MetadataProvider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      active: json['active'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, active];
}

class MetadataSearchResult extends Equatable {
  final String id;
  final String title;
  final String authors;
  final String description;
  final String publisher;
  final String pubdate;
  final String series;
  final String seriesIndex;
  final double rating;
  final List<String> tags;
  final List<String> languages;
  final String coverUrl;
  final String sourceId;
  final String sourceLink;

  const MetadataSearchResult({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.publisher,
    required this.pubdate,
    required this.series,
    required this.seriesIndex,
    required this.rating,
    required this.tags,
    required this.languages,
    required this.coverUrl,
    required this.sourceId,
    required this.sourceLink,
  });

  factory MetadataSearchResult.fromJson(Map<String, dynamic> json) {
    return MetadataSearchResult(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      authors:
          (json['authors'] as List?)?.map((e) => e.toString()).join(', ') ?? '',
      description: json['description'] ?? '',
      publisher: json['publisher'] ?? '',
      pubdate: json['publishedDate'] ?? '',
      series: json['series'] ?? '',
      seriesIndex: json['series_index']?.toString() ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      languages:
          (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      coverUrl: json['cover'] ?? '',
      sourceId: json['source']?['id'] ?? '',
      sourceLink: json['source']?['link'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, title, authors, sourceId];
}

enum MetadataProviderState {
  ok,
  empty,
  disabled,
  rateLimited,
  blocked,
  missingKey,
  error,
}

class MetadataProviderStatus extends Equatable {
  final String id;
  final String name;
  final MetadataProviderState state;
  final String message;

  const MetadataProviderStatus({
    required this.id,
    required this.name,
    required this.state,
    required this.message,
  });

  bool get isProblem => switch (state) {
    MetadataProviderState.ok ||
    MetadataProviderState.empty ||
    MetadataProviderState.disabled => false,
    _ => true,
  };

  factory MetadataProviderStatus.fromJson(Map<String, dynamic> json) {
    return MetadataProviderStatus(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['id']?.toString() ?? '',
      state: switch (json['status']) {
        'ok' => MetadataProviderState.ok,
        'empty' => MetadataProviderState.empty,
        'disabled' => MetadataProviderState.disabled,
        'rate_limited' => MetadataProviderState.rateLimited,
        'blocked' => MetadataProviderState.blocked,
        'missing_key' => MetadataProviderState.missingKey,
        _ => MetadataProviderState.error,
      },
      message: json['message']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, state, message];
}

class MetadataSearchResponse extends Equatable {
  final List<MetadataSearchResult> results;

  // Only Calibre-Web-NextGen reports per-source status; empty on stock CW.
  final List<MetadataProviderStatus> providers;

  const MetadataSearchResponse({
    required this.results,
    this.providers = const [],
  });

  List<MetadataProviderStatus> get problems =>
      providers.where((p) => p.isProblem).toList();

  // Calibre-Web returns a bare list; Calibre-Web-NextGen wraps it as
  // {"results": [...], "providers": [...]} (#221).
  factory MetadataSearchResponse.fromDecoded(dynamic decoded) {
    final dynamic results = decoded is Map ? decoded['results'] : decoded;
    final dynamic providers = decoded is Map ? decoded['providers'] : null;
    return MetadataSearchResponse(
      results:
          results is List
              ? results
                  .whereType<Map<String, dynamic>>()
                  .map(MetadataSearchResult.fromJson)
                  .toList()
              : const [],
      providers:
          providers is List
              ? providers
                  .whereType<Map<String, dynamic>>()
                  .map(MetadataProviderStatus.fromJson)
                  .toList()
              : const [],
    );
  }

  @override
  List<Object?> get props => [results, providers];
}
