import 'package:flutter/material.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';

class CreateShelfDialog extends StatefulWidget {
  final Function(String, bool) onCreateShelf;

  const CreateShelfDialog({super.key, required this.onCreateShelf});

  @override
  State<CreateShelfDialog> createState() => _CreateShelfDialogState();
}

class _CreateShelfDialogState extends State<CreateShelfDialog> {
  final _controller = TextEditingController();
  bool _isCreating = false;
  bool _isPublic = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.createShelf),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: localizations.shelfName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.list_rounded),
              ),
              autofocus: true,
              enabled: !_isCreating,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(localizations.public),
              value: _isPublic,
              onChanged:
                  _isCreating
                      ? null
                      : (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        AppDialogButton(
          onPressed: _isCreating ? null : _createShelf,
          isLoading: _isCreating,
          loadingLabel: localizations.creating,
          label: localizations.create,
        ),
      ],
    );
  }

  void _createShelf() {
    final localizations = AppLocalizations.of(context)!;

    if (_controller.text.trim().isEmpty) {
      context.showSnackBar(localizations.shelfNameRequired, isError: true);
      return;
    }

    setState(() {
      _isCreating = true;
    });

    widget.onCreateShelf(_controller.text.trim(), _isPublic);
    Navigator.of(context).pop();
  }
}
