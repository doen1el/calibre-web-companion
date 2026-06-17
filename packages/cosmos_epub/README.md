# CosmosEpub 💫

A feature-rich EPUB reader package for Flutter with page flip animations, text highlighting, hyphenation, infinite nested chapters, image support, RTL languages, customizable themes and fonts.

## Showcase

![banner](https://github.com/Mamasodikov/cosmos_epub/assets/64262986/b3ca850b-96da-48fc-9b9e-ff5f92544f53)

## Features

- **Text Highlighting** — select text, pick a color (6 options), highlights persist across sessions. Re-highlight to change color. Copy & Select All support.
- **Hyphenation** — syllable-aware word breaking for better justified text. Visible "-" at line breaks. Respects Uzbek digraphs (ch, sh, g', o').
- **Infinite Nested Chapters** — recursive TOC with unlimited depth. Section title pages auto-generated.
- **Image Support** — EPUB images rendered inline (PNG, JPEG, GIF, SVG, WebP).
- **Page Flip Animation** — realistic 3D page curl effect with swipe gestures.
- **5 Themes** — Grey, Purple, White, Black, Pink.
- **14 Fonts** — Alegreya, Amazon Ember, Bookerly, EB Garamond, Lora, Ubuntu, and more.
- **RTL Support** — Arabic, Persian, Hebrew, Urdu, and other RTL languages with auto-detection.
- **Reading Progress** — chapter and page position saved per book.
- **Brightness Control** — in-reader brightness slider.
- **Multiple Sources** — open EPUB from assets, local file, URL, or raw bytes.
- **Robust Parsing** — 3-tier chapter resolution (NCX NavMap → epubx Chapters → Spine order). Handles malformed EPUBs.

## Getting Started

Add the dependency:

```yaml
dependencies:
  cosmos_epub: ^1.0.0
```

```bash
flutter pub get
```

## Usage

### Initialize

Call `initialize()` once before using any other method (preferably in `main.dart`):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CosmosEpub.initialize();
  runApp(MyApp());
}
```

### Open a Book

```dart
// From assets
await CosmosEpub.openAssetBook(
  assetPath: 'assets/book.epub',
  context: context,
  bookId: 'my_book_1',
  accentColor: Colors.indigoAccent,
  onPageFlip: (currentPage, totalPages) {
    print('Page $currentPage of $totalPages');
  },
  onLastPage: (lastPageIndex) {
    print('Reached last page');
  },
);

// From local file
await CosmosEpub.openLocalBook(
  localPath: '/path/to/book.epub',
  context: context,
  bookId: 'my_book_2',
);

// From URL
await CosmosEpub.openURLBook(
  urlPath: 'https://example.com/book.epub',
  context: context,
  bookId: 'my_book_3',
);

// From bytes
await CosmosEpub.openFileBook(
  bytes: myUint8List,
  context: context,
  bookId: 'my_book_4',
);
```

### Progress Management

```dart
// Get current progress
BookProgressModel progress = CosmosEpub.getBookProgress('my_book_1');
print('Chapter: ${progress.currentChapterIndex}');
print('Page: ${progress.currentPageIndex}');

// Set progress manually
await CosmosEpub.setCurrentChapterIndex('my_book_1', 5);
await CosmosEpub.setCurrentPageIndex('my_book_1', 3);

// Delete progress
await CosmosEpub.deleteBookProgress('my_book_1');
await CosmosEpub.deleteAllBooksProgress();
```

### Highlight Management

```dart
// Get all highlights for a book
List<HighlightModel> highlights = CosmosEpub.getBookHighlights('my_book_1');

// Remove a specific highlight
CosmosEpub.removeHighlight(highlights.first.id);

// Remove all highlights for a book
CosmosEpub.removeAllHighlights('my_book_1');
```

### Clear Theme Cache

```dart
await CosmosEpub.clearThemeCache();
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `assetPath` / `localPath` / `urlPath` / `bytes` | `String` / `Uint8List` | required | EPUB source |
| `context` | `BuildContext` | required | Build context for navigation |
| `bookId` | `String` | required | Unique ID for progress tracking |
| `accentColor` | `Color` | `Colors.indigoAccent` | Primary accent color |
| `onPageFlip` | `Function(int, int)?` | `null` | Called on page change |
| `onLastPage` | `Function(int)?` | `null` | Called on last page |
| `chapterListTitle` | `String` | `'Table of Contents'` | TOC screen title |
| `shouldOpenDrawer` | `bool` | `false` | Open TOC on start |
| `starterChapter` | `int` | `-1` | Start at specific chapter |

## RTL Language Support 🌍

Automatic detection and support for Right-to-Left languages:

- Arabic (العربية), Persian (فارسی), Hebrew (עברית), Urdu (اردو)
- Pashto (پښتو), Sindhi (سنڌي), Kurdish (کوردی), Dhivehi (ދިވެހި), Yiddish (ייִדיש)

No configuration needed — just open the EPUB and the library handles direction, alignment, and navigation automatically.

## Notes

- Each book must have a unique `bookId`. Using the same ID for different books will cause progress conflicts.
- Highlights are stored locally via GetStorage and persist across app restarts.
- The package uses `isar_community` for progress persistence (Android/iOS/Desktop only, no web support).

## License

MIT

## Contact

Feel free to open an issue or reach out: [https://allmylinks.com/mamasodikov](https://allmylinks.com/mamasodikov)
