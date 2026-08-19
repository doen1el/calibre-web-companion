import 'package:calibre_web_companion/features/settings/data/models/download_path_template.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';
import 'package:flutter/material.dart';

/// Lets the user assemble a download path from tokens, with a live preview.
class DownloadPathTemplateDialog extends StatefulWidget {
  const DownloadPathTemplateDialog({super.key, required this.initialTemplate});

  final String initialTemplate;

  @override
  State<DownloadPathTemplateDialog> createState() =>
      _DownloadPathTemplateDialogState();
}

class _DownloadPathTemplateDialogState
    extends State<DownloadPathTemplateDialog> {
  static const String _calibreExample =
      '{#library}/{author_sort:.20}/'
      '{series:|| - }{series_index:0>2s|| - }{title:.15}';

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text:
          widget.initialTemplate.isEmpty
              ? DownloadPathTemplate.defaultTemplate
              : widget.initialTemplate,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insert(String text) {
    final value = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : value.length;
    final end = selection.isValid ? selection.end : value.length;

    final updated = value.replaceRange(start, end, text);
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(localizations.downloadPathTemplate),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              minLines: 1,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.downloadPathTemplateHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final token in DownloadPathToken.values)
                  ActionChip(
                    label: Text(token.placeholder),
                    onPressed: () => _insert(token.placeholder),
                  ),
                ActionChip(
                  label: const Text('{#column}'),
                  onPressed: () => _insert('{#column}'),
                ),
                ActionChip(
                  label: const Text('/'),
                  onPressed: () => _insert('/'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              localizations.downloadPathTemplateCalibreHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            const SelectableText(
              _calibreExample,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.preview,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DownloadPathTemplate.preview(_controller.text),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppDialogButton(
          onPressed:
              () => _controller.text = DownloadPathTemplate.defaultTemplate,
          label: localizations.reset,
        ),
        AppDialogButton(
          onPressed: () => Navigator.of(context).pop(),
          label: localizations.cancel,
        ),
        AppDialogButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          label: localizations.save,
        ),
      ],
    );
  }
}
