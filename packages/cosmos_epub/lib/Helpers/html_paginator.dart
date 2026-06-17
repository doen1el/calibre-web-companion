import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

/// Splits HTML content into page-sized chunks by block-level elements.
///
/// Measures each block's actual height by building a TextSpan and laying it
/// out with TextPainter at the exact page width. This matches what
/// SelectableText.rich will render, giving accurate page breaks.
class HtmlPaginator {
  final double pageWidth;
  final double pageHeight;
  final double fontSize;
  final String fontFamily;
  final String? fontPackage;
  final TextDirection textDirection;

  HtmlPaginator({
    required this.pageWidth,
    required this.pageHeight,
    required this.fontSize,
    this.fontFamily = 'Segoe',
    this.fontPackage,
    this.textDirection = TextDirection.ltr,
  });

  TextStyle get _baseStyle => TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        package: fontPackage,
        height: 1.4,
      );

  List<String> paginate(String htmlContent) {
    if (htmlContent.trim().isEmpty) return [''];

    final fixedHtml = _fixXhtml(htmlContent);
    final doc = html_parser.parse(fixedHtml);
    final body = doc.body ?? doc.documentElement;
    if (body == null) return [htmlContent];

    final blocks = <_HtmlBlock>[];
    _collectBlocks(body, blocks);

    if (blocks.isEmpty) {
      final text = body.text.trim();
      if (text.isNotEmpty) return ['<p>$text</p>'];
      return [htmlContent];
    }

    final pages = <String>[];
    var currentPageBlocks = <_HtmlBlock>[];
    var currentPageHeight = 0.0;

    for (final block in blocks) {
      final blockHeight = _measureBlockHeight(block);

      if (currentPageHeight + blockHeight <= pageHeight) {
        currentPageBlocks.add(block);
        currentPageHeight += blockHeight;
      } else if (currentPageBlocks.isEmpty) {
        pages.add(block.html);
      } else {
        pages.add(_serializePage(currentPageBlocks));
        currentPageBlocks = [block];
        currentPageHeight = blockHeight;
      }
    }

    if (currentPageBlocks.isNotEmpty) {
      pages.add(_serializePage(currentPageBlocks));
    }

    return pages.isEmpty ? [htmlContent] : pages;
  }

  /// Measure block height by building a TextSpan and using TextPainter.
  /// This matches what SelectableText.rich actually renders.
  double _measureBlockHeight(_HtmlBlock block) {
    final tag = block.tag;

    if (tag == 'hr') return 20.0;
    if (tag == 'br') return fontSize * 0.5;
    if (tag == 'img') return _estimateImageHeight(block) + fontSize * 0.6;
    if (tag == 'table') {
      final rows = block.element?.querySelectorAll('tr').length ?? 1;
      return rows * (fontSize * 1.5 + 8.0) + fontSize * 0.6;
    }

    // Build TextSpan matching _styleForTag + _buildSpans logic
    final style = _styleForTag(tag);
    final spans = <InlineSpan>[];
    _buildSpans(block.element ?? _textNode(block.text), spans, style);

    if (spans.isEmpty) {
      if (block.text.trim().isEmpty) return _paddingForTag(tag);
      spans.add(TextSpan(text: block.text, style: style));
    }

    // Measure with TextPainter at exact page width
    final painter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: textDirection,
      textAlign: TextAlign.justify,
    );
    painter.layout(maxWidth: pageWidth);
    final textHeight = painter.height;
    painter.dispose();

    // SelectableText.rich adds ~4px internal padding per paragraph.
    // Scale factor accounts for widget chrome that TextPainter doesn't measure.
    return (textHeight + _paddingForTag(tag)) * 1.03 + 2;
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
      case 'code': return base.copyWith(fontFamily: 'monospace', package: null);
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

  /// Vertical padding per tag — matches HtmlTextBuilder._paddingForTag
  double _paddingForTag(String tag) {
    switch (tag) {
      case 'h1': return fontSize * 1.6;
      case 'h2': return fontSize * 1.2;
      case 'h3' || 'h4' || 'h5' || 'h6': return fontSize * 0.8;
      case 'blockquote': return fontSize * 0.6 + fontSize;
      case 'li': return fontSize * 0.2 + fontSize;
      default: return fontSize * 0.6;
    }
  }

  html_dom.Node _textNode(String text) {
    return html_parser.parseFragment('<p>$text</p>').firstChild!;
  }

  void _collectBlocks(html_dom.Node node, List<_HtmlBlock> blocks) {
    for (final child in node.nodes) {
      if (child is html_dom.Element) {
        final tag = child.localName?.toLowerCase() ?? 'div';
        if (const {'script', 'style', 'head', 'meta', 'link', 'title'}
            .contains(tag)) continue;
        if (_isContainerOnly(child)) {
          _collectBlocks(child, blocks);
        } else {
          blocks.add(_HtmlBlock(
            html: child.outerHtml,
            text: child.text,
            tag: tag,
            element: child,
          ));
        }
      } else if (child is html_dom.Text) {
        final text = child.text.trim();
        if (text.isNotEmpty) {
          blocks.add(_HtmlBlock(html: '<p>$text</p>', text: text, tag: 'p'));
        }
      }
    }
  }

  bool _isContainerOnly(html_dom.Element element) {
    final tag = element.localName?.toLowerCase();
    if (const {
      'body', 'html', 'section', 'article', 'main',
      'aside', 'nav', 'header', 'footer'
    }.contains(tag)) return true;
    if (tag == 'div' || tag == 'span') {
      final hasDirectText = element.nodes
          .any((n) => n is html_dom.Text && n.text.trim().isNotEmpty);
      if (!hasDirectText && element.children.isNotEmpty) return true;
    }
    return false;
  }

  double _estimateImageHeight(_HtmlBlock block) {
    if (block.element == null) return 200.0;
    final target = block.tag == 'img'
        ? block.element!
        : (block.element!.querySelector('img') ?? block.element!);
    final widthAttr = target.attributes['width'];
    final heightAttr = target.attributes['height'];
    if (widthAttr != null && heightAttr != null) {
      final imgW = double.tryParse(widthAttr.replaceAll(RegExp(r'[^0-9.]'), ''));
      final imgH = double.tryParse(heightAttr.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (imgW != null && imgW > 0 && imgH != null) {
        return (imgH * pageWidth / imgW).clamp(50.0, pageHeight * 0.8);
      }
    }
    return 200.0;
  }

  String _serializePage(List<_HtmlBlock> blocks) {
    return blocks.map((b) => b.html).join('\n');
  }

  static String _fixXhtml(String html) {
    html = html.replaceAllMapped(
      RegExp(
          r'<(title|script|textarea|style|div|span|p|a|table|tbody|tr|td|th|ul|ol|li|h[1-6]|section|article|aside|header|footer|nav|main|blockquote|pre|code|em|strong|b|i|u|sub|sup|dd|dt|dl|figure|figcaption|details|summary)(\s[^>]*)?\s*/>',
          caseSensitive: false),
      (match) => '<${match.group(1)}${match.group(2) ?? ''}></${match.group(1)}>',
    );
    html = html.replaceAll(RegExp(r'<\?xml[^?]*\?>'), '');
    return html;
  }
}

class _HtmlBlock {
  final String html;
  final String text;
  final String tag;
  final html_dom.Element? element;

  _HtmlBlock({
    required this.html,
    required this.text,
    required this.tag,
    this.element,
  });
}
