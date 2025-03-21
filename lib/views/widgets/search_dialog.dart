import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  SearchDialogState createState() => SearchDialogState();
}

class SearchDialogState extends State<SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(16.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with decorative line
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                appLocalizations.searchBook,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            // Search field with custom design
            Container(
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  // ignore: deprecated_member_use
                  color: theme.colorScheme.outline.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Icon(Icons.search, color: theme.colorScheme.primary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: appLocalizations.enterTitleAuthorOrTags,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        Navigator.of(context).pop(value);
                      },
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _controller.clear(),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    appLocalizations.cancel,
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_controller.text),
                  child: Text(appLocalizations.search),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
