import 'package:flutter/material.dart';

extension SnackBarExtension on BuildContext {
  /// Shows a SnackBar with the given [message].
  ///
  /// Parameters:
  ///
  /// - [message]: The message to display in the SnackBar.
  /// - [isError]: Whether the message is an error message.
  /// - [duration]: The duration for which the SnackBar should be displayed.
  void showSnackBar(
    String message, {
    required bool isError,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Theme.of(this).colorScheme.error
                : Theme.of(this).colorScheme.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}
