import 'package:flutter/material.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';

class CreateShelfDialog extends StatefulWidget {
  final Function(String) onCreateShelf;

  const CreateShelfDialog({super.key, required this.onCreateShelf});

  @override
  State<CreateShelfDialog> createState() => _CreateShelfDialogState();
}

class _CreateShelfDialogState extends State<CreateShelfDialog> {
  final _controller = TextEditingController();
  bool _isCreating = false;

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
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: localizations.shelfName,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.list_rounded),
          ),
          autofocus: true,
          enabled: !_isCreating,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createShelf,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCreating)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              if (_isCreating) const SizedBox(width: 8),
              Text(_isCreating ? localizations.creating : localizations.create),
            ],
          ),
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

    widget.onCreateShelf(_controller.text.trim());
    Navigator.of(context).pop();
  }
}
