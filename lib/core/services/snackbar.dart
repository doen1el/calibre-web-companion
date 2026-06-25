import 'package:flutter/material.dart';

import 'package:calibre_web_companion/core/utils/network_error.dart';

extension SnackBarExtension on BuildContext {
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (isError && isNetworkErrorMessage(message)) return;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Theme.of(this).colorScheme.error
                : Theme.of(this).colorScheme.primary,
        duration: duration,
      ),
    );
  }
}
