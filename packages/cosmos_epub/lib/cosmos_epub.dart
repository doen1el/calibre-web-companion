library cosmos_epub;

import 'dart:io';

import 'package:cosmos_epub/Component/constants.dart';
import 'package:cosmos_epub/Helpers/progress_singleton.dart';
import 'package:cosmos_epub/Model/book_progress_model.dart';
import 'package:cosmos_epub/Model/highlight_model.dart';
import 'package:cosmos_epub/show_epub.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

/// Main entry point for the CosmosEpub reader.
///
/// Call [initialize] once before using any other methods.
/// Then use [openAssetBook], [openLocalBook], [openFileBook], or [openURLBook]
/// to open an EPUB file in the reader.
class CosmosEpub {
  static bool _initialized = false;

  // ──── Initialization ────

  /// Initialize the reader. Must be called once before opening any book.
  static Future<bool> initialize() async {
    await GetStorage.init();
    await GetStorage.init(BookProgressSingleton.containerName);
    bookProgress = BookProgressSingleton();
    _initialized = true;
    return true;
  }

  // ──── Open Book ────

  /// Open an EPUB from a local file path.
  static Future<void> openLocalBook({
    required String localPath,
    required BuildContext context,
    required String bookId,
    Color accentColor = Colors.indigoAccent,
    Function(int currentPage, int totalPages)? onPageFlip,
    Function(int lastPageIndex)? onLastPage,
    String chapterListTitle = 'Table of Contents',
    bool shouldOpenDrawer = false,
    int starterChapter = -1,
  }) async {
    var bytes = File(localPath).readAsBytesSync();
    EpubBook epubBook = await EpubReader.readBook(bytes.buffer.asUint8List());
    if (!context.mounted) return;
    _openBook(
      context: context,
      epubBook: epubBook,
      bookId: bookId,
      shouldOpenDrawer: shouldOpenDrawer,
      starterChapter: starterChapter,
      chapterListTitle: chapterListTitle,
      onPageFlip: onPageFlip,
      onLastPage: onLastPage,
      accentColor: accentColor,
    );
  }

  /// Open an EPUB from raw bytes (Uint8List).
  static Future<void> openFileBook({
    required Uint8List bytes,
    required BuildContext context,
    required String bookId,
    Color accentColor = Colors.indigoAccent,
    Function(int currentPage, int totalPages)? onPageFlip,
    Function(int lastPageIndex)? onLastPage,
    String chapterListTitle = 'Table of Contents',
    bool shouldOpenDrawer = false,
    int starterChapter = -1,
  }) async {
    EpubBook epubBook = await EpubReader.readBook(bytes.buffer.asUint8List());
    if (!context.mounted) return;
    _openBook(
      context: context,
      epubBook: epubBook,
      bookId: bookId,
      shouldOpenDrawer: shouldOpenDrawer,
      starterChapter: starterChapter,
      chapterListTitle: chapterListTitle,
      onPageFlip: onPageFlip,
      onLastPage: onLastPage,
      accentColor: accentColor,
    );
  }

  /// Open an EPUB from a URL.
  static Future<void> openURLBook({
    required String urlPath,
    required BuildContext context,
    required String bookId,
    Color accentColor = Colors.indigoAccent,
    Function(int currentPage, int totalPages)? onPageFlip,
    Function(int lastPageIndex)? onLastPage,
    String chapterListTitle = 'Table of Contents',
    bool shouldOpenDrawer = false,
    int starterChapter = -1,
  }) async {
    final result = await http.get(Uri.parse(urlPath));
    final bytes = result.bodyBytes;
    EpubBook epubBook = await EpubReader.readBook(bytes.buffer.asUint8List());
    if (!context.mounted) return;
    _openBook(
      context: context,
      epubBook: epubBook,
      bookId: bookId,
      shouldOpenDrawer: shouldOpenDrawer,
      starterChapter: starterChapter,
      chapterListTitle: chapterListTitle,
      onPageFlip: onPageFlip,
      onLastPage: onLastPage,
      accentColor: accentColor,
    );
  }

  /// Open an EPUB from Flutter assets.
  static Future<void> openAssetBook({
    required String assetPath,
    required BuildContext context,
    required String bookId,
    Color accentColor = Colors.indigoAccent,
    Function(int currentPage, int totalPages)? onPageFlip,
    Function(int lastPageIndex)? onLastPage,
    String chapterListTitle = 'Table of Contents',
    bool shouldOpenDrawer = false,
    int starterChapter = -1,
  }) async {
    var bytes = await rootBundle.load(assetPath);
    EpubBook epubBook = await EpubReader.readBook(bytes.buffer.asUint8List());
    if (!context.mounted) return;
    _openBook(
      context: context,
      epubBook: epubBook,
      bookId: bookId,
      shouldOpenDrawer: shouldOpenDrawer,
      starterChapter: starterChapter,
      chapterListTitle: chapterListTitle,
      onPageFlip: onPageFlip,
      onLastPage: onLastPage,
      accentColor: accentColor,
    );
  }

  // ──── Progress Management ────

  /// Get the reading progress for a book.
  static BookProgressModel getBookProgress(String bookId) {
    return bookProgress.getBookProgress(bookId);
  }

  /// Set the current page index for a book.
  static Future<bool> setCurrentPageIndex(String bookId, int index) async {
    return await bookProgress.setCurrentPageIndex(bookId, index);
  }

  /// Set the current chapter index for a book.
  static Future<bool> setCurrentChapterIndex(String bookId, int index) async {
    return await bookProgress.setCurrentChapterIndex(bookId, index);
  }

  /// Delete reading progress for a specific book.
  static Future<bool> deleteBookProgress(String bookId) async {
    return await bookProgress.deleteBookProgress(bookId);
  }

  /// Delete reading progress for all books.
  static Future<bool> deleteAllBooksProgress() async {
    return await bookProgress.deleteAllBooksProgress();
  }

  // ──── Highlight Management ────

  /// Get all highlights for a book.
  static List<HighlightModel> getBookHighlights(String bookId) {
    return HighlightStorage.getBookHighlights(bookId);
  }

  /// Remove a specific highlight by ID.
  static void removeHighlight(String highlightId) {
    HighlightStorage.removeHighlight(highlightId);
  }

  /// Remove all highlights for a book.
  static void removeAllHighlights(String bookId) {
    HighlightStorage.removeAllForBook(bookId);
  }

  // ──── Theme ────

  /// Clear cached theme, font, and font size preferences.
  static Future<bool> clearThemeCache() async {
    if (await GetStorage().initStorage) {
      var get = GetStorage();
      await get.remove(libTheme);
      await get.remove(libFont);
      await get.remove(libFontSize);
      return true;
    }
    return false;
  }

  // ──── Internal ────

  static void _checkInitialization() {
    if (!_initialized) {
      throw Exception(
        'CosmosEpub is not initialized. '
        'Call CosmosEpub.initialize() before using other methods.',
      );
    }
  }

  static _openBook({
    required BuildContext context,
    required EpubBook epubBook,
    required String bookId,
    required bool shouldOpenDrawer,
    required Color accentColor,
    required int starterChapter,
    required String chapterListTitle,
    Function(int currentPage, int totalPages)? onPageFlip,
    Function(int lastPageIndex)? onLastPage,
  }) async {
    _checkInitialization();

    if (starterChapter != -1) {
      await bookProgress.setCurrentChapterIndex(bookId, starterChapter);
      await bookProgress.setCurrentPageIndex(bookId, 0);
    }

    var route = MaterialPageRoute(
      builder: (context) {
        return ShowEpub(
          epubBook: epubBook,
          starterChapter: starterChapter >= 0
              ? starterChapter
              : bookProgress.getBookProgress(bookId).currentChapterIndex ?? 0,
          shouldOpenDrawer: shouldOpenDrawer,
          bookId: bookId,
          accentColor: accentColor,
          chapterListTitle: chapterListTitle,
          onPageFlip: onPageFlip,
          onLastPage: onLastPage,
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      shouldOpenDrawer || starterChapter != -1
          ? Navigator.pushReplacement(context, route)
          : Navigator.push(context, route);
    });
  }
}
