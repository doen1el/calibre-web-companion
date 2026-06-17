import 'package:cosmos_epub/Model/book_progress_model.dart';
import 'package:get_storage/get_storage.dart';

class BookProgressSingleton {
  static const String containerName = 'cosmos_epub_progress';

  final GetStorage _box;

  BookProgressSingleton({GetStorage? box})
      : _box = box ?? GetStorage(containerName);

  String _key(String bookId) => 'progress_$bookId';

  BookProgressModel getBookProgress(String bookId) {
    try {
      final raw = _box.read(_key(bookId));
      if (raw is Map) {
        return BookProgressModel(
          bookId: bookId,
          currentChapterIndex: (raw['chapter'] as num?)?.toInt() ?? 0,
          currentPageIndex: (raw['page'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (_) {}
    return BookProgressModel(
      bookId: bookId,
      currentChapterIndex: 0,
      currentPageIndex: 0,
    );
  }

  Future<bool> setCurrentChapterIndex(String bookId, int chapterIndex) {
    final current = getBookProgress(bookId);
    return _write(bookId, chapterIndex, current.currentPageIndex ?? 0);
  }

  Future<bool> setCurrentPageIndex(String bookId, int pageIndex) {
    final current = getBookProgress(bookId);
    return _write(bookId, current.currentChapterIndex ?? 0, pageIndex);
  }

  Future<bool> _write(String bookId, int chapter, int page) async {
    try {
      await _box.write(_key(bookId), {'chapter': chapter, 'page': page});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBookProgress(String bookId) async {
    try {
      await _box.remove(_key(bookId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAllBooksProgress() async {
    try {
      await _box.erase();
      return true;
    } catch (_) {
      return false;
    }
  }
}
