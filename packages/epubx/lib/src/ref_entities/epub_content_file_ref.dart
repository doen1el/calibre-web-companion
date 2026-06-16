import 'dart:async';
import 'dart:convert' as convert;

import 'package:archive/archive.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:quiver/core.dart';

import '../entities/epub_content_type.dart';
import '../utils/zip_path_utils.dart';
import 'epub_book_ref.dart';

abstract class EpubContentFileRef {
  late EpubBookRef epubBookRef;

  String? FileName;

  EpubContentType? ContentType;
  String? ContentMimeType;
  EpubContentFileRef(EpubBookRef epubBookRef) {
    this.epubBookRef = epubBookRef;
  }

  @override
  int get hashCode =>
      hash3(FileName.hashCode, ContentMimeType.hashCode, ContentType.hashCode);

  @override
  bool operator ==(other) {
    if (!(other is EpubContentFileRef)) {
      return false;
    }

    return (other.FileName == FileName &&
        other.ContentMimeType == ContentMimeType &&
        other.ContentType == ContentType);
  }

  ArchiveFile getContentFileEntry() {
    var contentFilePath = ZipPathUtils.combine(
            epubBookRef.Schema!.ContentDirectoryPath, FileName) ??
        '';
    final files = epubBookRef.EpubArchive()!.files;

    // Tolerant lookup. Manifest hrefs and actual zip entry names often differ
    // by case or URL-encoding (e.g. spaces as %20), which a strict `==` match
    // misses and then throws on — failing the whole book. Try progressively
    // looser matches before giving up. (calibre-web-companion patch.)
    var contentFileEntry =
        files.firstWhereOrNull((ArchiveFile x) => x.name == contentFilePath);
    if (contentFileEntry == null) {
      final decoded = Uri.decodeFull(contentFilePath);
      final lower = decoded.toLowerCase();
      contentFileEntry = files.firstWhereOrNull(
          (ArchiveFile x) => Uri.decodeFull(x.name).toLowerCase() == lower);
    }
    if (contentFileEntry == null) {
      // Last resort: match on bare filename (handles differing directory paths).
      final base = Uri.decodeFull(contentFilePath).split('/').last.toLowerCase();
      contentFileEntry = files.firstWhereOrNull(
          (ArchiveFile x) =>
              Uri.decodeFull(x.name).split('/').last.toLowerCase() == base);
    }
    if (contentFileEntry == null) {
      throw Exception(
          'EPUB parsing error: file $contentFilePath not found in archive.');
    }
    return contentFileEntry;
  }

  List<int> getContentStream() {
    return openContentStream(getContentFileEntry());
  }

  List<int> openContentStream(ArchiveFile contentFileEntry) {
    var contentStream = <int>[];
    if (contentFileEntry.content == null) {
      throw Exception(
          'Incorrect EPUB file: content file \"$FileName\" specified in manifest is not found.');
    }
    contentStream.addAll(contentFileEntry.content);
    return contentStream;
  }

  Future<List<int>> readContentAsBytes() async {
    var contentFileEntry = getContentFileEntry();
    var content = openContentStream(contentFileEntry);
    return content;
  }

  Future<String> readContentAsText() async {
    var contentStream = getContentStream();
    var result = convert.utf8.decode(contentStream);
    return result;
  }
}
