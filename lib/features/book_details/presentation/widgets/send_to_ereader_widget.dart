import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';

enum SendMethod { browser, email }

class SendToEreaderWidget extends StatelessWidget {
  final BookDetailsModel book;
  final bool isLoading;

  const SendToEreaderWidget({
    super.key,
    required this.book,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return FloatingActionButton.extended(
          onPressed:
              isLoading
                  ? null
                  : () => _showSendToReaderDialog(context, localizations),
          icon: const Icon(Icons.send),
          label: Text(localizations.sendToEReader),
        );
      },
    );
  }

  /// Show the dialog to send the book to the e-reader
  void _showSendToReaderDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final TextEditingController codeController = TextEditingController();
    bool isKindle = false;
    SendMethod sendMethod = SendMethod.browser;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(localizations.sendToKindleKobo),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Send method toggle (Browser vs Email)
                        _buildSendMethodToggle(context, sendMethod, (method) {
                          setState(() => sendMethod = method);
                        }),
                        const SizedBox(height: 16),

                        // Browser-specific options
                        if (sendMethod == SendMethod.browser) ...[
                          _buildEReaderTypeToggle(context, isKindle, (kindle) {
                            setState(() => isKindle = kindle);
                          }),
                          const SizedBox(height: 16),
                          _buildCodeInput(
                            context,
                            localizations,
                            codeController,
                          ),
                        ],

                        // Email-specific options
                        if (sendMethod == SendMethod.email) ...[
                          _buildEmailInfo(context, localizations),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations.cancel),
                    ),
                    ElevatedButton(
                      onPressed:
                          () => _handleSendAction(
                            context,
                            localizations,
                            sendMethod,
                            codeController,
                            isKindle,
                          ),
                      child: Text(localizations.send),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildSendMethodToggle(
    BuildContext context,
    SendMethod sendMethod,
    ValueChanged<SendMethod> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Browser option
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(SendMethod.browser),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      sendMethod == SendMethod.browser
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Browser',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        sendMethod == SendMethod.browser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          // Email option
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(SendMethod.email),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      sendMethod == SendMethod.email
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        sendMethod == SendMethod.email
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEReaderTypeToggle(
    BuildContext context,
    bool isKindle,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Kobo option
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      !isKindle
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Kobo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        !isKindle
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          // Kindle option
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isKindle
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Kindle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isKindle
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput(
    BuildContext context,
    AppLocalizations localizations,
    TextEditingController codeController,
  ) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Column(
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
                    text: ' ${settingsState.send2ereaderUrl} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: localizations.onYourEReader),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmailInfo(BuildContext context, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.bookWillBeSendToYourEmailAdress,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            localizations.makeSureEmailSettingsAreConfigured,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendAction(
    BuildContext context,
    AppLocalizations localizations,
    SendMethod sendMethod,
    TextEditingController codeController,
    bool isKindle,
  ) {
    if (sendMethod == SendMethod.browser) {
      final code = codeController.text.trim().toUpperCase();
      if (code.length != 4) {
        context.showSnackBar(
          localizations.pleaseEnter4DigitCode,
          isError: true,
        );
        return;
      }

      Navigator.pop(context);
      _sendToEReaderViaBrowser(context, localizations, code, isKindle);
    } else {
      Navigator.pop(context);
      _sendToEReaderByEmail(context, localizations);
    }
  }

  void _sendToEReaderViaBrowser(
    BuildContext context,
    AppLocalizations localizations,
    String code,
    bool isKindle,
  ) {
    // Show transfer status dialog
    _showTransferStatusDialog(context, localizations);

    // Trigger the send event
    context.read<BookDetailsBloc>().add(
      SendToEReaderViaBrowser(
        bookId: book.id.toString(),
        code: code,
        isKindle: isKindle,
        title: book.title,
      ),
    );
  }

  void _sendToEReaderByEmail(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    // Show transfer status dialog
    _showTransferStatusDialog(context, localizations);

    // Trigger the send event
    context.read<BookDetailsBloc>().add(
      SendToEReaderByEmail(bookId: book.id.toString(), format: 'epub'),
    );
  }

  void _showTransferStatusDialog(
    BuildContext context,
    AppLocalizations localizations,
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
                    previous.sendToEReaderState != current.sendToEReaderState,
            listener: (context, state) {
              if (state.sendToEReaderState == SendToEReaderState.success) {
                context.showSnackBar(
                  localizations.successfullySentToEReader,
                  isError: false,
                );
              } else if (state.sendToEReaderState == SendToEReaderState.error) {
                context.showSnackBar(
                  state.errorMessage ?? localizations.transferFailed,
                  isError: true,
                );
              }
            },
            buildWhen:
                (previous, current) =>
                    previous.sendToEReaderState != current.sendToEReaderState ||
                    previous.sendToEReaderProgress !=
                        current.sendToEReaderProgress,
            builder: (context, state) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status icon
                      _buildStatusIcon(state.sendToEReaderState),
                      const SizedBox(height: 20),

                      // Status text
                      Text(
                        _getStatusMessage(
                          state.sendToEReaderState,
                          localizations,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Error message if available
                      if (state.errorMessage != null &&
                          state.sendToEReaderState == SendToEReaderState.error)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.errorMessage!,
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
                      if (state.sendToEReaderState ==
                              SendToEReaderState.loading ||
                          state.sendToEReaderState ==
                              SendToEReaderState.downloading ||
                          state.sendToEReaderState ==
                              SendToEReaderState.uploading)
                        LinearProgressIndicator(
                          backgroundColor: Colors.grey[200],
                          value:
                              state.sendToEReaderProgress > 0
                                  ? state.sendToEReaderProgress / 100
                                  : null,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Close/Cancel button
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
                              // Cancel if in progress
                              if (state.sendToEReaderState ==
                                      SendToEReaderState.loading ||
                                  state.sendToEReaderState ==
                                      SendToEReaderState.downloading ||
                                  state.sendToEReaderState ==
                                      SendToEReaderState.uploading) {
                                context.read<BookDetailsBloc>().add(
                                  CancelSendToEReader(),
                                );
                              }
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
                                    state.sendToEReaderState ==
                                                SendToEReaderState.success ||
                                            state.sendToEReaderState ==
                                                SendToEReaderState.error
                                        ? Icons.close
                                        : Icons.cancel_rounded,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    state.sendToEReaderState ==
                                                SendToEReaderState.success ||
                                            state.sendToEReaderState ==
                                                SendToEReaderState.error
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

  Widget _buildStatusIcon(SendToEReaderState state) {
    switch (state) {
      case SendToEReaderState.initial:
      case SendToEReaderState.loading:
        return const CircularProgressIndicator();
      case SendToEReaderState.downloading:
        return const Icon(Icons.download_rounded, size: 48);
      case SendToEReaderState.uploading:
        return const Icon(Icons.upload_rounded, size: 48);
      case SendToEReaderState.success:
        return const Icon(Icons.check_circle, size: 48, color: Colors.green);
      case SendToEReaderState.error:
        return const Icon(Icons.error_outline, size: 48, color: Colors.red);
      case SendToEReaderState.cancelled:
        return const Icon(
          Icons.cancel_outlined,
          size: 48,
          color: Colors.orange,
        );
    }
  }

  String _getStatusMessage(
    SendToEReaderState state,
    AppLocalizations localizations,
  ) {
    switch (state) {
      case SendToEReaderState.initial:
      case SendToEReaderState.loading:
        return localizations.preparingTransfer;
      case SendToEReaderState.downloading:
        return localizations.downloadingBook;
      case SendToEReaderState.uploading:
        return localizations.sendToEReader;
      case SendToEReaderState.success:
        return localizations.successfullySentToEReader;
      case SendToEReaderState.error:
        return localizations.transferFailed;
      case SendToEReaderState.cancelled:
        return localizations.transferCancelled;
    }
  }
}
