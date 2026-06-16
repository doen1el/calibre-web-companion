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
  });

  String get authorsLabel => authors.join(', ');

  String get languageCode {
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
    };
    if (body.isNotEmpty && groups.containsKey(body[0])) {
      return groups[body[0]]!;
    }
    return 'und';
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
  ];
}
