class BookSearchResult {
  final String? line1;
  final String? line2;
  final String? line3;
  final int? bookId;
  final String? idWithTitleSuffix;
  final String? type;
  final String? phrase;
  final String? shortTitle;
  final String? author;
  final int? occurrences;
  final double? score;

  BookSearchResult({
    this.line1,
    this.line2,
    this.line3,
    this.bookId,
    this.idWithTitleSuffix,
    this.type,
    this.phrase,
    this.shortTitle,
    this.author,
    this.occurrences,
    this.score,
  });

  factory BookSearchResult.fromJson(Map<String, dynamic> json) {
    return BookSearchResult(
      line1: json['line1'],
      line2: json['line2'],
      line3: json['line3'],
      bookId: json['bookId'],
      idWithTitleSuffix: json['idWithTitleSuffix'],
      type: json['type'],
      phrase: json['phrase'],
      shortTitle: json['shortTitle'],
      author: json['author'],
      occurrences: json['occurrences'],
      score: json['score']?.toDouble(),
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
