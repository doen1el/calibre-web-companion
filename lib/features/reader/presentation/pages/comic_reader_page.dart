import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:calibre_web_companion/features/reader/presentation/widgets/page_reader_chrome.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComicReaderPage extends StatefulWidget {
  final Uint8List bytes;
  final String title;
  final int initialPage;
  final void Function(int page, int pageCount) onPageChanged;

  const ComicReaderPage({
    super.key,
    required this.bytes,
    required this.title,
    required this.initialPage,
    required this.onPageChanged,
  });

  static const String rightToLeftKey = 'comic_reader_rtl';

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
  };

  static List<ArchiveFile> imagePages(Archive archive) {
    final pages =
        archive.files.where((file) {
          if (!file.isFile) return false;
          final name = file.name;
          final base = name.split('/').last;
          if (base.startsWith('.') || name.startsWith('__MACOSX')) return false;
          final dot = base.lastIndexOf('.');
          return dot > 0 &&
              _imageExtensions.contains(base.substring(dot + 1).toLowerCase());
        }).toList();
    pages.sort((a, b) => naturalCompare(a.name, b.name));
    return pages;
  }

  // Page files are rarely zero-padded, so "10.jpg" must sort after "9.jpg".
  static int naturalCompare(String a, String b) {
    final chunk = RegExp(r'(\d+)|(\D+)');
    final aParts = chunk.allMatches(a.toLowerCase()).toList();
    final bParts = chunk.allMatches(b.toLowerCase()).toList();
    for (var i = 0; i < aParts.length && i < bParts.length; i++) {
      final aPart = aParts[i].group(0)!;
      final bPart = bParts[i].group(0)!;
      final aNum = int.tryParse(aPart);
      final bNum = int.tryParse(bPart);
      final result =
          aNum != null && bNum != null
              ? aNum.compareTo(bNum)
              : aPart.compareTo(bPart);
      if (result != 0) return result;
    }
    return aParts.length.compareTo(bParts.length);
  }

  @override
  State<ComicReaderPage> createState() => _ComicReaderPageState();
}

class _ComicReaderPageState extends State<ComicReaderPage> {
  late final PageController _pageController;
  late final List<ArchiveFile> _pages;
  final Map<int, Uint8List> _decoded = {};
  late int _page;
  bool _chromeVisible = true;
  bool _zoomed = false;
  bool _rightToLeft = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    try {
      _pages = ComicReaderPage.imagePages(
        ZipDecoder().decodeBytes(widget.bytes),
      );
    } catch (e) {
      _pages = const [];
      _error = e;
    }
    _page = _pages.isEmpty ? 0 : widget.initialPage.clamp(0, _pages.length - 1);
    _pageController = PageController(initialPage: _page);
    _loadDirection();
    if (_pages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onPageChanged(_page, _pages.length),
      );
    }
  }

  Future<void> _loadDirection() async {
    final prefs = await SharedPreferences.getInstance();
    final rtl = prefs.getBool(ComicReaderPage.rightToLeftKey) ?? false;
    if (mounted && rtl != _rightToLeft) setState(() => _rightToLeft = rtl);
  }

  Future<void> _toggleDirection() async {
    setState(() => _rightToLeft = !_rightToLeft);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ComicReaderPage.rightToLeftKey, _rightToLeft);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Uint8List _bytesFor(int index) {
    final cached = _decoded[index];
    if (cached != null) return cached;

    // Only neighbours stay decoded; a long comic would not fit otherwise.
    _decoded.removeWhere((key, _) => (key - index).abs() > 2);
    final content = _pages[index].content;
    final bytes =
        content is Uint8List
            ? content
            : Uint8List.fromList(List<int>.from(content as List));
    return _decoded[index] = bytes;
  }

  void _goTo(int page) {
    if (_pages.isEmpty) return;
    _pageController.jumpToPage(page.clamp(0, _pages.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PageReaderChrome(
      title: widget.title,
      page: _page,
      pageCount: _pages.length,
      visible: _chromeVisible || _pages.isEmpty,
      reverseTapZones: _rightToLeft,
      onSeek: _goTo,
      onPrevious: () => _goTo(_page - 1),
      onNext: () => _goTo(_page + 1),
      onToggleChrome: () => setState(() => _chromeVisible = !_chromeVisible),
      actions: [
        IconButton(
          tooltip: localizations.comicReadingDirection,
          icon: Icon(
            _rightToLeft
                ? Icons.format_textdirection_r_to_l
                : Icons.format_textdirection_l_to_r,
          ),
          onPressed: _toggleDirection,
        ),
      ],
      child:
          _pages.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error != null
                        ? '${localizations.errorOpeningBookInInternalReader} $_error'
                        : localizations.comicHasNoPages,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              )
              : PageView.builder(
                controller: _pageController,
                reverse: _rightToLeft,
                physics:
                    _zoomed
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                itemCount: _pages.length,
                onPageChanged: (page) {
                  setState(() {
                    _page = page;
                    _zoomed = false;
                  });
                  widget.onPageChanged(page, _pages.length);
                },
                itemBuilder:
                    (context, index) => _ComicPage(
                      bytes: _bytesFor(index),
                      onZoomChanged: (zoomed) {
                        if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                      },
                    ),
              ),
    );
  }
}

class _ComicPage extends StatefulWidget {
  final Uint8List bytes;
  final ValueChanged<bool> onZoomChanged;

  const _ComicPage({required this.bytes, required this.onZoomChanged});

  @override
  State<_ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<_ComicPage> {
  final TransformationController _transformation = TransformationController();

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _reportZoom() {
    widget.onZoomChanged(_transformation.value.getMaxScaleOnAxis() > 1.01);
  }

  void _toggleZoom(TapDownDetails details) {
    if (_transformation.value.getMaxScaleOnAxis() > 1.01) {
      _transformation.value = Matrix4.identity();
    } else {
      const scale = 2.5;
      final position = details.localPosition;
      _transformation.value =
          Matrix4.identity()
            ..translateByDouble(
              -position.dx * (scale - 1),
              -position.dy * (scale - 1),
              0,
              1,
            )
            ..scaleByDouble(scale, scale, 1, 1);
    }
    _reportZoom();
  }

  @override
  Widget build(BuildContext context) {
    TapDownDetails? doubleTapDetails;
    return GestureDetector(
      onDoubleTapDown: (details) => doubleTapDetails = details,
      onDoubleTap: () {
        final details = doubleTapDetails;
        if (details != null) _toggleZoom(details);
      },
      child: InteractiveViewer(
        transformationController: _transformation,
        maxScale: 5,
        onInteractionEnd: (_) => _reportZoom(),
        child: SizedBox.expand(
          child: Image.memory(
            widget.bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder:
                (_, _, _) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
          ),
        ),
      ),
    );
  }
}
