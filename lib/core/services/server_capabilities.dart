class ServerCapabilities {
  final bool pagination;
  final bool search;
  final bool sort;
  final bool addBooks;
  final bool editMetadata;
  final bool metadataLookup;
  final bool deleteBooks;
  final bool shelves;
  final bool readingProgress;
  final bool userStats;
  final bool discover;
  final bool multiLibrary;

  const ServerCapabilities({
    required this.pagination,
    required this.search,
    required this.sort,
    required this.addBooks,
    required this.editMetadata,
    required this.metadataLookup,
    required this.deleteBooks,
    required this.shelves,
    required this.readingProgress,
    required this.userStats,
    required this.discover,
    required this.multiLibrary,
  });

  static const ServerCapabilities calibreWeb = ServerCapabilities(
    pagination: true,
    search: true,
    sort: true,
    addBooks: true,
    editMetadata: true,
    metadataLookup: true,
    deleteBooks: true,
    shelves: true,
    readingProgress: true,
    userStats: true,
    discover: true,
    multiLibrary: false,
  );

  static const ServerCapabilities calibre = ServerCapabilities(
    pagination: true,
    search: true,
    sort: true,
    addBooks: true,
    editMetadata: true,
    metadataLookup: false,
    deleteBooks: true,
    shelves: false,
    readingProgress: false,
    userStats: false,
    discover: false,
    multiLibrary: true,
  );

  static const ServerCapabilities opds = ServerCapabilities(
    pagination: false,
    search: false,
    sort: false,
    addBooks: false,
    editMetadata: false,
    metadataLookup: false,
    deleteBooks: false,
    shelves: false,
    readingProgress: false,
    userStats: false,
    discover: false,
    multiLibrary: false,
  );

  factory ServerCapabilities.fromServerType(String? serverType) {
    switch (serverType) {
      case 'calibre':
        return calibre;
      case 'opds':
      case 'grimmory':
      case 'booklore':
        return opds;
      default:
        return calibreWeb;
    }
  }
}
