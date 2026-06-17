## 1.0.0

### Major Rewrite
This release is a complete rewrite of the core rendering engine and a major feature upgrade.

### New Features
* **Text Highlighting**: Select text and highlight with 6 colors. Highlights persist across sessions. Re-highlight to change color. Copy and Select All support.
* **Syllable-Aware Hyphenation**: Built-in hyphenation engine that breaks words at syllable boundaries for better justified text. Respects Uzbek digraphs (ch, sh, g', o'). Visible hyphen "-" at line breaks via two-pass TextPainter resolution.
* **Infinite Nested Chapters**: Recursive chapter tree with unlimited nesting depth. Proper TOC indentation by depth level. Section title pages auto-generated for TOC groupings.
* **Image Support**: EPUB images extracted and rendered inline via base64 data URIs. Supports PNG, JPEG, GIF, SVG, WebP.
* **Robust EPUB Parsing**: 3-tier chapter resolution: NCX NavMap → epubx Chapters → Spine order. Handles malformed EPUBs, nested TOCs, missing content files. XHTML compatibility fixes for HTML5 parser.

### Rendering Engine
* **Native Text Rendering**: Replaced flutter_html with native `Text.rich`/`SelectableText.rich` for full control over text layout, selection, and hyphenation.
* **HTML to TextSpan**: Custom `HtmlTextBuilder` converts HTML to Flutter widget tree preserving bold, italic, underline, strikethrough, headings, lists, blockquotes, code blocks, images.
* **Accurate Pagination**: TextPainter-based page splitting with real font metrics instead of height estimation. Pages are consistent in height.

### Improvements
* **Selection Color**: Visible blue selection highlight with configurable accent color.
* **Font Selection**: Fixed font loading for package fonts. Fonts apply correctly across the reader.
* **Chapter Navigation**: Proper swipe-to-advance with direction-aware callbacks. 1-page chapters advance immediately. Swipe counters reset between chapters.
* **Page Flip Animation**: `didUpdateWidget` properly resets animation state on chapter change. Cached page images cleared after highlighting.
* **TOC Ornament**: Decorative SVG divider in Table of Contents replacing plain text title.
* **Background Color**: Separated from TextStyle to prevent covering selection overlay.

### Breaking Changes
* Minimum Flutter version raised to 3.10.0
* Replaced `isar` with `isar_community` (^3.3.2)
* Removed `flutter_html_reborn` dependency (replaced with native rendering)
* `HighlightModel` added to public API
* `getBookHighlights`, `removeHighlight`, `removeAllHighlights` added to `CosmosEpub`

### Bug Fixes
* Fixed chapters not showing (XHTML `<title/>` breaking HTML5 parser)
* Fixed blank pages on startup (`ScreenUtil.ensureScreenSize` deadlock)
* Fixed Isar version mismatch between runtime and native libs
* Fixed font not changing (double package prefix on fontFamily)
* Fixed selection invisible (TextStyle.backgroundColor covering overlay)
* Fixed highlight rendering on wrong word occurrence
* Fixed page flip breaking after chapter change
* Fixed 1-page chapter navigation (forward/backward)

---

## 0.0.3

* **RTL Language Support**: Added comprehensive support for Right-to-Left languages
* **Automatic Text Direction Detection**: Library automatically detects and handles RTL content
* **RTL-Aware Navigation**: Navigation buttons automatically reverse for RTL languages
* **Multi-Language Support**: Added support for Arabic, Persian, Hebrew, Urdu, and other RTL languages
* **Smart Text Alignment**: Proper text alignment based on detected language direction
* **Chapter List RTL Support**: Table of contents now supports RTL layout with proper indentation
* **Mixed Content Handling**: Seamlessly handles documents with both LTR and RTL text
* **Unicode Range Detection**: Advanced RTL character detection using Unicode ranges
* **Bidirectional Text Support**: Improved rendering for mixed directional content

## 0.0.2

* Build error fix
* Add `CosmosEpub.openURLBook` & `CosmosEpub.openFileBook` methods

## 0.0.1

* Initial release of cosmos_epub package
