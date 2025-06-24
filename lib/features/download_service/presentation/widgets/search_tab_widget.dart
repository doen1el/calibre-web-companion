import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_event.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_state.dart';

import 'package:calibre_web_companion/features/download_service/presentation/widgets/book_card_widget.dart';

class SearchTabWidget extends StatelessWidget {
  const SearchTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<DownloadServiceBloc, DownloadServiceState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(context, localizations),
              _buildSearchContent(context, state, localizations),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, AppLocalizations localizations) {
    final searchController = TextEditingController();
    final borderRadius = BorderRadius.circular(8.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: localizations.searchForABook,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    context.read<DownloadServiceBloc>().add(SearchBooks(value));
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                final value = searchController.text.trim();
                if (value.isNotEmpty) {
                  context.read<DownloadServiceBloc>().add(SearchBooks(value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent(
    BuildContext context,
    DownloadServiceState state,
    AppLocalizations localizations,
  ) {
    if (state.isSearching) {
      return _buildBookCardSkeletons(context);
    } else if (state.searchResults.isNotEmpty) {
      return _buildBookList(
        context,
        localizations,
        state.searchResults,
        isSearchResults: true,
      );
    } else if (state.hasSearched && state.searchResults.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.search_off,
        localizations.noBooksFound,
      );
    } else {
      return _buildEmptyState(
        context,
        Icons.search,
        localizations.searchForBooks,
      );
    }
  }

  Widget _buildBookCardSkeletons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Skeletonizer(
              enabled: true,
              effect: ShimmerEffect(
                baseColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .2),
                highlightColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .4),
              ),
              child: Text(
                "Loading books...", // TODO: Localize this string
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Skeletonizer(
                enabled: true,
                effect: ShimmerEffect(
                  baseColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .2),
                  highlightColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .4),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Container(width: 120, color: Colors.grey),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 24,
                                  width: double.infinity,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 16,
                                  width: 150,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 16,
                                  width: 100,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(
    BuildContext context,
    AppLocalizations localizations,
    List<dynamic> books, {
    bool isSearchResults = false,
  }) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                isSearchResults ? Icons.search_off : Icons.download_done,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .5),
              ),
              const SizedBox(height: 16),
              Text(
                isSearchResults
                    ? localizations.noBooksFound
                    : localizations.noDownloadsFound,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              localizations.foundBooks(books.length),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return BookCardWidget(
                book: books[index],
                isSearchResult: isSearchResults,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
