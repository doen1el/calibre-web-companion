import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/view_models/book_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calibre_web_companion/main.dart';

enum BookListType {
  bookmarked,
  unreadbooks,
  readbooks,
  hot,
  newlyAdded,
  rated,
  discover,
}

enum CategoryType {
  category,
  language,
  publisher,
  author,
  ratings,
  formats,
  series,
}

class BookList extends StatefulWidget {
  final BookListType? bookListType;
  final CategoryType? categoryType;
  final String? subPath;
  final String? fullPath;
  final String title;

  const BookList({
    super.key,
    this.bookListType,
    this.categoryType,
    this.subPath,
    this.fullPath,
    required this.title,
  }) : assert(
         bookListType != null || categoryType != null || fullPath != null,
         'Either bookListType, categoryType, or fullPath must be provided',
       );

  @override
  BookListState createState() => BookListState();
}

class BookListState extends State<BookList> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Registriere diese Route beim Observer
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    // Abmelden beim Observer
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Wird aufgerufen, wenn der Benutzer zurück zu dieser Seite navigiert
    _loadData();
  }

  @override
  void didUpdateWidget(BookList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookListType != widget.bookListType ||
        oldWidget.categoryType != widget.categoryType ||
        oldWidget.subPath != widget.subPath) {
      _loadData();
    }
  }

  void _loadData() {
    final viewModel = context.read<BookListViewModel>();

    // Wenn ein vollständiger Pfad vorhanden ist, verwende diesen
    if (widget.fullPath != null) {
      viewModel.loadBooksFromPath(widget.fullPath!);
    }
    // Sonst Standard-Logik
    else if (widget.bookListType != null) {
      viewModel.loadBooks(widget.bookListType!, subPath: widget.subPath);
    } else if (widget.categoryType != null) {
      viewModel.loadCategories(widget.categoryType!, subPath: widget.subPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Consumer<BookListViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Fehler beim Laden der Daten',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(viewModel.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            );
          }

          // Zeige Bücher als Grid
          if (viewModel.bookFeed != null) {
            return _buildBookGrid(viewModel.bookFeed!);
          }

          // Zeige Kategorien als Liste
          if (viewModel.categoryFeed != null) {
            return _buildCategoryList(viewModel.categoryFeed!);
          }

          return const Center(child: Text('Keine Daten gefunden'));
        },
      ),
    );
  }

  Widget _buildBookGrid(OpdsFeed<BookItem> feed) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: feed.items.length,
      itemBuilder: (context, index) {
        final book = feed.items[index];
        return BookCard(book: book);
      },
    );
  }

  Widget _buildCategoryList(OpdsFeed<CategoryItem> feed) {
    return ListView.builder(
      itemCount: feed.items.length,
      itemBuilder: (context, index) {
        final category = feed.items[index];

        return CategoryListItem(
          category: category,
          onTap: () {
            _navigateToCategoryOrBooks(context, category);
          },
        );
      },
    );
  }

  void _navigateToCategoryOrBooks(BuildContext context, CategoryItem category) {
    final String url = category.navigationUrl;
    if (url.isEmpty) return;

    print('NavigationURL: $url');

    // Besondere Behandlung für Letter-Navigation
    if (url.contains('/letter/')) {
      // Letter-Navigation ist immer eine Kategorienliste
      final parts = url.split('/').where((p) => p.isNotEmpty).toList();
      CategoryType? categoryType;

      if (parts.length >= 2) {
        // Bestimme Kategorie-Typ
        switch (parts[1]) {
          case 'author':
            categoryType = CategoryType.author;
            break;
          case 'series':
            categoryType = CategoryType.series;
            break;
          case 'category':
            categoryType = CategoryType.category;
            break;
          case 'publisher':
            categoryType = CategoryType.publisher;
            break;
          case 'language':
            categoryType = CategoryType.language;
            break;
          case 'formats':
            categoryType = CategoryType.formats;
            break;
          case 'ratings':
            categoryType = CategoryType.ratings;
            break;
        }
      }

      // Extrahiere den kompletten Subpfad nach dem Kategorietyp
      String subPath = url.split('/${parts[1]}/')[1];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => BookList(
                title: category.title,
                categoryType: categoryType,
                subPath: subPath,
              ),
        ),
      );
      return;
    }

    // Für alle anderen URLs: Standardverhalten
    bool isBookListPath = false;

    if (url.startsWith('/opds/')) {
      final parts = url.split('/');
      if (parts.length >= 3) {
        // Prüfe, ob der letzte Teil eine Zahl ist
        final lastPart = parts.last;
        if (int.tryParse(lastPart) != null) {
          isBookListPath = true;
        }
      }
    }

    // Rest des Codes bleibt unverändert...
    if (isBookListPath) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookList(title: category.title, fullPath: url),
        ),
      );
    } else if (url.startsWith('/opds/')) {
      // Standardverhalten für andere OPDS-Pfade
      // ...
    }
  }
}

/// Karte für ein einzelnes Buch
class BookCard extends StatelessWidget {
  final BookItem book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover-Bild
          Expanded(child: _buildCoverImage(context, book.id)),

          // Buch-Informationen
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildCoverImage(BuildContext context, String bookId) {
  ApiService apiService = ApiService();
  final baseUrl = apiService.getBaseUrl();
  final username = apiService.getUsername();
  final password = apiService.getPassword();

  // Basic Auth Header in Base64 generieren
  final authHeader =
      'Basic ${base64.encode(utf8.encode('$username:$password'))}';
  final coverUrl = '$baseUrl/opds/cover/$bookId';

  return CachedNetworkImage(
    imageUrl: coverUrl,
    httpHeaders: {'Authorization': authHeader},
    fit: BoxFit.cover,
    width: double.infinity,
    placeholder:
        (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    errorWidget:
        (context, url, error) =>
            const Center(child: Icon(Icons.book, size: 64)),
    // Cache Einstellungen optimieren
    memCacheWidth: 300, // Speichereffizienz verbessern
    memCacheHeight: 400,
  );
}

/// ListItem for a category
///
/// Author, Categiory, Series
class CategoryListItem extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = BorderRadius.circular(8.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
