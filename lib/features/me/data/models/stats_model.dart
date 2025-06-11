import 'package:equatable/equatable.dart';

class StatsModel extends Equatable {
  final int books;
  final int authors;
  final int categories;
  final int series;

  const StatsModel({
    this.books = 0,
    this.authors = 0,
    this.categories = 0,
    this.series = 0,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      books: json['books'],
      authors: json['authors'],
      categories: json['categories'],
      series: json['series'],
    );
  }

  @override
  List<Object?> get props => [books, authors, categories, series];
}
