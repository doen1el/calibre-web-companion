part of 'package:vocsy_epub_viewer/epub_viewer.dart';

class Util {
  /// Get HEX code from [Colors], [MaterialColor],
  /// [Color] and [MaterialAccentColor]
  static String getHexFromColor(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Convert [EpubScrollDirection] to FolioReader reader String
  static String getDirection(EpubScrollDirection direction) {
    switch (direction) {
      case EpubScrollDirection.VERTICAL:
        return 'vertical';
      case EpubScrollDirection.HORIZONTAL:
        return 'horizontal';
      case EpubScrollDirection.ALLDIRECTIONS:
        return 'alldirections';
      default:
        return 'alldirections';
    }
  }

  /// Create a temporary [File] from an asset epub
  /// to be opened by [VocsyEpub]
  static Future<File> getFileFromAsset(String asset) async {
    ByteData data = await rootBundle.load(asset);
    String dir = (await getTemporaryDirectory()).path;
    String path = '$dir/${basename(asset)}';
    final buffer = data.buffer;
    return File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}
