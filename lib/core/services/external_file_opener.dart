import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';

class ExternalFileOpener {
  static const MethodChannel _channel = MethodChannel(
    'de.doen1el.calibre_web_companion/external_file_opener',
  );

  static Future<OpenResult> open(String filePath) async {
    if (Platform.isAndroid && filePath.startsWith('content://')) {
      return _openAndroidContentUri(filePath);
    }

    return OpenFile.open(filePath);
  }

  static Future<OpenResult> _openAndroidContentUri(String uri) async {
    try {
      await _channel.invokeMethod<void>('openContentUri', {'uri': uri});
      return OpenResult();
    } on PlatformException catch (e) {
      return OpenResult(
        type: _resultTypeForPlatformException(e),
        message: e.message ?? e.code,
      );
    } catch (e) {
      return OpenResult(type: ResultType.error, message: e.toString());
    }
  }

  static ResultType _resultTypeForPlatformException(PlatformException e) {
    switch (e.code) {
      case 'activity_not_found':
        return ResultType.noAppToOpen;
      case 'permission_denied':
        return ResultType.permissionDenied;
      case 'file_unavailable':
        return ResultType.fileNotFound;
      default:
        return ResultType.error;
    }
  }
}
