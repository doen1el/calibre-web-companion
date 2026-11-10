import 'package:calibre_web_companion/features/reader/data/bookmark_store.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:cosmos_epub/cosmos_epub.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreEpubBookmarkSource implements EpubBookmarkSource {
  final BookmarkStore store;

  StoreEpubBookmarkSource(this.store);

  factory StoreEpubBookmarkSource.forBook(String bookUuid) =>
      StoreEpubBookmarkSource(
        BookmarkStore(
          prefs: GetIt.instance<SharedPreferences>(),
          logger: GetIt.instance<Logger>(),
          bookUuid: bookUuid,
          format: 'epub',
        ),
      );

  static List<EpubBookmark> _map(List<ReaderBookmark> bookmarks) => [
    for (final b in bookmarks)
      if (b.chapter != null)
        EpubBookmark(
          id: b.id,
          chapterIndex: b.chapter!,
          chapterFraction: b.chapterFraction ?? 0,
          percentage: b.percentage,
          excerpt: b.label,
        ),
  ];

  @override
  Future<List<EpubBookmark>> load() async => _map(await store.sync());

  @override
  Future<List<EpubBookmark>> add({
    required int chapterIndex,
    required double chapterFraction,
    required double percentage,
    required String excerpt,
  }) async => _map(
    await store.add(
      ReaderBookmark.create(
        chapter: chapterIndex,
        chapterFraction: chapterFraction,
        percentage: percentage,
        label: excerpt,
      ),
    ),
  );

  @override
  Future<List<EpubBookmark>> remove(String id) async =>
      _map(await store.remove(id));
}

EpubBookmarkLabels epubBookmarkLabels(AppLocalizations l) => EpubBookmarkLabels(
  contents: l.readerContents,
  bookmarks: l.readerBookmarks,
  noBookmarks: l.readerNoBookmarks,
  addBookmark: l.readerAddBookmark,
  removeBookmark: l.readerRemoveBookmark,
  bookmarkAdded: l.readerBookmarkAdded,
  bookmarkRemoved: l.readerBookmarkRemoved,
);
