class StatsModel {
  final int books;
  final int authors;
  final int categories;
  final int series;

  StatsModel({
    this.books = 0,
    this.authors = 0,
    this.categories = 0,
    this.series = 0,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      books: json['books'] ?? 0,
      authors: json['authors'] ?? 0,
      categories: json['categories'] ?? 0,
      series: json['series'] ?? 0,
    );
  }
}
