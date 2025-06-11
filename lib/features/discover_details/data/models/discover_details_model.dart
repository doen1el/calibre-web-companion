import 'package:equatable/equatable.dart';

class DiscoverDetailsModel extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;

  const DiscoverDetailsModel({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
  });

  factory DiscoverDetailsModel.fromJson(Map<String, dynamic> json) {
    return DiscoverDetailsModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author']["name"] ?? '',
      coverUrl: '',
    );
  }

  @override
  List<Object?> get props => [id, title, author, coverUrl];
}
