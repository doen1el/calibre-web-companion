import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/scan_flow.dart';

class ScanBookPage extends StatefulWidget {
  const ScanBookPage({super.key});

  @override
  State<ScanBookPage> createState() => _ScanBookPageState();
}

class _ScanBookPageState extends State<ScanBookPage> {
  final Logger _logger = Logger();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _logger.i('ScanBookPage opened');
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    if (_busy) return;
    setState(() => _busy = true);

    final localizations = AppLocalizations.of(context)!;
    try {
      final result = await BarcodeScanner.scan(
        options: ScanOptions(
          restrictFormat: const [BarcodeFormat.ean13],
          android: AndroidOptions(appBarTitle: localizations.scanBook),
          strings: {
            'cancel': localizations.cancel,
            'flash_on': 'Flash on',
            'flash_off': 'Flash off',
          },
        ),
      );

      if (!mounted) return;

      switch (result.type) {
        case ResultType.Barcode:
          if (result.rawContent.isNotEmpty) {
            _logger.i('Barcode detected: ${result.rawContent}');
            await _handleIsbn(result.rawContent);
            return;
          }
          break;
        case ResultType.Error:
          _logger.e('Scan error: ${result.rawContent}');
          context.showSnackBar(localizations.isbnLookupFailed, isError: true);
          break;
        case ResultType.Cancelled:
          _logger.d('Scan cancelled');
          break;
      }
      setState(() => _busy = false);
    } on PlatformException catch (e) {
      _logger.e('Scanner platform error: ${e.code}');
      if (!mounted) return;
      context.showSnackBar(
        e.code == BarcodeScanner.cameraAccessDenied
            ? localizations.cameraPermissionRequired
            : localizations.isbnLookupFailed,
        isError: true,
      );
      setState(() => _busy = false);
    }
  }

  Future<void> _handleIsbn(String isbn) async {
    final added = await runIsbnLookupFlow(context, isbn);
    if (!mounted) return;

    if (added) {
      _logger.i('Book added — closing scanner');
      Navigator.of(context).pop(true);
    } else {
      _logger.d('Back to scan launcher');
      setState(() => _busy = false);
    }
  }

  Future<void> _enterIsbnManually() async {
    if (_busy) return;
    final isbn = await promptForIsbn(context);
    if (!mounted) return;
    if (isbn != null && isbn.isNotEmpty) {
      await _handleIsbn(isbn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.scanBook),
        actions: [
          IconButton(
            tooltip: localizations.enterIsbn,
            icon: const Icon(Icons.keyboard_rounded),
            onPressed: _busy ? null : _enterIsbnManually,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                localizations.pointCameraAtBarcode,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _busy ? null : _scan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(localizations.scanBook),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy ? null : _enterIsbnManually,
                icon: const Icon(Icons.keyboard_rounded),
                label: Text(localizations.enterIsbn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
