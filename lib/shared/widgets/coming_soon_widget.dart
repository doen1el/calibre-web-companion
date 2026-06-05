import 'package:flutter/material.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';

Future<void> showComingSoonDialog(
  BuildContext context,
  String contentText,
) async {
  final localizations = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(localizations.comingSoon),
        content: Text(contentText),

        actions: <Widget>[
          AppDialogButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            label: localizations.ok,
          ),
        ],
      );
    },
  );
}
