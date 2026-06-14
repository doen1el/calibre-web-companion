class ZipPathUtils {
  static String getDirectoryPath(String filePath) {
    var lastSlashIndex = filePath.lastIndexOf('/');
    if (lastSlashIndex == -1) {
      return '';
    } else {
      return filePath.substring(0, lastSlashIndex);
    }
  }

  static String? combine(String? directory, String? fileName) {
    if (directory == null || directory == '') {
      return fileName;
    } else {
      return directory + '/' + fileName!;
    }
  }
}
