import 'dart:io';
import 'package:epub_view/epub_view.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';

class EbookReaderWidget extends StatefulWidget {
  final String bookPath;
  final BookDetailsModel bookDetailsModel;

  const EbookReaderWidget({
    super.key,
    required this.bookPath,
    required this.bookDetailsModel,
  });

  @override
  State<EbookReaderWidget> createState() => _EbookReaderWidgetState();
}

class _EbookReaderWidgetState extends State<EbookReaderWidget> {
  EpubController? _epubController;
  String? _lastLocation;

  @override
  void initState() {
    super.initState();
    _initializeReader();
  }

  Future<void> _initializeReader() async {
    final prefs = await SharedPreferences.getInstance();
    _lastLocation = prefs.getString(
      'epub_location_${widget.bookDetailsModel.uuid}',
    );

    _epubController = EpubController(
      document: EpubDocument.openFile(File(widget.bookPath)),
      epubCfi: _lastLocation,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveLastPosition() async {
    if (_epubController != null) {
      final cfi = _epubController!.generateEpubCfi();
      if (cfi != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'epub_location_${widget.bookDetailsModel.uuid}',
          cfi,
        );
      }
    }
  }

  @override
  void dispose() {
    _saveLastPosition();
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_epubController == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.bookDetailsModel.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: EpubViewActualChapter(
          controller: _epubController!,
          builder:
              (chapterValue) => Text(
                chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ??
                    widget.bookDetailsModel.title,
                textAlign: TextAlign.start,
              ),
        ),
      ),
      drawer: Drawer(
        child: EpubViewTableOfContents(controller: _epubController!),
      ),
      body: EpubView(
        controller: _epubController!,
        onDocumentLoaded: (document) {
          if (_lastLocation != null) {
            _epubController!.gotoEpubCfi(_lastLocation!);
          }
        },
        onDocumentError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error while loading the book: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onChapterChanged: (value) {
          _saveLastPosition();
        },
      ),
    );
  }
}
