class BookSearchResult {
  final String id;
  final String key;
  final String line1; // Titel
  final String line2; // Autor(en)
  final String? coverUrl;
  final double? score;
  final String type;

  BookSearchResult({
    required this.id,
    required this.key,
    required this.line1,
    required this.line2,
    this.coverUrl,
    this.score,
    required this.type,
  });

  factory BookSearchResult.fromOpenLibrary(Map<String, dynamic> json) {
    String key = json['key'] ?? '';
    String id = json['key']?.replaceAll('/works/', '') ?? '';

    // Cover-URL bestimmen
    String? coverUrl;
    if (json['cover_i'] != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/${json['cover_i']}-M.jpg';
    } else if (json['cover_edition_key'] != null) {
      coverUrl =
          'https://covers.openlibrary.org/b/olid/${json['cover_edition_key']}-M.jpg';
    }

    // Autoren bestimmen
    String authors = 'Unknown Author';
    if (json['author_name'] != null &&
        json['author_name'] is List &&
        json['author_name'].isNotEmpty) {
      authors = (json['author_name'] as List).join(', ');
    }

    // Relevanz-Score berechnen (falls nicht vorhanden)
    double? score = json['_score']?.toDouble();

    return BookSearchResult(
      id: id,
      key: key,
      line1: json['title'] ?? 'Unknown Title',
      line2: authors,
      coverUrl: coverUrl,
      score: score,
      type: 'book',
    );
  }
}

class BookRecommendation {
  int id;
  final String title;
  final List<String> author;
  final String? shortTitle;
  final String coverUrl;
  final List<String> about;
  final List<String> reactions;
  final String? teaser;
  final int sourceBookId;
  final String sourceBookTitle;
  final int matchCount;

  BookRecommendation({
    this.id = 0,
    required this.title,
    required this.author,
    this.shortTitle,
    this.coverUrl = '',
    this.about = const [],
    this.reactions = const [],
    this.teaser = '',
    this.sourceBookId = 0,
    this.sourceBookTitle = '',
    this.matchCount = 0,
  });

  factory BookRecommendation.fromJson(
    Map<String, dynamic> json, {
    required int sourceBookId,
    required String sourceBookTitle,
  }) {
    List<String> authorList = [];
    if (json['author'] is List) {
      authorList = List<String>.from(json['author']);
    } else if (json['author'] is String) {
      authorList = [json['author']];
    }

    return BookRecommendation(
      id: json['id'],
      title: json['title'],
      author: authorList,
      shortTitle: json['shortTitle'],
      coverUrl:
          'https://assets.meetnewbooks.com/covers/medium${json['cover']}.webp',
      about: List<String>.from(json['about'] ?? []),
      reactions:
          json['reactions'] != null ? List<String>.from(json['reactions']) : [],
      teaser: json['teaser'],
      sourceBookId: sourceBookId,
      sourceBookTitle: sourceBookTitle,
    );
  }
}
