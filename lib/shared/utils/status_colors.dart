import 'package:flutter/material.dart';

class StatusColors {
  const StatusColors._();

  /// Success / completed (green).
  static Color success(BuildContext context) => _shade(context, Colors.green);

  /// In-progress / warning (amber).
  static Color warning(BuildContext context) => _shade(context, Colors.amber);

  /// Informational / available (blue).
  static Color info(BuildContext context) => _shade(context, Colors.blue);

  /// Queued / waiting (purple).
  static Color pending(BuildContext context) => _shade(context, Colors.purple);

  /// Error / failed
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  /// Neutral / inactive
  static Color neutral(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color _shade(BuildContext context, MaterialColor base) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? base.shade300 : base.shade700;
  }
}
