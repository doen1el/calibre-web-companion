import 'dart:io';

import 'package:docman/docman.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('de.doen1el.calibreWebCompanion/saf');

/// Copies [source] into [directory] under exactly [name] and returns the new
/// document's URI. docman's copyTo replaces spaces/brackets with '_' and cuts
/// the name at the first dot, which breaks KOReader filename sync (#223).
Future<String?> copyFileToSafDirectory(
  File source,
  DocumentFile directory,
  String name,
) async {
  if (Platform.isAndroid) {
    try {
      return await _channel.invokeMethod<String>('copyFileToDirectory', {
        'source': source.path,
        'directory': directory.uri,
        'name': name,
      });
    } on MissingPluginException {
      // fall through to docman
    }
  }

  final tempDoc = await DocumentFile.fromUri(source.path);
  if (tempDoc == null) {
    throw Exception('Could not open temporary download file');
  }
  // docman cuts the name at the first dot, so keep only the extension's dot
  final dot = name.lastIndexOf('.');
  final docmanName =
      dot > 0
          ? '${name.substring(0, dot).replaceAll('.', ' ')}${name.substring(dot)}'
          : name;
  final created = await tempDoc.copyTo(directory.uri, name: docmanName);
  return created?.uri;
}

/// Renames [document] to exactly [name]; returns the new URI or null when the
/// provider (or platform) can't rename.
Future<String?> renameSafDocument(DocumentFile document, String name) async {
  if (!Platform.isAndroid) return null;
  try {
    return await _channel.invokeMethod<String>('renameDocument', {
      'uri': document.uri,
      'name': name,
    });
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}
