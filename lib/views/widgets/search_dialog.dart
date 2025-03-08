import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  SearchDialogState createState() => SearchDialogState();
}

class SearchDialogState extends State<SearchDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(appLocalizations.searchBook),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: appLocalizations.enterTitleAuthorOrTags,
              ),
              autofocus: true,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => Navigator.of(context).pop(_controller.text = ''),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.cancel),
        ),

        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(appLocalizations.search),
        ),
      ],
    );
  }
}
