class EpubBookmark {
  final String id;
  final int chapterIndex;

  /// Share of the chapter, 0-1; pages depend on screen and font size.
  final double chapterFraction;

  /// Share of the whole book, 0-100.
  final double percentage;
  final String excerpt;

  const EpubBookmark({
    required this.id,
    required this.chapterIndex,
    required this.chapterFraction,
    required this.percentage,
    required this.excerpt,
  });
}

/// Where the reader keeps bookmarks. The host app owns storage and sync.
abstract class EpubBookmarkSource {
  /// Bookmarks after any remote merge; may be slow.
  Future<List<EpubBookmark>> load();

  Future<List<EpubBookmark>> add({
    required int chapterIndex,
    required double chapterFraction,
    required double percentage,
    required String excerpt,
  });

  Future<List<EpubBookmark>> remove(String id);
}

class EpubBookmarkLabels {
  final String contents;
  final String bookmarks;
  final String noBookmarks;
  final String addBookmark;
  final String removeBookmark;
  final String bookmarkAdded;
  final String bookmarkRemoved;

  const EpubBookmarkLabels({
    this.contents = 'Contents',
    this.bookmarks = 'Bookmarks',
    this.noBookmarks = 'No bookmarks yet',
    this.addBookmark = 'Add bookmark',
    this.removeBookmark = 'Remove bookmark',
    this.bookmarkAdded = 'Bookmark added',
    this.bookmarkRemoved = 'Bookmark removed',
  });
}
