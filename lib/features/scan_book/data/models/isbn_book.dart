import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_utils.dart';
import 'package:equatable/equatable.dart';

class IsbnBook extends Equatable {
  final String isbn;
  final String title;
  final List<String> authors;
  final String publisher;
  final String publishDate;
  final String? coverUrl;
  final int? pageCount;
  final List<String> subjects;
  final String description;
  final String language;
  final List<IsbnMetadataSource> sources;
  final bool approximate;

  const IsbnBook({
    required this.isbn,
    required this.title,
    this.authors = const [],
    this.publisher = '',
    this.publishDate = '',
    this.coverUrl,
    this.pageCount,
    this.subjects = const [],
    this.description = '',
    this.language = '',
    this.sources = const [],
    this.approximate = false,
  });

  String get authorsLabel => authors.join(', ');

  bool get hasUsableData => title.isNotEmpty || authors.isNotEmpty;

  String get languageCode {
    final reported = normalizeLanguageCode(language);
    if (reported.isNotEmpty) return reported;

    final digits = isbn.replaceAll(RegExp(r'[^0-9]'), '');
    String body;
    if (digits.length == 13 &&
        (digits.startsWith('978') || digits.startsWith('979'))) {
      body = digits.substring(3);
    } else if (digits.length == 10) {
      body = digits;
    } else {
      return 'und';
    }

    const groups = {
      '0': 'en',
      '1': 'en',
      '2': 'fr',
      '3': 'de',
      '4': 'ja',
      '5': 'ru',
      '7': 'zh',
      '80': 'cs',
      '82': 'no',
      '83': 'pl',
      '84': 'es',
      '85': 'pt',
      '86': 'sr',
      '87': 'da',
      '88': 'it',
      '89': 'ko',
      '90': 'nl',
      '91': 'sv',
      '94': 'nl',
      '950': 'es',
      '951': 'fi',
      '952': 'fi',
      '953': 'hr',
      '954': 'bg',
      '955': 'si',
      '957': 'zh',
      '959': 'es',
      '960': 'el',
      '961': 'sl',
      '963': 'hu',
      '964': 'fa',
      '966': 'uk',
      '967': 'ms',
      '968': 'es',
      '970': 'es',
      '972': 'pt',
      '973': 'ro',
      '974': 'th',
      '975': 'tr',
      '977': 'ar',
      '979': 'id',
      '980': 'es',
      '983': 'ms',
      '984': 'bn',
      '985': 'be',
      '986': 'zh',
      '987': 'es',
      '988': 'zh',
      '989': 'pt',
    };
    for (final length in [3, 2, 1]) {
      if (body.length < length) continue;
      final prefix = body.substring(0, length);
      if (groups.containsKey(prefix)) return groups[prefix]!;
    }
    return 'und';
  }

  IsbnBook copyWith({
    String? title,
    List<String>? authors,
    String? publisher,
    String? publishDate,
    String? coverUrl,
    int? pageCount,
    List<String>? subjects,
    String? description,
    String? language,
    List<IsbnMetadataSource>? sources,
    bool? approximate,
  }) {
    return IsbnBook(
      isbn: isbn,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      publisher: publisher ?? this.publisher,
      publishDate: publishDate ?? this.publishDate,
      coverUrl: coverUrl ?? this.coverUrl,
      pageCount: pageCount ?? this.pageCount,
      subjects: subjects ?? this.subjects,
      description: description ?? this.description,
      language: language ?? this.language,
      sources: sources ?? this.sources,
      approximate: approximate ?? this.approximate,
    );
  }

  IsbnBook mergeWith(IsbnBook other) {
    final mergedSubjects = <String>[
      ...subjects,
      ...other.subjects.where(
        (s) => !subjects.any((e) => e.toLowerCase() == s.toLowerCase()),
      ),
    ];

    return IsbnBook(
      isbn: isbn,
      title: title.isNotEmpty ? title : other.title,
      authors: authors.isNotEmpty ? authors : other.authors,
      publisher: publisher.isNotEmpty ? publisher : other.publisher,
      publishDate: publishDate.isNotEmpty ? publishDate : other.publishDate,
      coverUrl:
          (coverUrl != null && coverUrl!.isNotEmpty)
              ? coverUrl
              : other.coverUrl,
      pageCount: pageCount ?? other.pageCount,
      subjects: mergedSubjects.take(15).toList(),
      description:
          other.description.length > description.length
              ? other.description
              : description,
      language: language.isNotEmpty ? language : other.language,
      sources: [
        ...sources,
        ...other.sources.where((s) => !sources.contains(s)),
      ],
      approximate: approximate && other.approximate,
    );
  }

  factory IsbnBook.fromOpenLibrary(String isbn, Map<String, dynamic> json) {
    List<String> names(dynamic list) {
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => (e['name'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    String? cover;
    final coverMap = json['cover'];
    if (coverMap is Map) {
      cover =
          (coverMap['large'] ?? coverMap['medium'] ?? coverMap['small'])
              ?.toString();
    }

    String description = '';
    String extractText(dynamic v) {
      if (v is String) return v;
      if (v is Map) return (v['value'] ?? v['text'] ?? '').toString();
      return '';
    }

    description = extractText(json['description']);
    if (description.isEmpty) {
      description = extractText(json['notes']);
    }
    if (description.isEmpty && json['excerpts'] is List) {
      final excerpts = json['excerpts'] as List;
      if (excerpts.isNotEmpty) {
        description = extractText(excerpts.first);
      }
    }

    return IsbnBook(
      isbn: isbn,
      title: (json['title'] ?? '').toString(),
      authors: names(json['authors']),
      publisher: names(json['publishers']).join(', '),
      publishDate: (json['publish_date'] ?? '').toString(),
      coverUrl: cover,
      pageCount:
          json['number_of_pages'] is int
              ? json['number_of_pages'] as int
              : null,
      subjects: names(json['subjects']),
      description: description.trim(),
      sources: const [IsbnMetadataSource.openLibrary],
    );
  }

  @override
  List<Object?> get props => [
    isbn,
    title,
    authors,
    publisher,
    publishDate,
    coverUrl,
    pageCount,
    subjects,
    description,
    language,
    sources,
    approximate,
  ];
}
