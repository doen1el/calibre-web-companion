import 'package:flutter/material.dart';

import '../Model/highlight_model.dart';

/// A text paragraph that:
/// 1. Resolves soft hyphens (\u00AD) into visible "-" at line breaks
/// 2. Renders stored highlights as colored backgrounds
/// 3. Uses Text.rich to participate in parent SelectionArea for cross-paragraph selection
class SoftHyphenParagraph extends StatelessWidget {
  final TextSpan textSpan;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final List<HighlightModel> highlights;
  final String paragraphKey;
  final Color? selectionColor;
  final VoidCallback? onTap;
  final void Function(int start, int end, Color color)? onHighlight;

  const SoftHyphenParagraph({
    super.key,
    required this.textSpan,
    this.textAlign = TextAlign.justify,
    this.textDirection = TextDirection.ltr,
    this.highlights = const [],
    this.paragraphKey = '',
    this.selectionColor,
    this.onTap,
    this.onHighlight,
  });

  @override
  Widget build(BuildContext context) {
    final plainText = textSpan.toPlainText();
    final hasShy = plainText.contains('\u00AD');

    // Use LayoutBuilder to get exact width for hyphen resolution
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // Step 1: Apply highlights FIRST (on original text, before hyphen resolution)
        // This ensures highlight offsets match the clean text space.
        TextSpan highlightedSpan = textSpan;
        if (highlights.isNotEmpty) {
          highlightedSpan = _applyHighlights(highlightedSpan);
        }

        // Step 2: Resolve soft hyphens
        TextSpan resolvedSpan;
        if (hasShy && maxWidth > 0 && maxWidth.isFinite) {
          final breakOffsets = _findBreakOffsets(plainText, maxWidth);
          resolvedSpan = _resolveSpan(highlightedSpan, breakOffsets);
          resolvedSpan = _verifyHyphens(resolvedSpan, maxWidth);
        } else if (hasShy) {
          resolvedSpan = _stripSoftHyphens(highlightedSpan);
        } else {
          resolvedSpan = highlightedSpan;
        }

        // Step 3: Render as Text.rich (participates in parent SelectionArea)
        return Text.rich(
          resolvedSpan,
          textAlign: textAlign,
          textDirection: textDirection,
          softWrap: true,
        );
      },
    );
  }

  /// Second pass: lay out the resolved text and remove any "-" that
  /// ended up mid-line (not at a line break) after \u00AD removal shifted layout.
  TextSpan _verifyHyphens(TextSpan resolved, double maxWidth) {
    final resolvedText = resolved.toPlainText();
    if (!resolvedText.contains('-')) return resolved;

    final painter = TextPainter(
      text: resolved,
      textAlign: textAlign,
      textDirection: textDirection,
    );
    painter.layout(maxWidth: maxWidth);

    final lines = painter.computeLineMetrics();
    final validHyphens = <int>{};

    // Find which "-" are at actual line ends
    for (int li = 0; li < lines.length - 1; li++) {
      final line = lines[li];
      final endPos = painter
          .getPositionForOffset(
              Offset(line.left + line.width, line.baseline))
          .offset;

      // Check if there's a "-" right at the line end
      if (endPos > 0 && endPos <= resolvedText.length &&
          resolvedText[endPos - 1] == '-') {
        validHyphens.add(endPos - 1);
      }
    }

    // Remove "-" that aren't at line ends (they were from resolved soft hyphens)
    // We only remove "-" that were inserted by us (from \u00AD resolution),
    // not original "-" in the text. We detect ours by checking: in the original
    // textSpan, was this position a \u00AD?
    final originalText = textSpan.toPlainText();

    // Build set of positions where we inserted "-" (originally \u00AD)
    final insertedHyphens = <int>{};
    int origIdx = 0;
    int resIdx = 0;
    while (origIdx < originalText.length && resIdx < resolvedText.length) {
      if (originalText[origIdx] == '\u00AD') {
        if (resIdx < resolvedText.length && resolvedText[resIdx] == '-') {
          insertedHyphens.add(resIdx);
          resIdx++;
        }
        origIdx++;
      } else {
        origIdx++;
        resIdx++;
      }
    }

    // Find bad hyphens: inserted by us AND not at a valid line end
    final badHyphens = insertedHyphens.difference(validHyphens);
    if (badHyphens.isEmpty) return resolved;

    // Rebuild span removing bad hyphens
    final counter = _Counter();
    return _removeBadHyphens(resolved, badHyphens, counter);
  }

  TextSpan _removeBadHyphens(
      TextSpan span, Set<int> badPositions, _Counter offset) {
    String? newText;
    if (span.text != null) {
      final buf = StringBuffer();
      for (int i = 0; i < span.text!.length; i++) {
        if (span.text![i] == '-' && badPositions.contains(offset.value)) {
          // Skip this hyphen
        } else {
          buf.write(span.text![i]);
        }
        offset.value++;
      }
      newText = buf.toString();
    }

    List<InlineSpan>? newChildren;
    if (span.children != null && span.children!.isNotEmpty) {
      newChildren = span.children!.map((child) {
        if (child is TextSpan) return _removeBadHyphens(child, badPositions, offset);
        return child;
      }).toList();
    }

    return TextSpan(text: newText, style: span.style, children: newChildren);
  }

  Set<int> _findBreakOffsets(String text, double maxWidth) {
    final painter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      textDirection: textDirection,
    );
    painter.layout(maxWidth: maxWidth);

    final lines = painter.computeLineMetrics();
    final breakOffsets = <int>{};

    for (int li = 0; li < lines.length - 1; li++) {
      final line = lines[li];
      final endPos = painter
          .getPositionForOffset(
              Offset(line.left + line.width, line.baseline))
          .offset;

      if (endPos > 0 && endPos <= text.length &&
          text[endPos - 1] == '\u00AD') {
        breakOffsets.add(endPos - 1);
      } else if (endPos < text.length && text[endPos] == '\u00AD') {
        breakOffsets.add(endPos);
      }
    }
    return breakOffsets;
  }

  TextSpan _resolveSpan(TextSpan root, Set<int> breakOffsets) {
    final counter = _Counter();
    return _resolveSpanRecursive(root, breakOffsets, counter);
  }

  TextSpan _resolveSpanRecursive(
      TextSpan span, Set<int> breakOffsets, _Counter offset) {
    String? newText;
    if (span.text != null) {
      final buf = StringBuffer();
      for (int i = 0; i < span.text!.length; i++) {
        if (span.text![i] == '\u00AD') {
          if (breakOffsets.contains(offset.value)) buf.write('-');
        } else {
          buf.write(span.text![i]);
        }
        offset.value++;
      }
      newText = buf.toString();
    }

    List<InlineSpan>? newChildren;
    if (span.children != null && span.children!.isNotEmpty) {
      newChildren = span.children!.map((child) {
        if (child is TextSpan) {
          return _resolveSpanRecursive(child, breakOffsets, offset);
        }
        return child;
      }).toList();
    }

    return TextSpan(text: newText, style: span.style, children: newChildren);
  }

  TextSpan _stripSoftHyphens(TextSpan span) {
    return TextSpan(
      text: span.text?.replaceAll('\u00AD', ''),
      style: span.style,
      children: span.children?.map((child) {
        if (child is TextSpan) return _stripSoftHyphens(child);
        return child;
      }).toList(),
    );
  }

  /// Apply stored highlights as background colors on the TextSpan.
  /// Uses exact startIndex/endIndex from EditableTextState.selection.
  TextSpan _applyHighlights(TextSpan span) {
    final plainText = span.toPlainText();
    if (plainText.isEmpty || highlights.isEmpty) return span;

    // Flatten all text segments with their styles
    final segments = <_TextSegment>[];
    _flattenSpan(span, segments);

    // Map clean-text indices → span-text indices (accounting for \u00AD)
    // highlights use clean offsets, but plainText may contain \u00AD
    final cleanToSpan = <int>[];
    for (int i = 0; i < plainText.length; i++) {
      if (plainText[i] != '\u00AD') {
        cleanToSpan.add(i);
      }
    }

    // Build character-level color map (in span-text space)
    final charColors = List<Color?>.filled(plainText.length, null);
    for (final h in highlights) {
      final color = Color(h.colorValue);
      // Map clean start/end to span positions
      final spanStart = h.startIndex < cleanToSpan.length
          ? cleanToSpan[h.startIndex] : plainText.length;
      final spanEnd = h.endIndex <= cleanToSpan.length
          ? (h.endIndex < cleanToSpan.length ? cleanToSpan[h.endIndex] : plainText.length)
          : plainText.length;
      for (int i = spanStart; i < spanEnd && i < plainText.length; i++) {
        charColors[i] = color;
      }
    }

    // Rebuild spans splitting at color boundaries
    final result = <InlineSpan>[];
    int globalPos = 0;

    for (final seg in segments) {
      final text = seg.text;
      int pos = 0;
      while (pos < text.length) {
        final charIdx = globalPos + pos;
        final currentColor = charIdx < charColors.length ? charColors[charIdx] : null;

        // Find run of same color
        int runEnd = pos + 1;
        while (runEnd < text.length) {
          final nextIdx = globalPos + runEnd;
          final nextColor = nextIdx < charColors.length ? charColors[nextIdx] : null;
          if (nextColor != currentColor) break;
          runEnd++;
        }

        final runText = text.substring(pos, runEnd);
        result.add(TextSpan(
          text: runText,
          style: currentColor != null
              ? (seg.style ?? textSpan.style)?.copyWith(
                  backgroundColor: currentColor.withValues(alpha: 0.4))
              : seg.style,
        ));
        pos = runEnd;
      }
      globalPos += text.length;
    }

    return TextSpan(children: result);
  }

  void _flattenSpan(TextSpan span, List<_TextSegment> out) {
    if (span.text != null && span.text!.isNotEmpty) {
      out.add(_TextSegment(span.text!, span.style));
    }
    if (span.children != null) {
      for (final child in span.children!) {
        if (child is TextSpan) _flattenSpan(child, out);
      }
    }
  }
}

class _Counter {
  int value = 0;
}

class _TextSegment {
  final String text;
  final TextStyle? style;
  _TextSegment(this.text, this.style);
}
