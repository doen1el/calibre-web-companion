import 'package:flutter/material.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

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
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.searchBook),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: localizations.enterTitleAuthorOrTags,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
          ),
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            Navigator.of(context).pop(value);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(localizations.search)],
          ),
        ),
      ],
    );
  }
}
