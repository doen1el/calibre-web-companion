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
