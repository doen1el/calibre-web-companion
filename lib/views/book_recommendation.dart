import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calibre_web_companion/view_models/book_recommendation_view_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BookRecommendationsListView extends StatefulWidget {
  const BookRecommendationsListView({super.key});

  @override
  BookRecommendationsListViewState createState() =>
      BookRecommendationsListViewState();
}

class BookRecommendationsListViewState
    extends State<BookRecommendationsListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = Provider.of<BookRecommendationsViewModel>(
        context,
        listen: false,
      );

      // Lade Bücher, falls noch nicht geschehen
      if (!viewModel.hasBooks) {
        await viewModel.loadUserBooks();
      }

      // Suche nach Empfehlungen
      if (viewModel.hasSubjects && !viewModel.hasRecommendations) {
        await viewModel.findRecommendedBooks(minimumMatches: 3);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.bookRecommendations),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final viewModel = Provider.of<BookRecommendationsViewModel>(
                context,
                listen: false,
              );
              await viewModel.loadUserBooks();
              if (viewModel.hasSubjects) {
                await viewModel.findRecommendedBooks(minimumMatches: 3);
              }
            },
          ),
        ],
      ),
      body: Consumer<BookRecommendationsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoadingBooks ||
              viewModel.isLoadingSubjects ||
              viewModel.isLoadingRecommendations) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  viewModel.error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!viewModel.hasBooks) {
            return Center(child: Text(localizations.noBooksFound));
          }

          if (!viewModel.hasSubjects) {
            return Center(child: Text('No subjects found for your books'));
          }

          if (!viewModel.hasRecommendations) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No recommendations found for your books'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await viewModel.findRecommendedBooks(minimumMatches: 2);
                    },
                    child: Text('Try with fewer matches'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: viewModel.recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = viewModel.recommendations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recommendation.title,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recommendation.author.join(', '),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text('${recommendation.matchCount} matches'),
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (recommendation.about.isNotEmpty)
                        Text(
                          recommendation.about.first.length > 200
                              ? '${recommendation.about.first.substring(0, 200)}...'
                              : recommendation.about.first,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 8),
                      if (recommendation.reactions.isNotEmpty) ...[
                        const Text(
                          'Subjects:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8,
                          children:
                              recommendation.reactions
                                  .take(10)
                                  .map(
                                    (tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceVariant,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
