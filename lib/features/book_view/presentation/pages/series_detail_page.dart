import 'package:flutter/material.dart';

import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/book_card_widget.dart';

class SeriesDetailPage extends StatelessWidget {
  final String seriesName;
  final List<BookViewModel> books;

  const SeriesDetailPage({
    super.key,
    required this.seriesName,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(seriesName)),
      body:
          books.isEmpty
              ? Center(child: Text(localizations.noBooksFound))
              : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return BookCard(
                    bookId: book.id.toString(),
                    title: book.title,
                    authors: book.authors,
                    coverUrl: book.coverUrl,
                    readStatus: book.readStatus,
                    topLeftBadge: book.seriesBadge,
                    onTap:
                        () => Navigator.of(context).push(
                          AppTransitions.createSlideRoute(
                            BookDetailsPage(
                              bookViewModel: book,
                              bookUuid: book.uuid,
                            ),
                          ),
                        ),
                  );
                },
              ),
    );
  }
}
