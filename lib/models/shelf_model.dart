class ShelfModel {
  final String title;
  final String id;
  final Link link;

  ShelfModel({required this.title, required this.id, required this.link});

  factory ShelfModel.fromJson(Map<String, dynamic> json) {
    return ShelfModel(
      title: json['title'],
      id: _extractId(json['id']),
      link: Link.fromJson(json['link']),
    );
  }

  static List<ShelfModel> fromFeedJson(Map<String, dynamic> json) {
    final entries = json['feed']['entry'] as List<dynamic>;
    return entries.map((entry) => ShelfModel.fromJson(entry)).toList();
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'id': id, 'link': link.toJson()};
  }

  static String _extractId(String fullId) {
    final regex = RegExp(r'/opds/shelf/(\d+)');
    final match = regex.firstMatch(fullId);
    if (match != null) {
      return match.group(1) ?? fullId;
    }
    return fullId;
  }
}

class Link {
  final String rel;
  final String type;
  final String href;
  final String value;

  Link({
    required this.rel,
    required this.type,
    required this.href,
    required this.value,
  });

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      rel: json['_rel'],
      type: json['_type'],
      href: json['_href'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'_rel': rel, '_type': type, '_href': href, 'value': value};
  }
}

class ShelfDetailModel {
  final String name;
  final List<ShelfBookItem> books;

  ShelfDetailModel({required this.name, required this.books});
}

class ShelfBookItem {
  final String id;
  final String title;
  final List<BookAuthor> authors;
  final String? seriesName;
  final String? seriesId;
  final String? seriesIndex;
  final String? downloadUrl;

  ShelfBookItem({
    required this.id,
    required this.title,
    required this.authors,
    this.seriesName,
    this.seriesId,
    this.seriesIndex,
    this.downloadUrl,
  });
}

class BookAuthor {
  final String name;
  final String id;

  BookAuthor({required this.name, required this.id});
}
