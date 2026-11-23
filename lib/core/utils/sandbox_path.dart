import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// iOS gives the app container a new UUID on updates and reinstalls, so an
// absolute path saved earlier points into a container that no longer exists.
class SandboxPath {
  static String? _containerRoot;

  static final _container = RegExp(r'^.*/Data/Application/[0-9A-Fa-f-]+(?=/)');

  static Future<void> init() async {
    if (!Platform.isIOS) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      _containerRoot = docs.parent.path;
    } catch (_) {}
  }

  @visibleForTesting
  static set containerRoot(String? root) => _containerRoot = root;

  static String rebase(String path) {
    final root = _containerRoot;
    if (root == null || path.isEmpty || path.startsWith('$root/')) return path;
    final match = _container.firstMatch(path);
    if (match == null) return path;
    return root + path.substring(match.end);
  }

  static String? rebaseNullable(String? path) =>
      path == null ? null : rebase(path);
}
