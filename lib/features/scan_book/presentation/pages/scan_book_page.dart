import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/scan_flow.dart';

class ScanBookPage extends StatefulWidget {
  const ScanBookPage({super.key});

  @override
  State<ScanBookPage> createState() => _ScanBookPageState();
}

class _ScanBookPageState extends State<ScanBookPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13],
    detectionSpeed: DetectionSpeed.normal,
  );
  final Logger _logger = Logger();

  bool _handling = false;

  @override
  void initState() {
    super.initState();
    _logger.i('ScanBookPage opened');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handling) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;
    _logger.i('Barcode detected: $raw');
    _handleIsbn(raw);
  }

  Future<void> _handleIsbn(String isbn) async {
    if (_handling) return;
    setState(() => _handling = true);

    final added = await runIsbnLookupFlow(context, isbn);
    if (!mounted) return;

    if (added) {
      _logger.i('Book added — closing scanner');
      Navigator.of(context).pop(true);
    } else {
      _logger.d('Resuming scanning');
      setState(() => _handling = false);
    }
  }

  Future<void> _enterIsbnManually() async {
    if (_handling) return;
    setState(() => _handling = true);
    final isbn = await promptForIsbn(context);
    if (!mounted) return;
    if (isbn != null && isbn.isNotEmpty) {
      _handling = false;
      _handleIsbn(isbn);
    } else {
      setState(() => _handling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.scanBook),
        actions: [
          IconButton(
            tooltip: localizations.enterIsbn,
            icon: const Icon(Icons.keyboard_rounded),
            onPressed: _enterIsbnManually,
          ),
          IconButton(
            tooltip: 'Torch',
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          if (!_handling) ...[
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 260,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Text(
                localizations.pointCameraAtBarcode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
