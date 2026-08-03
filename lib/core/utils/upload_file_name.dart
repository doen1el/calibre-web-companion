import 'dart:typed_data';

/// Builds the multipart file name for uploads.
class UploadFileName {
  /// Mirrors werkzeug's `secure_filename`: calibre-web returns a 400 for names
  /// with parentheses, brackets, spaces and other special characters.
  static String sanitize(String rawFileName) {
    final dotIndex = rawFileName.lastIndexOf('.');
    final rawName =
        dotIndex > 0 ? rawFileName.substring(0, dotIndex) : rawFileName;
    final ext = dotIndex > 0 ? rawFileName.substring(dotIndex) : '';

    final sanitizedName = rawName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return '${sanitizedName.isEmpty ? 'upload' : sanitizedName}$ext';
  }

  static bool hasExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 && dotIndex < fileName.length - 1;
  }

  /// Detects the book format from the first bytes of a file.
  /// Returns null when the format cannot be identified with confidence.
  static String? detectExtension(Uint8List head) {
    if (_startsWith(head, '%PDF')) return 'pdf';
    if (_startsWith(head, 'AT&TFORM')) return 'djvu';
    if (_startsWith(head, 'Rar!')) return 'cbr';

    // MOBI/AZW keep their type at offset 60 of the PalmDOC header
    if (head.length >= 68) {
      final type = String.fromCharCodes(head.sublist(60, 68));
      if (type == 'BOOKMOBI') return 'mobi';
      if (type.startsWith('TPZ')) return 'azw3';
    }

    if (_startsWith(head, 'PK')) {
      final text = _asLatin1(head);
      if (text.contains('application/epub+zip') ||
          text.contains('META-INF/container.xml')) {
        return 'epub';
      }
      return null; // some other zip, could be cbz - do not guess
    }

    final text = _asLatin1(head);
    if (text.contains('<FictionBook') || text.contains('FictionBook')) {
      return 'fb2';
    }

    return null;
  }

  /// Returns a sanitized file name that always carries an extension when one
  /// can be determined.
  static String resolve(String rawFileName, {Uint8List? head}) {
    var fileName = rawFileName.split('/').last.split('\\').last.trim();
    if (fileName.isEmpty) fileName = 'upload';

    if (!hasExtension(fileName) && head != null) {
      final detected = detectExtension(head);
      if (detected != null) fileName = '$fileName.$detected';
    }

    return sanitize(fileName);
  }

  static bool _startsWith(Uint8List bytes, String prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix.codeUnitAt(i)) return false;
    }
    return true;
  }

  static String _asLatin1(Uint8List bytes) => String.fromCharCodes(
    bytes.length > 4096 ? bytes.sublist(0, 4096) : bytes,
  );
}
