part of 'package:vocsy_epub_viewer/epub_viewer.dart';

/// Model for android EpubLocator
class EpubLocator {
  String? bookId;
  String? href;
  int? created;
  Locations? locations;

  EpubLocator({this.bookId, this.href, this.created, this.locations});

  EpubLocator.fromJson(Map<String, dynamic> json) {
    bookId = json['bookId'];
    href = json['href'];
    created = json['created'];
    locations = json['locations'] != null
        ? Locations.fromJson(json['locations'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['bookId'] = bookId;
    data['href'] = href;
    data['created'] = created;
    if (locations != null) {
      data['locations'] = locations!.toJson();
    }
    return data;
  }
}

/// Model for Locations in [EpubLocator]
class Locations {
  String? cfi;

  Locations({this.cfi});

  Locations.fromJson(Map<String, dynamic> json) {
    cfi = json['cfi'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cfi'] = cfi;
    return data;
  }
}
