/// Base model class for OPDS items
abstract class OpdsItem {
  final String id;
  final String title;

  OpdsItem({required this.id, required this.title});
}

/// Represents a book in OPDS
class BookItem extends OpdsItem {
  final String uuid;
  final String author;
  final String? publisher;
  final DateTime? updated;
  final DateTime? published;
  final String? language;
  final List<String> categories;
  final Map<String, int> categoriesMap;
  final String? summary;
  final int? fileSize;
  final String? series;
  final double? seriesIndex;
  final List<String> formats;
  final Map<String, String> main_format;
  final Map<String, String> downloadLinks;
  final double? rating;
  final String? coverUrl;
  final String? thumbnailUrl;
  final Map<String, int>? formatSizes;
  final String authorSort;
  final int seriesId;

  BookItem({
    required super.id,
    required super.title,
    required this.author,
    required this.uuid,
    this.publisher,
    this.updated,
    this.published,
    this.language,
    required this.categories,
    this.categoriesMap = const {},
    this.summary,
    this.fileSize,
    this.series,
    this.seriesIndex,
    this.formats = const [],
    this.main_format = const {},
    this.downloadLinks = const {},
    this.rating,
    this.coverUrl,
    this.thumbnailUrl,
    this.formatSizes,
    this.authorSort = '',
    this.seriesId = 0,
  });

  /// Create a BookItem from an OPDS entry
  factory BookItem.fromOpdsEntry(Map<String, dynamic> entry) {
    String entryString = entry.toString();

    // Extract ID
    String bookId = '';

    RegExp coverRegex = RegExp(r'/opds/cover/(\d+)');
    var coverMatches = coverRegex.allMatches(entryString);
    if (coverMatches.isNotEmpty) {
      bookId = coverMatches.first.group(1)!;
    } else {
      // Suche nach Download-Link-Muster
      RegExp downloadRegex = RegExp(r'/opds/download/(\d+)/');
      var downloadMatches = downloadRegex.allMatches(entryString);
      if (downloadMatches.isNotEmpty) {
        bookId = downloadMatches.first.group(1)!;
      }
    }

    // Extrahiere UUID (aus ID-Feld)
    final String rawId = entry['id'] ?? '';
    final String uuid = rawId.replaceAll('urn:uuid:', '');

    // Fallback für ID, wenn keine numerische ID gefunden wurde
    if (bookId.isEmpty) {
      bookId = uuid; // Verwende UUID als Fallback
    }

    // Extract author - can be a single author or a list of authors
    String author = '';
    if (entry['author'] != null) {
      if (entry['author'] is Map && entry['author']['name'] != null) {
        author = entry['author']['name'];
      } else if (entry['author'] is List) {
        author = (entry['author'] as List).map((a) => a['name']).join(', ');
      }
    }

    // Extract categories
    List<String> categories = [];
    if (entry['category'] != null) {
      if (entry['category'] is List) {
        categories =
            (entry['category'] as List)
                .map((c) => c['@label'])
                .cast<String>()
                .toList();
      } else if (entry['category'] is Map) {
        categories = [entry['category']['@label']];
      }
    }

    // Extract cover and download URLs
    int? fileSize;

    return BookItem(
      id: bookId,
      title: entry['title'] ?? 'Unknown Title',
      uuid: uuid,
      author: author,
      publisher: entry['publisher']?['name'],
      updated: DateTime.parse(
        entry['updated'] ?? DateTime.now().toIso8601String(),
      ),
      published:
          entry['published'] != null
              ? DateTime.parse(entry['published'])
              : null,
      language: entry['dcterms:language'],
      categories: categories,
      summary: entry['summary'],
      fileSize: fileSize,
    );
  }

  @override
  String toString() {
    return 'BookItem{id: $id, uuid: $uuid, title: $title, author: $author}';
  }
}

/// Represents a category in OPDS
class CategoryItem extends OpdsItem {
  final String navigationUrl;

  CategoryItem({
    required super.id,
    required super.title,
    required this.navigationUrl,
  });

  factory CategoryItem.fromOpdsEntry(Map<String, dynamic> entry) {
    String navigationUrl = '';

    // Exract navigation URL
    dynamic linkData = entry['link'];
    if (linkData != null) {
      if (linkData is List) {
        for (var link in linkData) {
          if (link is Map &&
              (link['@rel'] == 'subsection' || navigationUrl.isEmpty)) {
            navigationUrl = link['@href'] ?? '';
            if (link['@rel'] == 'subsection') {
              break;
            }
          }
        }
      } else if (linkData is Map) {
        navigationUrl = linkData['@href'] ?? '';
      }
    }

    // Wenn kein Link gefunden wurde, die ID als Navigation-URL verwenden
    if (navigationUrl.isEmpty && entry['id'] != null) {
      String id = entry['id'].toString();
      // Prüfen ob die ID ein OPDS-Pfad ist
      if (id.startsWith('/opds/')) {
        navigationUrl = id;
      }
    }

    return CategoryItem(
      id: entry['id'] ?? '',
      title: entry['title'] ?? 'Unknown',
      navigationUrl: navigationUrl,
    );
  }
}

/// Represents an OPDS feed
class OpdsFeed<T extends OpdsItem> {
  final String title;
  final String id;
  final List<T> items;

  OpdsFeed({required this.title, required this.id, required this.items});

  /// Create an OPDS feed from a JSON response
  static OpdsFeed<BookItem> booksFromOpdsJson(Map<String, dynamic> json) {
    final feed = json['feed'];

    List<BookItem> books = [];
    if (feed['entry'] != null) {
      if (feed['entry'] is List) {
        books =
            (feed['entry'] as List)
                .map((entry) => BookItem.fromOpdsEntry(entry))
                .toList();
      } else {
        books = [BookItem.fromOpdsEntry(feed['entry'])];
      }
    }

    return OpdsFeed<BookItem>(
      items: books,
      title: feed['title'] ?? 'Reading List',
      id: feed['id'] ?? '',
    );
  }
}
