import 'package:flutter/material.dart';

Future<void> showComingSoonDialog(
  BuildContext context,
  String contentText,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Coming Soon!'),
        content: Text(contentText),

        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}
