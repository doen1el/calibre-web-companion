import 'package:flutter/material.dart';

class AppDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  final bool isLoading;
  final String? loadingLabel;

  final IconData? icon;

  final bool isDestructive;

  const AppDialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.icon,
    this.isDestructive = false,
  });

  const AppDialogButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.icon,
  }) : isDestructive = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color background =
        isDestructive ? scheme.errorContainer : scheme.primaryContainer;
    final Color foreground =
        isDestructive ? scheme.onErrorContainer : scheme.onPrimaryContainer;

    final style = FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: background.withValues(alpha: 0.5),
      disabledForegroundColor: foreground.withValues(alpha: 0.5),
    );

    if (isLoading) {
      return FilledButton(
        onPressed: null,
        style: style,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            ),
            const SizedBox(width: 8),
            Text(loadingLabel ?? label),
          ],
        ),
      );
    }

    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }
}
