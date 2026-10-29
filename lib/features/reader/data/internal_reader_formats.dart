import 'dart:typed_data';

class InternalReaderFormats {
  static const Set<String> supported = {'epub', 'pdf', 'cbz'};
  static const Set<String> pageBased = {'pdf', 'cbz'};

  static bool isSupported(String format) =>
      supported.contains(format.toLowerCase());

  static bool isPageBased(String format) =>
      pageBased.contains(format.toLowerCase());

  static bool bytesMatch(String format, Uint8List bytes) {
    if (bytes.length < 4) return false;
    if (format.toLowerCase() == 'pdf') {
      return bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46;
    }
    return bytes[0] == 0x50 && bytes[1] == 0x4B;
  }
}
