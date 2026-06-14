import 'dart:async';

import 'package:archive/archive.dart';

import 'entities/epub_book.dart';
import 'entities/epub_byte_content_file.dart';
import 'entities/epub_chapter.dart';
import 'entities/epub_content.dart';
import 'entities/epub_content_file.dart';
import 'entities/epub_text_content_file.dart';
import 'readers/content_reader.dart';
import 'readers/schema_reader.dart';
import 'ref_entities/epub_book_ref.dart';
import 'ref_entities/epub_byte_content_file_ref.dart';
import 'ref_entities/epub_chapter_ref.dart';
import 'ref_entities/epub_content_file_ref.dart';
import 'ref_entities/epub_content_ref.dart';
import 'ref_entities/epub_text_content_file_ref.dart';
import 'schema/opf/epub_metadata_creator.dart';

/// A class that provides the primary interface to read Epub files.
///
/// To open an Epub and load all data at once use the [readBook()] method.
///
/// To open an Epub and load only basic metadata use the [openBook()] method.
/// This is a good option to quickly load text-based metadata, while leaving the
/// heavier lifting of loading images and main content for subsequent operations.
///
/// ## Example
/// ```dart
/// // Read the basic metadata.
/// EpubBookRef epub = await EpubReader.openBook(epubFileBytes);
/// // Extract values of interest.
/// String title = epub.Title;
/// String author = epub.Author;
/// var metadata = epub.Schema.Package.Metadata;
/// String genres = metadata.Subjects.join(', ');
/// ```
class EpubReader {
  /// Loads basics metadata.
  ///
  /// Opens the book asynchronously without reading its main content.
  /// Holds the handle to the EPUB file.
  ///
  /// Argument [bytes] should be the bytes of
  /// the epub file you have loaded with something like the [dart:io] package's
  /// [readAsBytes()].
  ///
  /// This is a fast and convenient way to get the most important information
  /// about the book, notably the [Title], [Author] and [AuthorList].
  /// Additional information is loaded in the [Schema] property such as the
  /// Epub version, Publishers, Languages and more.
  static Future<EpubBookRef> openBook(FutureOr<List<int>> bytes) async {
    List<int> loadedBytes;
    if (bytes is Future) {
      loadedBytes = await bytes;
    } else {
      loadedBytes = bytes;
    }

    var epubArchive = ZipDecoder().decodeBytes(loadedBytes);

    var bookRef = EpubBookRef(epubArchive);
    bookRef.Schema = await SchemaReader.readSchema(epubArchive);
    bookRef.Title = bookRef.Schema!.Package!.Metadata!.Titles!
        .firstWhere((String name) => true, orElse: () => '');
    bookRef.AuthorList = bookRef.Schema!.Package!.Metadata!.Creators!
        .map((EpubMetadataCreator creator) => creator.Creator)
        .toList();
    bookRef.Author = bookRef.AuthorList!.join(', ');
    bookRef.Content = ContentReader.parseContentMap(bookRef);
    return bookRef;
  }

  /// Opens the book asynchronously and reads all of its content into the memory. Does not hold the handle to the EPUB file.
  static Future<EpubBook> readBook(FutureOr<List<int>> bytes) async {
    var result = EpubBook();
    List<int> loadedBytes;
    if (bytes is Future) {
      loadedBytes = await bytes;
    } else {
      loadedBytes = bytes;
    }

    var epubBookRef = await openBook(loadedBytes);
    result.Schema = epubBookRef.Schema;
    result.Title = epubBookRef.Title;
    result.AuthorList = epubBookRef.AuthorList;
    result.Author = epubBookRef.Author;
    result.Content = await readContent(epubBookRef.Content!);
    // Non-fatal: a missing/declared-but-absent cover shouldn't fail the book.
    try {
      result.CoverImage = await epubBookRef.readCover();
    } catch (_) {
      result.CoverImage = null;
    }
    // Chapter extraction walks the navigation map and throws if a nav entry
    // points at a missing content file. Keep it non-fatal — an empty chapter
    // list lets consumers fall back to spine order instead of failing the whole
    // book. (calibre-web-companion patch.)
    var chapterRefs = <EpubChapterRef>[];
    try {
      chapterRefs = await epubBookRef.getChapters();
    } catch (_) {
      chapterRefs = <EpubChapterRef>[];
    }
    result.Chapters = await readChapters(chapterRefs);

    return result;
  }

  static Future<EpubContent> readContent(EpubContentRef contentRef) async {
    var result = EpubContent();
    result.Html = await readTextContentFiles(contentRef.Html!);
    result.Css = await readTextContentFiles(contentRef.Css!);
    result.Images = await readByteContentFiles(contentRef.Images!);
    result.Fonts = await readByteContentFiles(contentRef.Fonts!);
    result.AllFiles = <String, EpubContentFile>{};

    result.Html!.forEach((String? key, EpubTextContentFile value) {
      result.AllFiles![key!] = value;
    });
    result.Css!.forEach((String? key, EpubTextContentFile value) {
      result.AllFiles![key!] = value;
    });

    result.Images!.forEach((String? key, EpubByteContentFile value) {
      result.AllFiles![key!] = value;
    });
    result.Fonts!.forEach((String? key, EpubByteContentFile value) {
      result.AllFiles![key!] = value;
    });

    await Future.forEach(contentRef.AllFiles!.keys, (dynamic key) async {
      if (!result.AllFiles!.containsKey(key)) {
        // Non-fatal: skip unreadable/missing files (see readTextContentFiles).
        try {
          result.AllFiles![key] =
              await readByteContentFile(contentRef.AllFiles![key]!);
        } catch (_) {}
      }
    });

    return result;
  }

  static Future<Map<String, EpubTextContentFile>> readTextContentFiles(
      Map<String, EpubTextContentFileRef> textContentFileRefs) async {
    var result = <String, EpubTextContentFile>{};

    await Future.forEach(textContentFileRefs.keys, (dynamic key) async {
      EpubContentFileRef value = textContentFileRefs[key]!;
      var textContentFile = EpubTextContentFile();
      textContentFile.FileName = value.FileName;
      textContentFile.ContentType = value.ContentType;
      textContentFile.ContentMimeType = value.ContentMimeType;
      // Non-fatal: a manifest may list a file that isn't actually in the
      // archive. Skip it instead of failing the whole book — the reader falls
      // back to whatever content is present. (calibre-web-companion patch.)
      try {
        textContentFile.Content = await value.readContentAsText();
        result[key] = textContentFile;
      } catch (_) {}
    });
    return result;
  }

  static Future<Map<String, EpubByteContentFile>> readByteContentFiles(
      Map<String, EpubByteContentFileRef> byteContentFileRefs) async {
    var result = <String, EpubByteContentFile>{};
    await Future.forEach(byteContentFileRefs.keys, (dynamic key) async {
      // Non-fatal: skip files that can't be read (see readTextContentFiles).
      try {
        result[key] = await readByteContentFile(byteContentFileRefs[key]!);
      } catch (_) {}
    });
    return result;
  }

  static Future<EpubByteContentFile> readByteContentFile(
      EpubContentFileRef contentFileRef) async {
    var result = EpubByteContentFile();

    result.FileName = contentFileRef.FileName;
    result.ContentType = contentFileRef.ContentType;
    result.ContentMimeType = contentFileRef.ContentMimeType;
    result.Content = await contentFileRef.readContentAsBytes();

    return result;
  }

  static Future<List<EpubChapter>> readChapters(
      List<EpubChapterRef> chapterRefs) async {
    var result = <EpubChapter>[];
    await Future.forEach(chapterRefs, (EpubChapterRef chapterRef) async {
      var chapter = EpubChapter();

      chapter.Title = chapterRef.Title;
      chapter.ContentFileName = chapterRef.ContentFileName;
      chapter.Anchor = chapterRef.Anchor;
      chapter.HtmlContent = await chapterRef.readHtmlContent();
      chapter.SubChapters = await readChapters(chapterRef.SubChapters!);

      result.add(chapter);
    });
    return result;
  }
}
