import 'dart:io';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_path_template.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';
import 'package:calibre_web_companion/features/settings/presentation/widgets/download_path_template_dialog.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';
import 'package:docman/docman.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadOptionsWidget extends StatelessWidget {
  const DownloadOptionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (Platform.isAndroid) ...[
          _buildSelectingDownloadFolder(context),
          _buildSelectingDownloadSchema(context),
        ],
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  onPressed: () async {
                    String? selectedPath;

                    if (Platform.isAndroid) {
                      final DocumentFile? selectedDirectory =
                          await DocMan.pick.directory();
                      selectedPath = selectedDirectory?.uri;
                    } else {
                      selectedPath = await FilePicker.getDirectoryPath();
                    }

                    if (selectedPath == null) {
                      // ignore: use_build_context_synchronously
                      context.showSnackBar(
                        localizations.noFolderWasSelected,
                        isError: true,
                      );
                      return;
                    }

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('download_folder_path', selectedPath);

                    // ignore: use_build_context_synchronously
                    context.read<SettingsBloc>().add(
                      SetDownloadFolder(selectedPath),
                    );

                    // ignore: use_build_context_synchronously
                    context.showSnackBar(
                      localizations.folderSelectedSuccessfully,
                      isError: false,
                    );
                  },
                  child: Text(
                    localizations.select,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
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
              previous.downloadSchema != current.downloadSchema ||
              previous.downloadPathTemplate != current.downloadPathTemplate,
      builder: (context, state) {
        final schemaInfo = _getSchemaDisplayInfo(
          state.downloadSchema,
          state.downloadPathTemplate,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  onPressed: () async {
                    final result = await _showSchemaSelectionDialog(
                      context,
                      localizations,
                      state.downloadSchema,
                      state.downloadPathTemplate,
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
                  child: Text(
                    localizations.select,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
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
    String pathTemplate,
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
      case DownloadSchema.authorSortOnly:
        return {
          'title': '${localizations.schemaAuthorOnly} (Sort)',
          'example': '/author_sort/book1.epub',
        };
      case DownloadSchema.authorSortBook:
        return {
          'title': '${localizations.schemaAuthorBook} (Sort)',
          'example': '/author_sort/book1/book1.epub',
        };
      case DownloadSchema.authorSortSeriesBook:
        return {
          'title': '${localizations.schemaAuthorSeriesBook} (Sort)',
          'example': '/author_sort/series/book1/book1.epub',
        };
      case DownloadSchema.seriesOnly:
        return {
          'title': localizations.schemaSeriesOnly,
          'example': '/series/book1.epub',
        };
      case DownloadSchema.custom:
        return {
          'title': localizations.schemaCustom,
          'example': DownloadPathTemplate.preview(pathTemplate),
        };
    }
  }

  Future<DownloadSchema?> _showSchemaSelectionDialog(
    BuildContext context,
    AppLocalizations localizations,
    DownloadSchema currentSchema,
    String currentTemplate,
  ) async {
    bool useAuthorSort = [
      DownloadSchema.authorSortOnly,
      DownloadSchema.authorSortBook,
      DownloadSchema.authorSortSeriesBook,
    ].contains(currentSchema);

    return showDialog<DownloadSchema>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.selectDownloadSchema),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text(localizations.useAuthorSort),
                      subtitle: Text(
                        useAuthorSort ? 'Doe, John' : 'John Doe',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      value: useAuthorSort,
                      onChanged: (bool value) {
                        setState(() {
                          useAuthorSort = value;
                        });
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildSchemaOption(
                      context,
                      DownloadSchema.flat,
                      localizations.schemaFlat,
                      '/book1.epub',
                    ),
                    _buildSchemaOption(
                      context,
                      useAuthorSort
                          ? DownloadSchema.authorSortOnly
                          : DownloadSchema.authorOnly,
                      localizations.schemaAuthorOnly,
                      useAuthorSort
                          ? '/author_sort/book1.epub'
                          : '/author/book1.epub',
                    ),
                    _buildSchemaOption(
                      context,
                      useAuthorSort
                          ? DownloadSchema.authorSortBook
                          : DownloadSchema.authorBook,
                      localizations.schemaAuthorBook,
                      useAuthorSort
                          ? '/author_sort/book1/book1.epub'
                          : '/author/book1/book1.epub',
                    ),
                    _buildSchemaOption(
                      context,
                      useAuthorSort
                          ? DownloadSchema.authorSortSeriesBook
                          : DownloadSchema.authorSeriesBook,
                      localizations.schemaAuthorSeriesBook,
                      useAuthorSort
                          ? '/author_sort/series/book1/book1.epub'
                          : '/author/series/book1/book1.epub',
                    ),
                    _buildSchemaOption(
                      context,
                      DownloadSchema.seriesOnly,
                      localizations.schemaSeriesOnly,
                      '/series/book1.epub',
                    ),
                    _buildSchemaOption(
                      context,
                      DownloadSchema.custom,
                      localizations.schemaCustom,
                      DownloadPathTemplate.preview(currentTemplate),
                      onTap: () => _editTemplate(context, currentTemplate),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                AppDialogButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  label: localizations.cancel,
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Opens the template builder and closes the schema dialog with
  /// [DownloadSchema.custom] once a template was saved.
  Future<void> _editTemplate(
    BuildContext context,
    String currentTemplate,
  ) async {
    final navigator = Navigator.of(context);
    final settingsBloc = context.read<SettingsBloc>();

    final template = await showDialog<String>(
      context: context,
      builder:
          (_) => DownloadPathTemplateDialog(initialTemplate: currentTemplate),
    );

    if (template == null) return;

    settingsBloc.add(SetDownloadPathTemplate(template));
    navigator.pop(DownloadSchema.custom);
  }

  Widget _buildSchemaOption(
    BuildContext context,
    DownloadSchema schema,
    String title,
    String example, {
    VoidCallback? onTap,
  }) {
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
            onTap: onTap ?? () => Navigator.of(context).pop(schema),
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
