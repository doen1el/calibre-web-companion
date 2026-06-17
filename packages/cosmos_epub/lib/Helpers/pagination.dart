import 'package:cosmos_epub/Component/highlight_toolbar.dart';
import 'package:cosmos_epub/Helpers/epub_content_parser.dart';
import 'package:cosmos_epub/Helpers/html_paginator.dart';
import 'package:cosmos_epub/Helpers/html_text_builder.dart';
import 'package:cosmos_epub/Model/highlight_model.dart';
import 'package:cosmos_epub/PageFlip/builders/builder.dart' as flip_cache;
import 'package:cosmos_epub/PageFlip/page_flip_widget.dart';
import 'package:cosmos_epub/Helpers/functions.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Soft hyphen — Flutter's native Text/RichText breaks lines here.
// flutter_html strips these, so we use HtmlTextBuilder (native RichText) instead.
const _shyChar = '\u00AD';
const _vowels = 'aeiouyAEIOUYаеёиоуыэюяАЕЁИОУЫЭЮЯ';

// Uzbek digraphs that must never be split
const _uzDigraphs = ['ch', 'sh', "g'", "o'", "gʻ", "oʻ",
                      'Ch', 'Sh', "G'", "O'", "Gʻ", "Oʻ",
                      'CH', 'SH'];

bool _isVowel(String c) => _vowels.contains(c);
/// Get the length of digraph starting at position i, or 1 if not a digraph.
int _charLen(String word, int i) {
  for (final dg in _uzDigraphs) {
    if (i + dg.length <= word.length && word.substring(i, i + dg.length) == dg) {
      return dg.length;
    }
  }
  return 1;
}

/// Inserts soft hyphens into words for better justified text line-breaking.
/// Respects Uzbek digraphs (ch, sh, ng, g', o') — never breaks them apart.
/// Uses - as visible hyphen at break points via Unicode soft hyphen (\u00AD).
String _hyphenateWord(String word) {
  if (word.length < 5) return word;

  // First, tokenize into logical characters (digraphs count as one)
  final tokens = <String>[];
  int i = 0;
  while (i < word.length) {
    final len = _charLen(word, i);
    tokens.add(word.substring(i, i + len));
    i += len;
  }

  if (tokens.length < 4) return word;

  // Classify each token as vowel or consonant
  // For digraphs: o' is vowel, g' is consonant, ch/sh/ng are consonant
  bool tokenIsVowel(String t) {
    if (t == "o'" || t == "oʻ" || t == "O'" || t == "Oʻ") return true;
    if (t.length == 1) return _isVowel(t);
    return false; // ch, sh, ng, g' are consonants
  }

  final buf = StringBuffer();
  for (int ti = 0; ti < tokens.length; ti++) {
    // Don't insert break in first 2 or last 2 tokens
    if (ti >= 2 && ti <= tokens.length - 2) {
      final prev = tokens[ti - 1];
      final cur = tokens[ti];
      final next = ti + 1 < tokens.length ? tokens[ti + 1] : '';
      final prevIsV = tokenIsVowel(prev);
      final curIsC = !tokenIsVowel(cur);
      final nextIsV = next.isNotEmpty && tokenIsVowel(next);

      // V|CV — break before single consonant between vowels
      if (prevIsV && curIsC && nextIsV) {
        buf.write(_shyChar);
      }
      // CC|CV — break between consonant cluster before vowel
      else if (!tokenIsVowel(prev) && curIsC && nextIsV) {
        buf.write(_shyChar);
      }
    }
    buf.write(tokens[ti]);
  }
  return buf.toString();
}

/// Inserts soft hyphens into text content between HTML tags.
String _hyphenateHtml(String html) {
  return html.replaceAllMapped(
    RegExp(r'>([^<]+)<'),
    (match) {
      final text = match.group(1)!;
      if (text.trim().isEmpty) return match.group(0)!;
      final hyphenated = text.replaceAllMapped(
        RegExp(r"[a-zA-Zа-яА-Яʻ']{5,}"),
        (m) => _hyphenateWord(m.group(0)!),
      );
      return '>$hyphenated<';
    },
  );
}

class PagingTextHandler {
  final Function paginate;

  PagingTextHandler({required this.paginate});
}

class PagingWidget extends StatefulWidget {
  final String htmlContent;
  final EpubContentParser? contentParser;
  final String bookId;
  final int chapterIndex;
  final String rawFontFamily;
  final Color accentColor;
  final Color backgroundColor;
  final String chapterTitle;
  final int totalChapters;
  final int starterPageIndex;
  final TextStyle style;
  final Function handlerCallback;
  final VoidCallback onTextTap;
  final Function(int, int) onPageFlip;
  final Function(int, int) onLastPage;
  final Function(int, int)? onFirstPageBack;
  final Widget? lastWidget;

  const PagingWidget({
    super.key,
    required this.htmlContent,
    this.contentParser,
    this.bookId = '',
    this.chapterIndex = 0,
    this.rawFontFamily = 'Segoe',
    this.accentColor = Colors.indigoAccent,
    this.backgroundColor = Colors.white,
    this.style = const TextStyle(
      color: Colors.black,
      fontSize: 30,
    ),
    required this.handlerCallback(PagingTextHandler handler),
    required this.onTextTap,
    required this.onPageFlip,
    required this.onLastPage,
    this.onFirstPageBack,
    this.starterPageIndex = 0,
    required this.chapterTitle,
    required this.totalChapters,
    this.lastWidget,
  });

  @override
  _PagingWidgetState createState() => _PagingWidgetState();
}

class _PagingWidgetState extends State<PagingWidget> {
  List<String> _pageHtmls = [];
  List<Widget> pages = [];
  int _currentPageIndex = 0;
  Future<void> paginateFuture = Future.value(true);
  late RenderBox _initializedRenderBox;

  final _pageKey = GlobalKey();
  final _pageController = GlobalKey<PageFlipWidgetState>();

  @override
  void initState() {
    rePaginate();
    var handler = PagingTextHandler(paginate: rePaginate);
    widget.handlerCallback(handler);
    super.initState();
  }

  rePaginate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _initializedRenderBox = context.findRenderObject() as RenderBox;
        paginateFuture = _paginate();
      });
    });
  }

  Future<void> _paginate() async {
    final pageSize = _initializedRenderBox.size;
    final textDirection = RTLHelper.getTextDirection(widget.htmlContent);

    // Resolve EPUB images to inline base64 data URIs
    String resolvedHtml = widget.htmlContent;
    if (widget.contentParser != null) {
      resolvedHtml = widget.contentParser!.resolveImagesInHtml(resolvedHtml);
    }

    // Split HTML into page-sized chunks (before hyphenation so measurement is clean)
    final paginator = HtmlPaginator(
      pageWidth: pageSize.width - 20.w,
      pageHeight: pageSize.height - 100.h,
      fontSize: widget.style.fontSize ?? 17.0,
      fontFamily: widget.rawFontFamily,
      fontPackage: 'cosmos_epub',
      textDirection: textDirection,
    );

    _pageHtmls = paginator.paginate(resolvedHtml);

    // Insert soft hyphens AFTER pagination — applied to text that goes
    // directly to native RichText (not flutter_html which strips \u00AD)
    _pageHtmls = _pageHtmls.map((h) => _hyphenateHtml(h)).toList();

    pages = _pageHtmls.map((pageHtml) {
      return _HighlightablePage(
        pageHtml: pageHtml,
        chapterTitle: widget.chapterTitle,
        style: widget.style,
        rawFontFamily: widget.rawFontFamily,
        bookId: widget.bookId,
        chapterIndex: widget.chapterIndex,
        accentColor: widget.accentColor,
        backgroundColor: widget.backgroundColor,
        onTextTap: widget.onTextTap,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: paginateFuture,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              {
                return Center(
                    child: CupertinoActivityIndicator(
                  color: Theme.of(context).primaryColor,
                  radius: 30.r,
                ));
              }
            default:
              {
                if (pages.isEmpty) {
                  return const Center(child: Text('No content'));
                }
                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: SizedBox.expand(
                            key: _pageKey,
                            child: PageFlipWidget(
                              key: _pageController,
                              initialIndex: widget.starterPageIndex != 0
                                  ? (pages.isNotEmpty &&
                                          widget.starterPageIndex < pages.length
                                      ? widget.starterPageIndex
                                      : 0)
                                  : widget.starterPageIndex,
                              onPageFlip: (pageIndex, {bool? isForward}) {
                                _currentPageIndex = pageIndex;
                                widget.onPageFlip(pageIndex, pages.length);
                                // Forward on last page → onLastPage
                                if (isForward == true &&
                                    _currentPageIndex == pages.length - 1) {
                                  widget.onLastPage(pageIndex, pages.length);
                                }
                                // Backward on first page → onFirstPage
                                if (isForward == false &&
                                    _currentPageIndex == 0) {
                                  widget.onFirstPageBack
                                      ?.call(pageIndex, pages.length);
                                }
                              },
                              backgroundColor: widget.backgroundColor,
                              lastPage: widget.lastWidget,
                              children: pages,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
          }
        });
  }
}

class _HighlightablePage extends StatefulWidget {
  final String pageHtml;
  final String chapterTitle;
  final TextStyle style;
  final String rawFontFamily;
  final String bookId;
  final int chapterIndex;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTextTap;

  const _HighlightablePage({
    required this.pageHtml,
    this.chapterTitle = '',
    required this.style,
    this.rawFontFamily = 'Segoe',
    required this.bookId,
    required this.chapterIndex,
    this.accentColor = Colors.indigoAccent,
    this.backgroundColor = Colors.white,
    required this.onTextTap,
  });

  @override
  State<_HighlightablePage> createState() => _HighlightablePageState();
}

class _HighlightablePageState extends State<_HighlightablePage> {
  final _scrollController = ScrollController();
  String _lastSelectedText = '';
  Offset? _tapDownPos;
  int _tappedParagraphStart = 0;
  int _tappedParagraphEnd = -1;
  HtmlTextBuilder? _lastBuilder;


  List<Widget> _buildContent() {
    // Build once to get the page key from accumulated block text
    final tempBuilder = HtmlTextBuilder(
      fontSize: widget.style.fontSize ?? 17.0,
      fontFamily: widget.rawFontFamily,
      fontPackage: 'cosmos_epub',
      textColor: widget.style.color ?? Colors.black,
      accentColor: widget.accentColor,
      onTextTap: widget.onTextTap,
    );
    tempBuilder.build(widget.pageHtml);
    final pageKey = HighlightModel.makeParagraphKey(tempBuilder.lastBuiltCleanText);

    // Now build with highlights loaded using that key
    final pageHighlights = widget.bookId.isNotEmpty
        ? HighlightStorage.getParagraphHighlights(
            widget.bookId, widget.chapterIndex, pageKey)
        : <HighlightModel>[];

    _lastBuilder = HtmlTextBuilder(
      fontSize: widget.style.fontSize ?? 17.0,
      fontFamily: widget.rawFontFamily,
      fontPackage: 'cosmos_epub',
      textColor: widget.style.color ?? Colors.black,
      accentColor: widget.accentColor,
      onTextTap: widget.onTextTap,
      highlights: pageHighlights,
      onParagraphTapped: (start, end) {
        _tappedParagraphStart = start;
        _tappedParagraphEnd = end;
      },
      onHighlightChanged: () {
        // Clear cached page images so flip animation shows updated highlights
        flip_cache.imageData.clear();
        if (mounted) setState(() {});
      },
    );

    return _lastBuilder!.build(widget.pageHtml);
  }

  void _addHighlight(String selectedText, Color color) {
    if (selectedText.isEmpty || widget.bookId.isEmpty) return;

    final cleanSelected = selectedText
        .replaceAll('\u00AD', '')
        .replaceAll('-\n', '')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleanSelected.isEmpty) return;

    final builtText = _lastBuilder?.lastBuiltCleanText ?? '';

    // Search within the tapped paragraph first (accurate for duplicate words)
    final searchText = cleanSelected.replaceAll('-', '');
    final searchStart = _tappedParagraphEnd > 0 ? _tappedParagraphStart : 0;
    final searchEnd = _tappedParagraphEnd > 0 ? _tappedParagraphEnd : builtText.length;
    final paragraphText = builtText.substring(
        searchStart.clamp(0, builtText.length),
        searchEnd.clamp(0, builtText.length));

    var localIdx = paragraphText.indexOf(searchText);
    var idx = localIdx != -1 ? searchStart + localIdx : -1;

    // Fallback: search full page
    if (idx == -1) {
      idx = builtText.indexOf(cleanSelected);
    }
    if (idx == -1) {
      idx = builtText.indexOf(searchText);
    }
    if (idx == -1) {
      final normalizedBuilt = builtText.replaceAll(RegExp(r'\s+'), ' ');
      final normalizedIdx = normalizedBuilt.indexOf(cleanSelected);
      if (normalizedIdx == -1) return;
      int origPos = 0, normPos = 0;
      while (normPos < normalizedIdx && origPos < builtText.length) {
        if (RegExp(r'\s').hasMatch(builtText[origPos])) {
          while (origPos < builtText.length && RegExp(r'\s').hasMatch(builtText[origPos])) origPos++;
          normPos++;
        } else {
          origPos++;
          normPos++;
        }
      }
      idx = origPos;
    }

    final pKey = HighlightModel.makeParagraphKey(builtText);

    final highlight = HighlightModel(
      id: HighlightModel.generateId(),
      bookId: widget.bookId,
      chapterIndex: widget.chapterIndex,
      paragraphKey: pKey,
      startIndex: idx,
      endIndex: idx + cleanSelected.length,
      selectedText: cleanSelected,
      colorValue: color.toARGB32(),
    );

    HighlightStorage.addOrUpdate(highlight);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Section title page — centered title, no content
    if (widget.pageHtml.isEmpty && widget.chapterTitle.isNotEmpty) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTextTap,
        child: Container(
          color: widget.backgroundColor,
          child: Center(
            child: Text(
              widget.chapterTitle,
              textAlign: TextAlign.center,
              style: (widget.style).copyWith(
                fontSize: (widget.style.fontSize ?? 17) * 1.8,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    final pageTextDirection = RTLHelper.getTextDirection(widget.pageHtml);
    final contentWidgets = _buildContent();

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _tapDownPos = e.position,
      onPointerUp: (e) {
        // Only trigger on simple taps (not drags/selections)
        if (_tapDownPos != null &&
            (e.position - _tapDownPos!).distance < 5) {
          widget.onTextTap();
        }
        _tapDownPos = null;
      },
      child: SelectionArea(
        onSelectionChanged: (content) {
          _lastSelectedText = content?.plainText ?? '';
        },
        contextMenuBuilder: (context, selectableRegionState) {
          return _PageToolbar(
            anchor: selectableRegionState.contextMenuAnchors,
            onCopy: () {
              selectableRegionState
                  .copySelection(SelectionChangedCause.toolbar);
            },
            onSelectAll: () {
              selectableRegionState
                  .selectAll(SelectionChangedCause.toolbar);
            },
            onColorSelected: (color) {
              _addHighlight(_lastSelectedText, color);
              FocusManager.instance.primaryFocus?.unfocus();
            },
          );
        },
        child: Container(
          color: widget.backgroundColor,
          child: FadingEdgeScrollView.fromSingleChildScrollView(
            gradientFractionOnEnd: 0.2,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: 40.h, top: 60.h, left: 20.w, right: 20.w),
                child: DefaultTextStyle(
                  style: widget.style.copyWith(height: 1.4),
                  child: Directionality(
                    textDirection: pageTextDirection,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: contentWidgets,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Page-level toolbar with highlight colors + copy + select all.
class _PageToolbar extends StatelessWidget {
  final TextSelectionToolbarAnchors anchor;
  final VoidCallback onCopy;
  final VoidCallback onSelectAll;
  final void Function(Color) onColorSelected;

  const _PageToolbar({
    required this.anchor,
    required this.onCopy,
    required this.onSelectAll,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveTextSelectionToolbar(
      anchors: anchor,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...highlightColors.map((color) => GestureDetector(
                    onTap: () => onColorSelected(color),
                    child: Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 1.5),
                      ),
                    ),
                  )),
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.white24,
              ),
              GestureDetector(
                onTap: onCopy,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.copy, size: 20, color: Colors.white70),
                ),
              ),
              GestureDetector(
                onTap: onSelectAll,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.select_all, size: 20, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
