import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/data/models/download_schema.dart';

class DownloadToDeviceWidget extends StatelessWidget {
  final BookDetailsModel book;
  final bool isLoading;

  const DownloadToDeviceWidget({
    super.key,
    required this.book,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<BookDetailsBloc, BookDetailsState>(
      buildWhen:
          (previous, current) =>
              previous.downloadState != current.downloadState ||
              previous.downloadProgress != current.downloadProgress,
      builder: (context, state) {
        return IconButton(
          icon: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child:
                state.downloadState == DownloadState.downloading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        value:
                            state.downloadProgress > 0
                                ? state.downloadProgress / 100
                                : null,
                      ),
                    )
                    : const Icon(Icons.download_rounded),
          ),
          onPressed:
              isLoading || state.downloadState == DownloadState.downloading
                  ? null
                  : () => _showDownloadOptions(context, localizations, book),
          tooltip: localizations.downloadToDevice,
        );
      },
    );
  }

  /// Shows download options for a book
  void _showDownloadOptions(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsModel book,
  ) {
    // If only one format is available, start download directly
    if (book.formats.length == 1) {
      _downloadBook(
        context,
        localizations,
        book,
        book.formats.first.toLowerCase(),
      );
      return;
    }

    // Show modal bottom sheet with download options
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(localizations.downlaodFomat),
                  leading: const Icon(Icons.download),
                ),
                const Divider(),
                ...book.formats.map((format) {
                  IconData icon;
                  switch (format.toLowerCase()) {
                    case 'epub':
                      icon = Icons.menu_book;
                      break;
                    case 'pdf':
                      icon = Icons.picture_as_pdf;
                      break;
                    case 'mobi':
                      icon = Icons.book_online;
                      break;
                    default:
                      icon = Icons.file_present;
                  }

                  return ListTile(
                    leading: Icon(icon),
                    title: Text(format.toUpperCase()),
                    onTap: () {
                      Navigator.pop(context);
                      _downloadBook(context, localizations, book, format);
                    },
                  );
                }),
              ],
            ),
          ),
    );
  }

  /// Downloads a book to the device
  void _downloadBook(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsModel book,
    String format,
  ) async {
    final settingsState = context.read<SettingsBloc>().state;
    String? selectedDirectory;

    // Check if we need to select a directory or use the default
    if (settingsState.defaultDownloadPath.isEmpty) {
      if (!await _checkAndRequestPermissions()) {
        // ignore: use_build_context_synchronously
        context.showSnackBar(
          localizations.storagePermissionRequiredToSelectAFolder,
          isError: true,
        );
        return;
      }

      // Show download status dialog with "selecting destination" state
      _showDownloadStatusSheet(
        // ignore: use_build_context_synchronously
        context,
        localizations,
        DownloadState.selectingDestination,
        null,
        0,
        () {
          // Cancel operation - just close the dialog
          Navigator.pop(context);
        },
      );

      selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        // User cancelled directory selection
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Close the status dialog
        return;
      }
    } else {
      selectedDirectory = settingsState.defaultDownloadPath;

      // Show download status dialog immediately with "downloading" state
      _showDownloadStatusSheet(
        context,
        localizations,
        DownloadState.downloading,
        null,
        0,
        () {
          // Cancel the download
          context.read<BookDetailsBloc>().add(CancelDownload());
          Navigator.pop(context);
        },
      );
    }

    // Start the download process
    // ignore: use_build_context_synchronously
    context.read<BookDetailsBloc>().add(
      DownloadBook(
        bookId: book.id.toString(),
        format: format,
        title: book.title,
        author: book.authors,
        series: book.series,
        seriesIndex: book.seriesIndex,
        directory: selectedDirectory,
        schema: settingsState.downloadSchema,
      ),
    );
  }

  /// Check and request storage permissions
  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return true;
    }
    return true;
  }

  /// Show the download status sheet
  void _showDownloadStatusSheet(
    BuildContext context,
    AppLocalizations localizations,
    DownloadState initialStatus,
    String? errorMessage,
    int initialProgress,
    VoidCallback? onCancel,
  ) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: BlocConsumer<BookDetailsBloc, BookDetailsState>(
            listenWhen:
                (previous, current) =>
                    previous.downloadState != current.downloadState ||
                    previous.downloadErrorMessage !=
                        current.downloadErrorMessage,
            listener: (context, state) {
              // When download completes or fails, we can allow closing the sheet
              if (state.downloadState == DownloadState.success ||
                  state.downloadState == DownloadState.failed) {
                // Could add auto-close with delay here if desired
              }
            },
            buildWhen:
                (previous, current) =>
                    previous.downloadState != current.downloadState ||
                    previous.downloadProgress != current.downloadProgress ||
                    previous.downloadErrorMessage !=
                        current.downloadErrorMessage,
            builder: (context, state) {
              // Fallback to initial values if the state doesn't have updated values yet
              final currentStatus =
                  state.downloadState != DownloadState.initial
                      ? state.downloadState
                      : initialStatus;
              final currentError =
                  state.downloadErrorMessage?.isNotEmpty == true
                      ? state.downloadErrorMessage
                      : errorMessage;
              final currentProgress =
                  state.downloadState == DownloadState.downloading
                      ? state.downloadProgress
                      : initialProgress;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status icon
                      _buildStatusIcon(currentStatus),
                      const SizedBox(height: 20),

                      // Status text
                      Text(
                        _getStatusMessage(currentStatus, localizations),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Error message if available
                      if (currentError != null &&
                          currentStatus == DownloadState.failed)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            currentError,
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Progress indicator for loading states
                      if (currentStatus == DownloadState.selectingDestination)
                        LinearProgressIndicator(
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),

                      // Progress indicator with percentage for downloading
                      if (currentStatus == DownloadState.downloading)
                        Column(
                          children: [
                            LinearProgressIndicator(
                              backgroundColor: Colors.grey[200],
                              value:
                                  currentProgress > 0
                                      ? currentProgress / 100
                                      : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$currentProgress%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Material(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.0),
                            onTap: () {
                              // If operation is in progress, call cancellation
                              if (currentStatus == DownloadState.initial ||
                                  currentStatus ==
                                      DownloadState.selectingDestination ||
                                  currentStatus == DownloadState.downloading) {
                                if (onCancel != null) onCancel();
                              } else {
                                // Just close the sheet
                                Navigator.of(context).pop();
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    currentStatus == DownloadState.success ||
                                            currentStatus ==
                                                DownloadState.failed
                                        ? Icons.close
                                        : Icons.cancel_rounded,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    currentStatus == DownloadState.success ||
                                            currentStatus ==
                                                DownloadState.failed
                                        ? localizations.close
                                        : localizations.cancel,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Build the status icon based on the current status
Widget _buildStatusIcon(DownloadState status) {
  switch (status) {
    case DownloadState.initial:
      return const CircularProgressIndicator();
    case DownloadState.selectingDestination:
      return const Icon(Icons.folder_open_rounded, size: 48);
    case DownloadState.downloading:
      return const Icon(Icons.download_rounded, size: 48);
    case DownloadState.success:
      return const Icon(Icons.check_circle, size: 48, color: Colors.green);
    case DownloadState.failed:
      return const Icon(Icons.error_outline, size: 48, color: Colors.red);
    case DownloadState.canceled:
      return const Icon(Icons.cancel_outlined, size: 48, color: Colors.orange);
  }
}

/// Get the status message based on the current status
String _getStatusMessage(DownloadState status, AppLocalizations localizations) {
  switch (status) {
    case DownloadState.initial:
      return localizations.preparingDownload;
    case DownloadState.selectingDestination:
      return localizations.selectDownloadDestination;
    case DownloadState.downloading:
      return localizations.downloadingBook;
    case DownloadState.success:
      return localizations.successfullyDownloadedBook;
    case DownloadState.failed:
      return localizations.downloadFailed;
    case DownloadState.canceled:
      return localizations.downloadCancelled;
  }
}
