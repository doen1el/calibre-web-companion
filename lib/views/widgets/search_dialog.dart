import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('Search Books'),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter title, author, or tags...',
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
          child: const Text('CANCEL'),
        ),

        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('SEARCH'),
        ),
      ],
    );
  }
}
