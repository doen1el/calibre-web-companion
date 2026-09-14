import 'dart:typed_data';

import 'package:docman/docman.dart';

const _chunkSize = 1024 * 1024;

/// Reads a SAF document in chunks. docman's `read()` loads the whole file into
/// the Java heap at once, and the resulting OutOfMemoryError on a large book
/// is not caught by the plugin, so it kills the app.
Future<Uint8List> readDocumentBytes(DocumentFile doc) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in doc.readAsBytes(bufferSize: _chunkSize)) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}
