/// MIME types for the book formats Calibre-Web can serve.
const Map<String, String> bookMimeTypes = {
  'epub': 'application/epub+zip',
  'kepub': 'application/epub+zip',
  'pdf': 'application/pdf',
  'mobi': 'application/x-mobipocket-ebook',
  'prc': 'application/x-mobipocket-ebook',
  'pdb': 'application/x-mobipocket-ebook',
  'azw': 'application/vnd.amazon.ebook',
  'azw3': 'application/vnd.amazon.ebook',
  'fb2': 'application/x-fictionbook+xml',
  'cbz': 'application/vnd.comicbook+zip',
  'cbr': 'application/vnd.comicbook-rar',
  'djvu': 'image/vnd.djvu',
  'djv': 'image/vnd.djvu',
  'txt': 'text/plain',
  'rtf': 'application/rtf',
  'htm': 'text/html',
  'html': 'text/html',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'odt': 'application/vnd.oasis.opendocument.text',
};

/// Resolves the MIME type of a file path or a bare format such as `epub`.
String? bookMimeType(String pathOrFormat) {
  final extension = pathOrFormat.split('.').last.toLowerCase().trim();
  return bookMimeTypes[extension];
}

/// MIME types Calibre-Web (and other OPDS servers) put on acquisition links,
/// mapped back to the Calibre format they stand for.
const Map<String, String> _acquisitionFormats = {
  'application/epub+zip': 'epub',
  'application/x-kepub+zip': 'kepub',
  'application/pdf': 'pdf',
  'application/x-mobipocket-ebook': 'mobi',
  'application/mobi': 'mobi',
  'application/x-mobi8-ebook': 'azw3',
  'application/vnd.amazon.mobi8-ebook': 'azw3',
  'application/vnd.amazon.ebook': 'azw3',
  'application/x-fictionbook+xml': 'fb2',
  'application/fb2': 'fb2',
  'application/vnd.comicbook+zip': 'cbz',
  'application/x-cbz': 'cbz',
  'application/vnd.comicbook-rar': 'cbr',
  'application/x-cbr': 'cbr',
  'application/x-cbt': 'cbt',
  'image/vnd.djvu': 'djvu',
  'image/x-djvu': 'djvu',
  'image/djvu': 'djvu',
  'application/djvu': 'djvu',
  'application/x-djvu': 'djvu',
  'application/vnd.palm': 'pdb',
  'application/x-sony-bbeb': 'lrf',
  'application/vnd.ms-htmlhelp': 'chm',
  'application/x-ms-reader': 'lit',
  'application/rtf': 'rtf',
  'text/rtf': 'rtf',
  'text/plain': 'txt',
  'text/markdown': 'md',
  'text/x-markdown': 'md',
  'text/html': 'html',
  'application/msword': 'doc',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      'docx',
  'application/vnd.oasis.opendocument.text': 'odt',
};

final RegExp _formatSegment = RegExp(r'^[a-z0-9]{2,8}$');

/// Reads the format out of an OPDS acquisition link.
///
/// Falls back to the download URL (`/opds/download/42/djvu/`, `book.djvu`) so
/// formats without a well-known MIME type still get picked up.
String? bookFormatFromAcquisition({String? mimeType, String? href}) {
  final mime = mimeType?.toLowerCase().split(';').first.trim();
  if (mime != null && mime.isNotEmpty) {
    final known = _acquisitionFormats[mime];
    if (known != null) return known;
  }

  return _bookFormatFromHref(href);
}

String? _bookFormatFromHref(String? href) {
  if (href == null || href.isEmpty) return null;

  final segments =
      (Uri.tryParse(href)?.pathSegments ?? const <String>[])
          .where((segment) => segment.isNotEmpty)
          .toList();
  if (segments.isEmpty) return null;

  final downloadIndex = segments.lastIndexOf('download');
  if (downloadIndex != -1 && downloadIndex + 2 < segments.length) {
    final candidate = segments[downloadIndex + 2].toLowerCase();
    if (_formatSegment.hasMatch(candidate) && int.tryParse(candidate) == null) {
      return candidate;
    }
  }

  final last = segments.last;
  if (last.contains('.')) {
    final extension = last.split('.').last.toLowerCase();
    if (_formatSegment.hasMatch(extension)) return extension;
  }

  return null;
}
