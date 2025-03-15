class ShelfModel {
  final String title;
  final String id;

  ShelfModel({required this.title, required this.id});

  static List<ShelfModel> fromFeedJson(Map<String, dynamic> json) {
    final List<ShelfModel> shelves = [];

    try {
      final feed = json['feed'];
      if (feed == null) return [];

      final dynamic entry = feed['entry'];
      if (entry == null) return [];

      if (entry is Map<String, dynamic>) {
        String title;
        String fullId;

        if (entry['title'] is String) {
          title = entry['title'] as String;
        } else if (entry['title'] is Map && entry['title']?['_value'] != null) {
          title = entry['title']?['_value'];
        } else {
          title = 'Unkown Shelf';
        }

        if (entry['id'] is String) {
          fullId = entry['id'] as String;
        } else if (entry['id'] is Map && entry['id']?['_value'] != null) {
          fullId = entry['id']['_value'].toString();
        } else {
          fullId = '';
        }

        final String id = _extractId(fullId);
        shelves.add(ShelfModel(title: title, id: id));
      } else if (entry is List) {
        for (var shelf in entry) {
          String title;
          String fullId;

          if (shelf['title'] is String) {
            title = shelf['title'] as String;
          } else if (shelf['title'] is Map &&
              shelf['title']?['_value'] != null) {
            title = shelf['title']?['_value'];
          } else {
            title = 'Unkown Shelf';
          }

          if (shelf['id'] is String) {
            fullId = shelf['id'] as String;
          } else if (shelf['id'] is Map && shelf['id']?['_value'] != null) {
            fullId = shelf['id']['_value'].toString();
          } else {
            fullId = '';
          }

          final String id = _extractId(fullId);
          shelves.add(ShelfModel(title: title, id: id));
        }
      }

      return shelves;
    } catch (e) {
      return [];
    }
  }

  // Helper-Methode to extract the ID from a full URL
  static String _extractId(String fullId) {
    if (fullId.isEmpty) {
      return '';
    }

    try {
      final regex = RegExp(r'/(\d+)$');
      final match = regex.firstMatch(fullId);
      if (match != null && match.groupCount >= 1) {
        return match.group(1) ?? '';
      }

      final parts = fullId.split('/');
      if (parts.isEmpty) {
        return '';
      }

      final lastIndex = parts.length - 1;
      return lastIndex >= 0 ? parts[lastIndex] : '';
    } catch (e) {
      return '';
    }
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
