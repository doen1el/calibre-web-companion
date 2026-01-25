import 'package:equatable/equatable.dart';

class SyncFilter extends Equatable {
  final List<String> selectedFormats;
  final String? shelfId;
  final List<String> tags;
  final List<String> authors;
  final List<String> series;
  final List<String> languages;
  final List<String> publishers;

  final bool unreadOnly;

  const SyncFilter({
    this.selectedFormats = const ['epub'],
    this.shelfId,
    this.tags = const [],
    this.authors = const [],
    this.series = const [],
    this.languages = const [],
    this.publishers = const [],
    this.unreadOnly = false,
  });

  SyncFilter copyWith({
    List<String>? selectedFormats,
    String? shelfId,
    List<String>? tags,
    List<String>? authors,
    List<String>? series,
    List<String>? languages,
    List<String>? publishers,
    bool? unreadOnly,
  }) {
    return SyncFilter(
      selectedFormats: selectedFormats ?? this.selectedFormats,
      shelfId: shelfId ?? this.shelfId,
      tags: tags ?? this.tags,
      authors: authors ?? this.authors,
      series: series ?? this.series,
      languages: languages ?? this.languages,
      publishers: publishers ?? this.publishers,
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }

  @override
  List<Object?> get props => [
    selectedFormats,
    shelfId,
    tags,
    authors,
    series,
    languages,
    publishers,
    unreadOnly,
  ];
}
