import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';

import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';

class DownloadOptionsWidget extends StatefulWidget {
  const DownloadOptionsWidget({super.key});

  @override
  State<DownloadOptionsWidget> createState() => _DownloadOptionsWidgetState();
}

class _DownloadOptionsWidgetState extends State<DownloadOptionsWidget> {
  String? _customFolderName;
  bool _showCustomFolderField = false;
  final TextEditingController _customFolderController = TextEditingController();

  @override
  void dispose() {
    _customFolderController.dispose();
    super.dispose();
  }

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
        final savedPath = state.defaultDownloadPath;
        String displayPath = 'Downloads';
        String subfolderValue = 'default';

        if (savedPath.startsWith('downloads:')) {
          final parts = savedPath.split(':');
          if (parts.length > 1 && parts[1].isNotEmpty) {
            subfolderValue = parts[1];

            if (subfolderValue != 'default' &&
                subfolderValue != 'calibre' &&
                subfolderValue != 'books') {
              subfolderValue = 'custom';
              _customFolderName = parts[1];
              _customFolderController.text = _customFolderName ?? '';
              if (!_showCustomFolderField) {
                setState(() {
                  _showCustomFolderField = true;
                });
              }
            }

            displayPath = 'Downloads/${parts[1]}';
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.downloadFolder,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  displayPath,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Unterordner auswählen',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  value: subfolderValue,
                  onChanged: (String? newValue) async {
                    if (newValue != null) {
                      if (!await _checkAndRequestPermissions()) {
                        // ignore: use_build_context_synchronously
                        context.showSnackBar(
                          localizations
                              .storagePermissionRequiredToSelectAFolder,
                          isError: true,
                        );
                        return;
                      }

                      setState(() {
                        _showCustomFolderField = newValue == 'custom';
                        if (newValue != 'custom') {
                          _saveSelectedSubfolder(context, newValue);
                        }
                      });
                    }
                  },
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(
                            Icons.download,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text('Downloads (Standard)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'calibre',
                      child: Row(
                        children: [
                          Icon(
                            Icons.book,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text('Downloads/Calibre'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'books',
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text('Downloads/Books'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'custom',
                      child: Row(
                        children: [
                          Icon(
                            Icons.create_new_folder,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text('Benutzerdefinierter Ordner'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_showCustomFolderField) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _customFolderController,
                    decoration: InputDecoration(
                      labelText: 'Ordnername eingeben',
                      hintText: 'z.B. MeineCalibreBücher',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixText: 'Downloads/',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          final folderName =
                              _customFolderController.text.trim();
                          if (folderName.isNotEmpty) {
                            _saveSelectedSubfolder(context, folderName);
                          }
                        },
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _saveSelectedSubfolder(context, value.trim());
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveSelectedSubfolder(BuildContext context, String subfolder) {
    final newPath = 'downloads:$subfolder';

    context.read<SettingsBloc>().add(SetDownloadFolder(newPath));

    context.showSnackBar(
      AppLocalizations.of(context)!.folderSelectedSuccessfully,
      isError: false,
    );
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      final mediaStorePlugin = MediaStore();
      final sdkInt = await mediaStorePlugin.getPlatformSDKInt();

      if (sdkInt >= 29) {
        return true;
      } else {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return status.isGranted;
      }
    }
    return true;
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
