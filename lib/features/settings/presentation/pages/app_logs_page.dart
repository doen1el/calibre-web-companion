import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/services/app_log_service.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

class AppLogsPage extends StatelessWidget {
  const AppLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final appLogService = GetIt.instance<AppLogService>();

    Future<void> copyLogs() async {
      final logs = appLogService.exportText();
      if (logs.trim().isEmpty) return;
      await Clipboard.setData(ClipboardData(text: logs));
      if (context.mounted) {
        context.showSnackBar(localizations.logsCopied);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appLogs),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: appLogService.revision,
            builder: (context, _, __) {
              final hasLogs = !appLogService.isEmpty;
              return IconButton(
                tooltip: localizations.copyLogs,
                onPressed: hasLogs ? copyLogs : null,
                icon: const Icon(Icons.copy_rounded),
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: appLogService.revision,
            builder: (context, _, __) {
              final hasLogs = !appLogService.isEmpty;
              return IconButton(
                tooltip: localizations.clearLogs,
                onPressed: hasLogs ? appLogService.clear : null,
                icon: const Icon(Icons.delete_sweep_rounded),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: appLogService.revision,
        builder: (context, _, __) {
          final text = appLogService.exportText();

          if (text.trim().isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  localizations.noLogsAvailable,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          );
        },
      ),
    );
  }
}
