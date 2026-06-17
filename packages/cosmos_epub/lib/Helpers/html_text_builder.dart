import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

import '../Model/highlight_model.dart';
import 'soft_hyphen_text.dart';

/// Converts HTML content to Flutter widgets using native SelectableText.rich.
/// Each block element becomes a SoftHyphenParagraph with highlight support.
class HtmlTextBuilder {
  final double fontSize;
  final String? fontFamily;
  final String? fontPackage;
  final Color textColor;
  final TextAlign textAlign;
  final Color? accentColor;
  final VoidCallback? onTextTap;
  final List<HighlightModel> highlights;
  final void Function()? onHighlightChanged;
  final void Function(int paragraphStart, int paragraphEnd)? onParagraphTapped;

  /// Cumulative offset tracking across blocks for highlight matching.
  int _pageOffset = 0;
  final StringBuffer _pageTextBuf = StringBuffer();

  /// The clean text built from blocks (same as what _pageOffset tracks).
  String get lastBuiltCleanText => _pageTextBuf.toString();

  HtmlTextBuilder({
    required this.fontSize,
    this.fontFamily,
    this.fontPackage,
    required this.textColor,
    this.textAlign = TextAlign.justify,
    this.accentColor,
    this.onTextTap,
    this.highlights = const [],
    this.onHighlightChanged,
    this.onParagraphTapped,
  });

  TextStyle get _baseStyle => TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        package: fontPackage,
        color: textColor,
        height: 1.4,
      );

  List<Widget> build(String html) {
    _pageOffset = 0;
    _pageTextBuf.clear();
    final fixedHtml = _fixXhtml(html);
    final doc = html_parser.parse(fixedHtml);
    final body = doc.body ?? doc.documentElement;
    if (body == null) return [Text(html, style: _baseStyle)];

    final widgets = <Widget>[];
    _collectWidgets(body, widgets);
    if (widgets.isEmpty) {
      final text = body.text.trim();
      if (text.isNotEmpty) {
        widgets.add(Text(text, style: _baseStyle, textAlign: textAlign));
      }
    }
    return widgets;
  }

  void _collectWidgets(html_dom.Node node, List<Widget> widgets) {
    for (final child in node.nodes) {
      if (child is html_dom.Element) {
        final tag = child.localName?.toLowerCase() ?? '';

        if (const {'script', 'style', 'head', 'meta', 'link', 'title'}
            .contains(tag)) continue;
        if (_isContainer(child)) {
          _collectWidgets(child, widgets);
          continue;
        }
        if (tag == 'img') { _addImage(child, widgets); continue; }
        if (tag == 'hr') { widgets.add(const Divider()); continue; }
        if (tag == 'br') { widgets.add(SizedBox(height: fontSize * 0.5)); continue; }

        // Block element → build paragraph
        final spans = <InlineSpan>[];
        _buildSpans(child, spans, _styleForTag(tag));
        if (spans.isNotEmpty) {
          final span = TextSpan(children: spans);
          final blockClean = child.text.replaceAll('\u00AD', '');
          final blockStart = _pageOffset;
          _pageOffset += blockClean.length;
          _pageTextBuf.write(blockClean);

          final blockEnd = _pageOffset;
          final blockHighlights = _getBlockHighlights(blockStart, blockClean.length);

          widgets.add(Listener(
            onPointerDown: (_) => onParagraphTapped?.call(blockStart, blockEnd),
            child: Padding(
              padding: _paddingForTag(tag),
              child: SoftHyphenParagraph(
                textSpan: span,
                textAlign: textAlign,
                highlights: blockHighlights,
              ),
            ),
          ));
        }
      } else if (child is html_dom.Text) {
        final text = child.text.trim();
        if (text.isNotEmpty) {
          final span = TextSpan(text: text, style: _baseStyle);
          final blockClean = text.replaceAll('\u00AD', '');
          final blockStart = _pageOffset;
          _pageOffset += blockClean.length;
          _pageTextBuf.write(blockClean);

          final blockEnd = _pageOffset;
          final blockHighlights = _getBlockHighlights(blockStart, blockClean.length);

          widgets.add(Listener(
            onPointerDown: (_) => onParagraphTapped?.call(blockStart, blockEnd),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: fontSize * 0.3),
              child: SoftHyphenParagraph(
                textSpan: span,
                textAlign: textAlign,
                highlights: blockHighlights,
              ),
            ),
          ));
        }
      }
    }
  }

  /// Get highlights that overlap this block, with offsets adjusted to block-local.
  List<HighlightModel> _getBlockHighlights(int blockStart, int blockLen) {
    if (highlights.isEmpty) return [];
    final blockEnd = blockStart + blockLen;
    return highlights
        .where((h) => h.startIndex < blockEnd && h.endIndex > blockStart)
        .map((h) => HighlightModel(
              id: h.id,
              bookId: h.bookId,
              chapterIndex: h.chapterIndex,
              paragraphKey: h.paragraphKey,
              startIndex: (h.startIndex - blockStart).clamp(0, blockLen),
              endIndex: (h.endIndex - blockStart).clamp(0, blockLen),
              selectedText: h.selectedText,
              colorValue: h.colorValue,
            ))
        .toList();
  }

  void _buildSpans(
      html_dom.Node node, List<InlineSpan> spans, TextStyle style) {
    for (final child in node.nodes) {
      if (child is html_dom.Text) {
        final text = child.text;
        if (text.isNotEmpty) spans.add(TextSpan(text: text, style: style));
      } else if (child is html_dom.Element) {
        final tag = child.localName?.toLowerCase() ?? '';
        if (tag == 'br') { spans.add(const TextSpan(text: '\n')); continue; }
        if (tag == 'img') continue;
        _buildSpans(child, spans, _applyInlineTag(tag, style));
      }
    }
  }

  TextStyle _applyInlineTag(String tag, TextStyle base) {
    switch (tag) {
      case 'b' || 'strong': return base.copyWith(fontWeight: FontWeight.bold);
      case 'i' || 'em' || 'cite': return base.copyWith(fontStyle: FontStyle.italic);
      case 'u' || 'ins': return base.copyWith(decoration: TextDecoration.underline);
      case 's' || 'del' || 'strike': return base.copyWith(decoration: TextDecoration.lineThrough);
      case 'sup': return base.copyWith(fontSize: (base.fontSize ?? fontSize) * 0.7);
      case 'sub': return base.copyWith(fontSize: (base.fontSize ?? fontSize) * 0.7);
      case 'code': return base.copyWith(fontFamily: 'monospace', package: null, backgroundColor: textColor.withValues(alpha: 0.1));
      default: return base;
    }
  }

  TextStyle _styleForTag(String tag) {
    switch (tag) {
      case 'h1': return _baseStyle.copyWith(fontSize: fontSize * 2.0, fontWeight: FontWeight.bold);
      case 'h2': return _baseStyle.copyWith(fontSize: fontSize * 1.5, fontWeight: FontWeight.bold);
      case 'h3': return _baseStyle.copyWith(fontSize: fontSize * 1.17, fontWeight: FontWeight.bold);
      case 'h4': return _baseStyle.copyWith(fontWeight: FontWeight.bold);
      case 'h5': return _baseStyle.copyWith(fontSize: fontSize * 0.83, fontWeight: FontWeight.bold);
      case 'h6': return _baseStyle.copyWith(fontSize: fontSize * 0.67, fontWeight: FontWeight.bold);
      case 'blockquote': return _baseStyle.copyWith(fontStyle: FontStyle.italic);
      case 'pre' || 'code': return _baseStyle.copyWith(fontFamily: 'monospace', package: null);
      default: return _baseStyle;
    }
  }

  EdgeInsets _paddingForTag(String tag) {
    switch (tag) {
      case 'h1': return EdgeInsets.symmetric(vertical: fontSize * 0.8);
      case 'h2': return EdgeInsets.symmetric(vertical: fontSize * 0.6);
      case 'h3' || 'h4' || 'h5' || 'h6': return EdgeInsets.symmetric(vertical: fontSize * 0.4);
      case 'blockquote': return EdgeInsets.only(left: fontSize, top: fontSize * 0.3, bottom: fontSize * 0.3);
      case 'li': return EdgeInsets.only(left: fontSize, top: fontSize * 0.1, bottom: fontSize * 0.1);
      default: return EdgeInsets.symmetric(vertical: fontSize * 0.3);
    }
  }

  bool _isContainer(html_dom.Element element) {
    final tag = element.localName?.toLowerCase();
    if (const {'body','html','section','article','main','aside','nav','header','footer'}.contains(tag)) return true;
    if (tag == 'div' || tag == 'span') {
      final hasDirectText = element.nodes.any((n) => n is html_dom.Text && n.text.trim().isNotEmpty);
      if (!hasDirectText && element.children.isNotEmpty) return true;
    }
    return false;
  }

  void _addImage(html_dom.Element img, List<Widget> widgets) {
    final src = img.attributes['src'] ?? '';
    if (src.startsWith('data:')) {
      try {
        if (src.split(',').length == 2) {
          final bytes = UriData.parse(src).contentAsBytes();
          widgets.add(Padding(
            padding: EdgeInsets.symmetric(vertical: fontSize * 0.3),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ));
        }
      } catch (_) {}
    }
  }

  static String getPageCleanText(String pageHtml) {
    final fixed = _fixXhtml(pageHtml);
    final doc = html_parser.parse(fixed);
    return (doc.body ?? doc.documentElement)?.text.replaceAll('\u00AD', '') ?? '';
  }

  static String _fixXhtml(String html) {
    html = html.replaceAllMapped(
      RegExp(r'<(title|script|textarea|style|div|span|p|a|table|tbody|tr|td|th|ul|ol|li|h[1-6]|section|article|aside|header|footer|nav|main|blockquote|pre|code|em|strong|b|i|u|sub|sup|dd|dt|dl|figure|figcaption|details|summary)(\s[^>]*)?\s*/>', caseSensitive: false),
      (match) => '<${match.group(1)}${match.group(2) ?? ''}></${match.group(1)}>',
    );
    html = html.replaceAll(RegExp(r'<\?xml[^?]*\?>'), '');
    return html;
  }
}
