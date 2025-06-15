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

  factory DiscoverDetailsModel.fromJson(
    Map<String, dynamic> json,
    String baseUrl,
  ) {
    return DiscoverDetailsModel(
      id: (json['id'] ?? '').toString().replaceFirst('urn:uuid:', ''),
      title: json['title'] ?? '',
      author:
          json['author'] is List
              ? (json['author'] as List)
                  .where((a) => a is Map && a['name'] != null)
                  .map((a) => a['name'].toString())
                  .join(', ')
              : (json['author'] is Map && json['author']['name'] != null)
              ? json['author']['name'].toString()
              : '',
      coverUrl:
          (json['link'] as List?)
                      ?.cast<Map<String, dynamic>>()
                      .where(
                        (link) => link['_rel'] == 'http://opds-spec.org/image',
                      )
                      .firstOrNull?['_href'] !=
                  null
              ? '$baseUrl${(json['link'] as List?)?.cast<Map<String, dynamic>>().where((link) => link['_rel'] == 'http://opds-spec.org/image').firstOrNull?['_href']}'
              : null,
    );
  }

  @override
  List<Object?> get props => [id, title, author, coverUrl];
}
