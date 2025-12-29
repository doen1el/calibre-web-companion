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
