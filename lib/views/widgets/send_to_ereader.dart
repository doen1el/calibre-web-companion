import 'dart:typed_data';

import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/view_models/book_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

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

    return FloatingActionButton.extended(
      onPressed: () => _showSendToReaderDialog(context, viewModel, widget.book),
      icon: const Icon(Icons.send),
      label: const Text('Send to Reader'),
    );
  }

  void _showSendToReaderDialog(
    BuildContext context,
    BookDetailsViewModel viewModel,
    BookItem book,
  ) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Send to Kindle/Kobo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the 4-digit code displayed on your e-reader\'s browser:',
                ),
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Visit send.djazz.se on your e-reader to get a code',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final code = codeController.text.trim().toUpperCase();
                  if (code.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid 4-digit code'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  _sendToEReader(context, viewModel, book, code);
                },
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }

  Future<void> _sendToEReader(
    BuildContext context,
    BookDetailsViewModel viewModel,
    BookItem book,
    String code,
  ) async {
    // Dialog mit Fortschritt anzeigen
    final progressDialog = _showProgressDialog(context);

    try {
      // Ebook-Datei herunterladen
      final ebookBytes = await viewModel.downloadBookBytes(
        book.id,
        format: 'epub',
      );
      if (ebookBytes == null || ebookBytes.isEmpty) {
        throw Exception('Failed to download ebook');
      }

      // Datei zu send.djazz.se hochladen
      final result = await _uploadToSendDjazz(
        code,
        '${book.title}.epub',
        ebookBytes,
        isKindle: false, // TODO: Option für Kindle hinzufügen
      );

      // Fortschrittsdialog schließen
      Navigator.pop(context);

      // Erfolg oder Fehler anzeigen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result
                ? 'Successfully sent to e-reader!'
                : 'Failed to send to e-reader',
          ),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      // Fortschrittsdialog schließen
      Navigator.pop(context);

      // Fehlermeldung anzeigen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  AlertDialog _showProgressDialog(BuildContext context) {
    AlertDialog dialog = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          const Text("Sending to e-reader..."),
        ],
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => dialog,
    );

    return dialog;
  }

  Future<bool> _uploadToSendDjazz(
    String code,
    String filename,
    Uint8List fileBytes, {
    bool isKindle = false,
  }) async {
    try {
      final uri = Uri.parse('https://send.djazz.se/upload');

      // Formular mit Multipart-Request erstellen
      final request = http.MultipartRequest('POST', uri);

      // Füge den Code hinzu
      request.fields['key'] = code;

      // Füge Konvertierungsoptionen hinzu
      request.fields['kepubify'] = (!isKindle).toString();
      request.fields['kindlegen'] = isKindle.toString();

      // Füge die Datei hinzu
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: path.basename(filename),
      );
      request.files.add(multipartFile);

      // Sende die Anfrage
      final response = await request.send();

      // Überprüfe den Statuscode
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return responseBody.contains('Upload successful');
      } else {
        final responseBody = await response.stream.bytesToString();
        throw Exception('Error uploading file: $responseBody');
      }
    } catch (e) {
      print('Error uploading to send.djazz.se: $e');
      rethrow;
    }
  }
}
