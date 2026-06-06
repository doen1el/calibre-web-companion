import 'package:flutter/material.dart';

class AppSheetOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool enabled;

  const AppSheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
    this.enabled = true,
  });
}

Future<void> showAppOptionsSheet(
  BuildContext context, {
  required String title,
  required List<AppSheetOption> options,
}) {
  return showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppOptionsSheetHeader(title: title),
            ...options.map(
              (option) => AppOptionTile(
                icon: option.icon,
                title: option.title,
                subtitle: option.subtitle,
                isDestructive: option.isDestructive,
                enabled: option.enabled,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  option.onTap();
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

class AppOptionsSheetHeader extends StatelessWidget {
  final String title;

  const AppOptionsSheetHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AppOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool enabled;

  final Widget? trailing;

  const AppOptionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.enabled = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color badgeColor;
    final Color iconColor;
    if (!enabled) {
      badgeColor = scheme.surfaceContainerHighest;
      iconColor = scheme.onSurfaceVariant.withValues(alpha: 0.5);
    } else if (isDestructive) {
      badgeColor = scheme.errorContainer;
      iconColor = scheme.onErrorContainer;
    } else {
      badgeColor = scheme.primaryContainer;
      iconColor = scheme.onPrimaryContainer;
    }

    final titleColor =
        !enabled
            ? scheme.onSurface.withValues(alpha: 0.5)
            : isDestructive
            ? scheme.error
            : null;

    return ListTile(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing:
          trailing ??
          (enabled
              ? const Icon(Icons.chevron_right_rounded)
              : const SizedBox.shrink()),
    );
  }
}
