import 'dart:ffi';

import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/view_models/book_details_view_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

enum DownloadStatus {
  loading,
  slectinDestination,
  downloading,
  success,
  failed,
}

class CancellationToken {
  bool _isCancelled = false;

  /// Cancel the operation associated with this token
  void cancel() {
    _isCancelled = true;
  }

  /// Check if the token has been cancelled
  bool get isCancelled => _isCancelled;
}

/// An exception thrown when an operation is cancelled
class CancellationException implements Exception {
  final String message;

  CancellationException(this.message);

  @override
  String toString() => message;
}

class DownloadToDevice extends StatefulWidget {
  final BookItem book;
  const DownloadToDevice({super.key, required this.book});

  @override
  DownloadToDeviceState createState() => DownloadToDeviceState();
}

class DownloadToDeviceState extends State<DownloadToDevice> {
  var logger = Logger();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookDetailsViewModel>();

    return IconButton(
      onPressed: () => _showDownloadOptions(context, viewModel, widget.book),
      icon: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: const Icon(Icons.download_rounded),
      ),
      tooltip: "Download to device",
    );
  }

  /// Shows download options for a book
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [viewModel]: The view model for the book details
  /// - [book]: The book item to download
  void _showDownloadOptions(
    BuildContext context,
    BookDetailsViewModel viewModel,
    BookItem book,
  ) {
    try {
      if (book.formats.length == 1) {
        // If only one format is available, download it directly
        _downloadBook(context, viewModel, book, book.formats[0]);
        return;
      } else if (book.formats.isEmpty) {
        // If no formats are available, try epub
        _downloadBook(context, viewModel, book, 'epub');
        return;
      }
    } catch (e) {
      // Show snackbar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading ${book.title}: $e')),
      );
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
                  title: const Text('Download Format'),
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
                      _downloadBook(context, viewModel, book, format);
                    },
                  );
                }),
              ],
            ),
          ),
    );
  }

  /// Downloads a book to the device
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [viewModel]: The view model for the book details
  /// - [book]: The book item to download
  /// - [format]: The format of the book to download
  void _downloadBook(
    BuildContext context,
    BookDetailsViewModel viewModel,
    BookItem book,
    String format,
  ) async {
    // Create transfer status notifier
    final downloadStatus = ValueNotifier<DownloadStatus>(
      DownloadStatus.loading,
    );

    String? errorMessage;

    final cancelToken = CancellationToken();

    _showDownloadStatusSheet(context, downloadStatus, errorMessage, () {
      cancelToken.cancel();
    });

    downloadStatus.value = DownloadStatus.slectinDestination;

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      logger.i('Download cancelled: No directory selected');
    }

    try {
      logger.i("Starting download process");

      downloadStatus.value = DownloadStatus.downloading;

      if (cancelToken.isCancelled == true) {
        throw CancellationException('Operation cancelled');
      }

      // Download ebook
      final response = await viewModel.downloadBook(
        book.id,
        book.title,
        selectedDirectory!,
        format: format,
      );
      if (!response) {
        throw Exception('Failed to download ebook');
      }

      logger.i('Downloaded ebook: ${book.title}.epub to $selectedDirectory');

      downloadStatus.value = DownloadStatus.success;
    } catch (e) {
      if (e is! CancellationException) {
        logger.e('Error downloading book: $e');
      }

      errorMessage = e.toString();

      downloadStatus.value = DownloadStatus.failed;
    }
  }
}

/// Show the download status sheet
///
/// Parameters:
///
/// - `context`: The current build context
/// - `status`: The download status notifier
/// - `errorMessage`: The error message to display
void _showDownloadStatusSheet(
  BuildContext context,
  ValueNotifier<DownloadStatus> status,
  String? errorMessage,
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
        child: ValueListenableBuilder<DownloadStatus>(
          valueListenable: status,
          builder: (context, currentStatus, _) {
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
                      _getStatusMessage(currentStatus),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Error message if available
                    if (errorMessage != null &&
                        currentStatus == DownloadStatus.failed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage,
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
                    if (currentStatus == DownloadStatus.slectinDestination ||
                        currentStatus == DownloadStatus.downloading)
                      LinearProgressIndicator(
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),

                    const SizedBox(height: 20),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Material(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.0),
                          onTap: () {
                            // If operation is in progress, call cancellation
                            if (currentStatus == DownloadStatus.loading ||
                                currentStatus ==
                                    DownloadStatus.slectinDestination ||
                                currentStatus == DownloadStatus.downloading) {
                              if (onCancel != null) onCancel();
                            }

                            // Close the sheet
                            Navigator.of(context).pop();
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
                                  currentStatus == DownloadStatus.success ||
                                          currentStatus == DownloadStatus.failed
                                      ? Icons.close
                                      : Icons.cancel_rounded,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  currentStatus == DownloadStatus.success ||
                                          currentStatus == DownloadStatus.failed
                                      ? "Close"
                                      : "Cancel",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
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

/// Build the status icon based on the current status
/// Parameters:
///
/// - `status`: The current download status
Widget _buildStatusIcon(DownloadStatus status) {
  switch (status) {
    case DownloadStatus.loading:
      return const CircularProgressIndicator();
    case DownloadStatus.slectinDestination:
      return const Icon(Icons.folder_open_rounded, size: 48);
    case DownloadStatus.downloading:
      return const Icon(Icons.download_rounded, size: 48);
    case DownloadStatus.success:
      return const Icon(Icons.check_circle, size: 48);
    case DownloadStatus.failed:
      return const Icon(Icons.error_outline, size: 48);
  }
}

/// Get the status message based on the current status
///
/// Parameters:
///
/// - `status`: The current download status
String _getStatusMessage(DownloadStatus status) {
  switch (status) {
    case DownloadStatus.loading:
      return "Preparing download...";
    case DownloadStatus.slectinDestination:
      return "Select download destination...";
    case DownloadStatus.downloading:
      return "Downloading book...";
    case DownloadStatus.success:
      return "Successfully downloaded book";
    case DownloadStatus.failed:
      return "Download failed";
  }
}
