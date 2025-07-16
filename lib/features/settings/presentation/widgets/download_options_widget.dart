import 'package:docman/docman.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadOptionsWidget extends StatelessWidget {
  const DownloadOptionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSelectingDownloadFolder(context),
        _buildSelectingDownloadSchema(context),
      ],
    );
  }

  Widget _buildSelectingDownloadFolder(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen:
          (previous, current) =>
              previous.defaultDownloadPath != current.defaultDownloadPath,
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.downloadFolder,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.defaultDownloadPath.isNotEmpty
                            ? state.defaultDownloadPath
                            : localizations.noFolderSelected,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    DocumentFile? selectedDirectory =
                        await DocMan.pick.directory();
                    if (selectedDirectory == null) {
                      // ignore: use_build_context_synchronously
                      context.showSnackBar(
                        localizations.noFolderWasSelected,
                        isError: true,
                      );
                      return;
                    }

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                      'download_folder_path',
                      selectedDirectory.uri,
                    );

                    // ignore: use_build_context_synchronously
                    context.read<SettingsBloc>().add(
                      SetDownloadFolder(selectedDirectory.uri),
                    );

                    // ignore: use_build_context_synchronously
                    context.showSnackBar(
                      localizations.folderSelectedSuccessfully,
                      isError: false,
                    );
                  },
                  child: Text(localizations.select),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectingDownloadSchema(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen:
          (previous, current) =>
              previous.downloadSchema != current.downloadSchema,
      builder: (context, state) {
        final schemaInfo = _getSchemaDisplayInfo(
          state.downloadSchema,
          localizations,
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.downloadSchema,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        schemaInfo['title'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schemaInfo['example'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final result = await _showSchemaSelectionDialog(
                      context,
                      localizations,
                    );
                    if (result != null) {
                      // ignore: use_build_context_synchronously
                      context.read<SettingsBloc>().add(
                        SetDownloadSchema(result),
                      );

                      // ignore: use_build_context_synchronously
                      context.showSnackBar(
                        localizations.schemaWasSelectedSuccessfully,
                        isError: false,
                      );
                    }
                  },
                  child: Text(localizations.select),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, String> _getSchemaDisplayInfo(
    DownloadSchema schema,
    AppLocalizations localizations,
  ) {
    switch (schema) {
      case DownloadSchema.flat:
        return {'title': localizations.schemaFlat, 'example': '/book1.epub'};
      case DownloadSchema.authorOnly:
        return {
          'title': localizations.schemaAuthorOnly,
          'example': '/author/book1.epub',
        };
      case DownloadSchema.authorBook:
        return {
          'title': localizations.schemaAuthorBook,
          'example': '/author/book1/book1.epub',
        };
      case DownloadSchema.authorSeriesBook:
        return {
          'title': localizations.schemaAuthorSeriesBook,
          'example': '/author/series/book1/book1.epub',
        };
    }
  }

  Future<DownloadSchema?> _showSchemaSelectionDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    return showDialog<DownloadSchema>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.selectDownloadSchema),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSchemaOption(
                  context,
                  DownloadSchema.flat,
                  localizations.schemaFlat,
                  '/book1.epub',
                ),
                _buildSchemaOption(
                  context,
                  DownloadSchema.authorOnly,
                  localizations.schemaAuthorOnly,
                  '/author/book1.epub',
                ),
                _buildSchemaOption(
                  context,
                  DownloadSchema.authorBook,
                  localizations.schemaAuthorBook,
                  '/author/book1/book1.epub',
                ),
                _buildSchemaOption(
                  context,
                  DownloadSchema.authorSeriesBook,
                  localizations.schemaAuthorSeriesBook,
                  '/author/series/book1/book1.epub',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(localizations.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSchemaOption(
    BuildContext context,
    DownloadSchema schema,
    String title,
    String example,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8.0),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(schema);
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    example,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
