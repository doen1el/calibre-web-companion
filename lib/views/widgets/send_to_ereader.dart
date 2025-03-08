import 'dart:typed_data';

import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/view_models/book_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum TransferStatus { loading, downloading, uploading, success, failed }

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

class SendToEreader extends StatefulWidget {
  final BookItem book;
  const SendToEreader({super.key, required this.book});

  @override
  SendToEreaderState createState() => SendToEreaderState();
}

class SendToEreaderState extends State<SendToEreader> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookDetailsViewModel>();
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return FloatingActionButton.extended(
      onPressed:
          () => _showSendToReaderDialog(
            context,
            viewModel,
            localizations,
            widget.book,
          ),
      icon: const Icon(Icons.send),
      label: Text(localizations.sendToEReader),
    );
  }

  /// Show the dialog to send the book to the e-reader
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The view model to use for downloading the book
  /// - `book`: The book to send
  void _showSendToReaderDialog(
    BuildContext context,
    BookDetailsViewModel viewModel,
    AppLocalizations localizations,
    BookItem book,
  ) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.sendToKindleKobo),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(localizations.enter4DigitCode),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'XXXX',
                    counterText: '',
                  ),
                  onChanged: (value) {
                    codeController.value = codeController.value.copyWith(
                      text: value.toUpperCase(),
                      selection: TextSelection.collapsed(offset: value.length),
                    );
                  },
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    text: localizations.visit,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).hintColor,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'send.djazz.se',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: localizations.onYourEReader),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () {
                  final code = codeController.text.trim().toUpperCase();
                  if (code.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.pleaseEnter4DigitCode),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  _sendToEReader(context, localizations, viewModel, book, code);
                },
                child: Text(localizations.send),
              ),
            ],
          ),
    );
  }

  /// Send the book to the e-reader using the provided code
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The view model to use for downloading the book
  /// - `book`: The book to send
  /// - `code`: The 4-digit code to use for the transfer
  Future<void> _sendToEReader(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsViewModel viewModel,
    BookItem book,
    String code,
  ) async {
    var logger = Logger();

    // Create transfer status notifier
    final transferStatus = ValueNotifier<TransferStatus>(
      TransferStatus.loading,
    );
    String? errorMessage;

    final cancelToken = CancellationToken();

    // Show progress dialog
    _showTransferStatusSheet(
      context,
      localizations,
      transferStatus,
      errorMessage,
      () {
        cancelToken.cancel();
      },
    );

    try {
      logger.i("Starting download process");

      transferStatus.value = TransferStatus.downloading;

      // Download ebook
      final ebookBytes = await viewModel.downloadBookBytes(
        book.id,
        format: 'epub',
      );
      if (ebookBytes == null || ebookBytes.isEmpty) {
        throw Exception('Failed to download ebook');
      }

      logger.i('Downloaded ebook: ${book.title}.epub');

      transferStatus.value = TransferStatus.uploading;

      // Upload to send.djazz.se
      final result = await _uploadToSendDjazz(
        code,
        "${book.title}.epub",
        ebookBytes,
        isKindle: false, // TODO: Add Kindle/Kobo option
      );

      transferStatus.value =
          result ? TransferStatus.success : TransferStatus.failed;
      logger.i("Set status to ${result ? 'success' : 'failed'}");
    } catch (e) {
      logger.e("Error in _sendToEReader: $e");
      errorMessage = e.toString();

      transferStatus.value = TransferStatus.failed;
    }
  }

  /// Show the transfer status sheet
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `status`: The transfer status notifier
  /// - `errorMessage`: The error message to display
  void _showTransferStatusSheet(
    BuildContext context,
    AppLocalizations localizations,
    ValueNotifier<TransferStatus> status,
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
          child: ValueListenableBuilder<TransferStatus>(
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
                        _getStatusMessage(currentStatus, localizations),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Error message if available
                      if (errorMessage != null &&
                          currentStatus == TransferStatus.failed)
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
                      if (currentStatus == TransferStatus.loading ||
                          currentStatus == TransferStatus.downloading ||
                          currentStatus == TransferStatus.uploading)
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
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.0),
                            onTap: () {
                              // If operation is in progress, call cancellation
                              if (currentStatus == TransferStatus.loading ||
                                  currentStatus == TransferStatus.downloading ||
                                  currentStatus == TransferStatus.uploading) {
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
                                    currentStatus == TransferStatus.success ||
                                            currentStatus ==
                                                TransferStatus.failed
                                        ? Icons.close
                                        : Icons.cancel_rounded,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    currentStatus == TransferStatus.success ||
                                            currentStatus ==
                                                TransferStatus.failed
                                        ? localizations.close
                                        : localizations.cancel,
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
  /// - `status`: The current transfer status
  Widget _buildStatusIcon(TransferStatus status) {
    switch (status) {
      case TransferStatus.loading:
        return const CircularProgressIndicator();
      case TransferStatus.downloading:
        return const Icon(Icons.download_rounded, size: 48);
      case TransferStatus.uploading:
        return const Icon(Icons.upload_rounded, size: 48);
      case TransferStatus.success:
        return const Icon(Icons.check_circle, size: 48);
      case TransferStatus.failed:
        return const Icon(Icons.error_outline, size: 48);
    }
  }

  /// Get the status message based on the current status
  ///
  /// Parameters:
  ///
  /// - `status`: The current transfer status
  String _getStatusMessage(
    TransferStatus status,
    AppLocalizations localizations,
  ) {
    switch (status) {
      case TransferStatus.loading:
        return localizations.preparingTransfer;
      case TransferStatus.downloading:
        return localizations.downloadingBook;
      case TransferStatus.uploading:
        return localizations.sendToEReader;
      case TransferStatus.success:
        return localizations.successfullySentToEReader;
      case TransferStatus.failed:
        return localizations.transferFailed;
    }
  }

  /// Upload the file to send.djazz.se
  ///
  /// Parameters:
  ///
  /// - `code`: The 4-digit code to use for the transfer
  /// - `filename`: The name of the file to upload
  /// - `fileBytes`: The bytes of the file to upload
  /// - `isKindle`: Whether to convert the file for Kindle
  Future<bool> _uploadToSendDjazz(
    String code,
    String filename,
    Uint8List fileBytes, {
    bool isKindle = false,
    CancellationToken? cancelToken,
  }) async {
    var logger = Logger();

    try {
      final uri = Uri.parse('https://send.djazz.se/upload');

      // Check cancellation before starting
      if (cancelToken?.isCancelled == true) {
        throw CancellationException('Operation cancelled');
      }

      logger.i('Starting upload to: $uri');
      logger.i('File size: ${(fileBytes.length / 1024).toStringAsFixed(2)} KB');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add code and conversion options
      request.fields['key'] = code;
      // TODO: Add conversion options
      // request.fields['kepubify'] = (!isKindle).toString();
      // request.fields['kindlegen'] = isKindle.toString();

      // Add the file
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: path.basename(filename),
      );
      request.files.add(multipartFile);

      // Check cancellation again before sending request
      if (cancelToken?.isCancelled == true) {
        throw CancellationException('Operation cancelled');
      }

      logger.i('Sending request with file: ${path.basename(filename)}');

      if (cancelToken?.isCancelled == true) {
        throw CancellationException('Operation cancelled');
      }

      // Send the request
      final streamedResponse = await request.send();
      logger.i('Response status: ${streamedResponse.statusCode}');

      // Get the full response body
      final responseBody = await streamedResponse.stream.bytesToString();

      if (cancelToken?.isCancelled == true) {
        throw CancellationException('Operation cancelled');
      }

      logger.i('Response body: $responseBody');

      // Check status code first
      if (streamedResponse.statusCode == 200) {
        logger.i('Upload confirmed successful');
        return true;
      } else {
        logger.e('Error status code: ${streamedResponse.statusCode}');
        throw Exception(
          'Upload failed with status: ${streamedResponse.statusCode}, Body: $responseBody',
        );
      }
    } catch (e) {
      if (e is! CancellationException) {
        logger.e('Error uploading to send.djazz.se: $e');
      }
      rethrow;
    }
  }
}
