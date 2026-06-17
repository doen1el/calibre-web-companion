import 'dart:convert';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';

import '../Model/chapter_model.dart';

/// Parses an EpubBook into a flat chapter list with infinite nesting support
/// and extracts all images for rendering.
///
/// Uses multiple strategies to build the chapter list:
/// 1. NCX NavMap with recursive ChildNavigationPoints (handles nested TOCs)
/// 2. Falls back to epubx Chapters if NavMap is empty
/// 3. Falls back to spine order if both fail
class EpubContentParser {
  final EpubBook epubBook;
  late final List<LocalChapterModel> flatChapters;
  late final Map<String, Uint8List> imageMap;

  EpubContentParser(this.epubBook) {
    flatChapters = _buildChapterList();
    imageMap = _extractImages();
  }

  List<LocalChapterModel> _buildChapterList() {
    // Strategy 1: Build from NCX NavMap (supports nested navPoints)
    final navPoints = epubBook.Schema?.Navigation?.NavMap?.Points;
    if (navPoints != null && navPoints.isNotEmpty) {
      final list = <LocalChapterModel>[];
      _flattenNavPoints(navPoints, list, 0);
      if (list.isNotEmpty) return list;
    }

    // Strategy 2: Use epubx Chapters (works for simple flat TOCs)
    if (epubBook.Chapters != null && epubBook.Chapters!.isNotEmpty) {
      final list = <LocalChapterModel>[];
      _flattenEpubChapters(epubBook.Chapters!, list, 0);
      if (list.isNotEmpty) return list;
    }

    // Strategy 3: Fall back to spine order (catches EPUBs with no/broken TOC)
    return _buildFromSpine();
  }

  /// Recursively flatten NCX navigation points — handles infinite nesting.
  void _flattenNavPoints(List<EpubNavigationPoint> points,
      List<LocalChapterModel> list, int depth) {
    for (final point in points) {
      final title =
          point.NavigationLabels?.isNotEmpty == true
              ? point.NavigationLabels!.first.Text ?? '...'
              : '...';
      final source = point.Content?.Source ?? '';
      final htmlContent = _resolveContentBySource(source);

      if (source.isEmpty && htmlContent.isEmpty) {
        // Section wrapper with no content — generate a centered title page
        list.add(LocalChapterModel(
          chapter: title,
          htmlContent: '',
          isSectionTitle: true,
          depth: depth,
        ));
      } else {
        list.add(LocalChapterModel(
          chapter: title,
          htmlContent: htmlContent,
          depth: depth,
        ));
      }

      // Recurse into children (infinite nesting)
      if (point.ChildNavigationPoints != null &&
          point.ChildNavigationPoints!.isNotEmpty) {
        _flattenNavPoints(point.ChildNavigationPoints!, list, depth + 1);
      }
    }
  }

  /// Resolve a TOC source path to actual HTML content from the EPUB.
  String _resolveContentBySource(String source) {
    if (source.isEmpty) return '';

    // Strip fragment (#anchor)
    final cleanSource = source.split('#').first;

    final htmlFiles = epubBook.Content?.Html;
    if (htmlFiles == null) return '';

    // Try exact match
    if (htmlFiles.containsKey(cleanSource)) {
      return htmlFiles[cleanSource]?.Content ?? '';
    }

    // Try matching by filename
    final filename = cleanSource.split('/').last;
    for (final entry in htmlFiles.entries) {
      if (entry.key.endsWith(filename)) {
        return entry.value.Content ?? '';
      }
    }

    return '';
  }

  /// Flatten epubx EpubChapter objects (fallback).
  void _flattenEpubChapters(
      List<EpubChapter> chapters, List<LocalChapterModel> list, int depth) {
    for (final chapter in chapters) {
      list.add(LocalChapterModel(
        chapter: chapter.Title ?? '...',
        htmlContent: chapter.HtmlContent ?? '',
        depth: depth,
      ));
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        _flattenEpubChapters(chapter.SubChapters!, list, depth + 1);
      }
    }
  }

  /// Build chapter list from spine order (last resort).
  List<LocalChapterModel> _buildFromSpine() {
    final list = <LocalChapterModel>[];
    final htmlFiles = epubBook.Content?.Html;
    if (htmlFiles == null) return list;

    // Use spine order
    final spineItems = epubBook.Schema?.Package?.Spine?.Items;
    final manifest = epubBook.Schema?.Package?.Manifest?.Items;

    if (spineItems != null && manifest != null) {
      for (final spineItem in spineItems) {
        final manifestItem =
            manifest.where((m) => m.Id == spineItem.IdRef).firstOrNull;
        if (manifestItem == null) continue;
        final href = manifestItem.Href ?? '';
        if (href.isEmpty) continue;

        final content = _resolveContentBySource(href);
        if (content.isEmpty) continue;

        // Skip nav pages
        if (href.contains('nav')) continue;

        list.add(LocalChapterModel(
          chapter: 'Chapter ${list.length + 1}',
          htmlContent: content,
          depth: 0,
        ));
      }
    } else {
      // No spine — just dump all HTML files
      for (final entry in htmlFiles.entries) {
        if (entry.key.contains('nav')) continue;
        list.add(LocalChapterModel(
          chapter: entry.key.split('/').last.replaceAll('.xhtml', ''),
          htmlContent: entry.value.Content ?? '',
          depth: 0,
        ));
      }
    }

    return list;
  }

  Map<String, Uint8List> _extractImages() {
    final map = <String, Uint8List>{};
    final images = epubBook.Content?.Images;
    if (images != null) {
      for (final entry in images.entries) {
        if (entry.value.Content != null) {
          map[entry.key] = Uint8List.fromList(entry.value.Content!);
        }
      }
    }
    return map;
  }

  Uint8List? resolveImage(String src) {
    if (imageMap.containsKey(src)) return imageMap[src];

    final filename = src.split('/').last.split('?').first;
    for (final entry in imageMap.entries) {
      if (entry.key.endsWith(filename)) return entry.value;
    }

    final normalized = src.replaceAll(RegExp(r'^(\.\./)+'), '');
    if (imageMap.containsKey(normalized)) return imageMap[normalized];
    for (final entry in imageMap.entries) {
      if (entry.key.endsWith(normalized)) return entry.value;
    }

    return null;
  }

  String resolveImagesInHtml(String html) {
    return html.replaceAllMapped(
      RegExp(r'''src\s*=\s*["']([^"']+)["']'''),
      (match) {
        final src = match.group(1)!;
        if (src.startsWith('data:')) return match.group(0)!;
        final bytes = resolveImage(src);
        if (bytes != null) {
          final mimeType = _getMimeType(src);
          final base64Str = base64Encode(bytes);
          return 'src="data:$mimeType;base64,$base64Str"';
        }
        return match.group(0)!;
      },
    );
  }

  static String _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    return 'image/png';
  }
}
