import 'package:flutter/material.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';

class EditShelfDialog extends StatefulWidget {
  final String currentName;
  final bool isPublic;
  final Function(String, bool) onEditShelf;

  const EditShelfDialog({
    super.key,
    required this.currentName,
    required this.isPublic,
    required this.onEditShelf,
  });

  @override
  State<EditShelfDialog> createState() => _EditShelfDialogState();
}

class _EditShelfDialogState extends State<EditShelfDialog> {
  late final TextEditingController _controller;
  bool _isEditing = false;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
    _isPublic = widget.isPublic;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.editShelf),
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
              enabled: !_isEditing,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Public'),
              value: _isPublic,
              onChanged:
                  _isEditing
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
          onPressed: _isEditing ? null : () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: _isEditing ? null : _editShelf,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isEditing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              if (_isEditing) const SizedBox(width: 8),
              Text(_isEditing ? localizations.editing : localizations.edit),
            ],
          ),
        ),
      ],
    );
  }

  void _editShelf() {
    final localizations = AppLocalizations.of(context)!;

    if (_controller.text.trim().isEmpty) {
      context.showSnackBar(localizations.shelfNameRequired, isError: true);
      return;
    }

    setState(() {
      _isEditing = true;
    });

    widget.onEditShelf(_controller.text.trim(), _isPublic);
    Navigator.of(context).pop();
  }
}
