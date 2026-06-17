/// All functions

import 'package:flutter/material.dart';

/// Utility class for RTL (Right-to-Left) language support
class RTLHelper {
  // RTL language codes that should use right-to-left text direction
  static const Set<String> rtlLanguages = {
    'ar', // Arabic
    'fa', // Persian/Farsi
    'he', // Hebrew
    'ur', // Urdu
    'ps', // Pashto
    'sd', // Sindhi
    'ku', // Kurdish
    'ckb', // Sorani Kurdish
    'dv', // Dhivehi/Maldivian
    'yi', // Yiddish
  };

  // RTL Unicode character ranges
  static const List<List<int>> rtlUnicodeRanges = [
    [0x0590, 0x05FF], // Hebrew
    [0x0600, 0x06FF], // Arabic
    [0x0700, 0x074F], // Syriac
    [0x0750, 0x077F], // Arabic Supplement
    [0x0780, 0x07BF], // Thaana (Dhivehi)
    [0x08A0, 0x08FF], // Arabic Extended-A
    [0xFB1D, 0xFB4F], // Hebrew Presentation Forms
    [0xFB50, 0xFDFF], // Arabic Presentation Forms-A
    [0xFE70, 0xFEFF], // Arabic Presentation Forms-B
  ];

  /// Detects if the given text contains RTL characters
  static bool containsRTLCharacters(String text) {
    if (text.isEmpty) return false;

    for (int i = 0; i < text.length; i++) {
      int codeUnit = text.codeUnitAt(i);

      for (List<int> range in rtlUnicodeRanges) {
        if (codeUnit >= range[0] && codeUnit <= range[1]) {
          return true;
        }
      }
    }
    return false;
  }

  /// Determines the primary text direction for a given text
  /// Returns TextDirection.rtl if the text is primarily RTL, otherwise TextDirection.ltr
  static TextDirection getTextDirection(String text) {
    if (text.isEmpty) return TextDirection.ltr;

    int rtlCount = 0;
    int ltrCount = 0;

    for (int i = 0; i < text.length; i++) {
      int codeUnit = text.codeUnitAt(i);

      // Check for RTL characters
      bool isRTL = false;
      for (List<int> range in rtlUnicodeRanges) {
        if (codeUnit >= range[0] && codeUnit <= range[1]) {
          rtlCount++;
          isRTL = true;
          break;
        }
      }

      // Check for LTR characters (Latin, numbers, etc.)
      if (!isRTL &&
          ((codeUnit >= 0x0041 && codeUnit <= 0x005A) || // A-Z
              (codeUnit >= 0x0061 && codeUnit <= 0x007A) || // a-z
              (codeUnit >= 0x0030 && codeUnit <= 0x0039) || // 0-9
              (codeUnit >= 0x00C0 && codeUnit <= 0x00FF))) {
        // Latin-1 Supplement
        ltrCount++;
      }
    }

    // If more than 30% of characters are RTL, consider the text RTL
    double rtlRatio = rtlCount / (rtlCount + ltrCount);
    return rtlRatio > 0.3 ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Gets the appropriate text alignment based on text direction
  static TextAlign getTextAlign(TextDirection direction) {
    return direction == TextDirection.rtl ? TextAlign.right : TextAlign.left;
  }

  /// Gets justified text alignment (works for both LTR and RTL)
  static TextAlign getJustifiedAlign() {
    return TextAlign.justify;
  }
}
