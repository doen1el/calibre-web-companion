import 'package:flutter/material.dart';

import 'package:calibre_web_companion/core/di/injection_container.dart';
import 'package:calibre_web_companion/core/services/widget_service.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

class WidgetSettingsPage extends StatefulWidget {
  const WidgetSettingsPage({super.key});

  @override
  State<WidgetSettingsPage> createState() => _WidgetSettingsPageState();
}

class _WidgetSettingsPageState extends State<WidgetSettingsPage> {
  final WidgetService _widgetService = getIt<WidgetService>();
  late WidgetTapTarget _tapTarget = _widgetService.tapTarget;

  Future<void> _select(WidgetTapTarget target) async {
    if (target == _tapTarget) return;
    setState(() => _tapTarget = target);
    await _widgetService.setTapTarget(target);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final options = <(WidgetTapTarget, String, IconData)>[
      (
        WidgetTapTarget.bookDetails,
        localizations.widgetActionBookDetails,
        Icons.menu_book_rounded,
      ),
      (
        WidgetTapTarget.internalReader,
        localizations.widgetActionInternalReader,
        Icons.chrome_reader_mode_rounded,
      ),
      (
        WidgetTapTarget.externalReader,
        localizations.widgetActionExternalReader,
        Icons.open_in_new_rounded,
      ),
      (
        WidgetTapTarget.appOnly,
        localizations.widgetActionOpenApp,
        Icons.apps_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(localizations.homeWidget)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, localizations.widgetTapAction),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                localizations.widgetTapActionDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  for (final option in options)
                    ListTile(
                      onTap: () => _select(option.$1),
                      leading: Icon(
                        option.$3,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(option.$2),
                      trailing:
                          _tapTarget == option.$1
                              ? Icon(
                                Icons.check_circle_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              )
                              : const Icon(Icons.circle_outlined),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildHowToCard(context, localizations),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToCard(BuildContext context, AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.widgets_rounded,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.widgetHowToAddTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizations.widgetHowToAddDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
