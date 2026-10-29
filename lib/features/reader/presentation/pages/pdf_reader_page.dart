import 'dart:typed_data';

import 'package:calibre_web_companion/features/reader/presentation/widgets/page_reader_chrome.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfReaderPage extends StatefulWidget {
  final Uint8List bytes;
  final String title;
  final int initialPage;
  final void Function(int page, int pageCount) onPageChanged;

  const PdfReaderPage({
    super.key,
    required this.bytes,
    required this.title,
    required this.initialPage,
    required this.onPageChanged,
  });

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  late final PdfController _controller;
  late int _page = widget.initialPage;
  int _pageCount = 0;
  bool _chromeVisible = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(
      document: PdfDocument.openData(widget.bytes),
      initialPage: widget.initialPage + 1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (_pageCount == 0) return;
    _controller.jumpToPage(page.clamp(0, _pageCount - 1) + 1);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PageReaderChrome(
      title: widget.title,
      page: _page,
      pageCount: _pageCount,
      visible: _chromeVisible || _error != null,
      onSeek: _goTo,
      onPrevious: () => _goTo(_page - 1),
      onNext: () => _goTo(_page + 1),
      onToggleChrome: () => setState(() => _chromeVisible = !_chromeVisible),
      child:
          _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '${localizations.errorOpeningBookInInternalReader} $_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              )
              : PdfView(
                controller: _controller,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                onDocumentLoaded: (document) {
                  setState(() => _pageCount = document.pagesCount);
                  widget.onPageChanged(_page, document.pagesCount);
                },
                onDocumentError: (error) => setState(() => _error = error),
                onPageChanged: (page) {
                  setState(() => _page = page - 1);
                  if (_pageCount > 0) {
                    widget.onPageChanged(page - 1, _pageCount);
                  }
                },
              ),
    );
  }
}
