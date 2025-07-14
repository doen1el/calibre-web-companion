import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_event.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_state.dart';

import 'package:calibre_web_companion/features/download_service/presentation/widgets/book_card_widget.dart';

class DownloadsTabWidget extends StatelessWidget {
  const DownloadsTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<DownloadServiceBloc, DownloadServiceState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.downloads,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed:
                          () => context.read<DownloadServiceBloc>().add(
                            GetDownloadStatus(),
                          ),
                    ),
                  ],
                ),
              ),
              _buildDownloadsContent(context, state, localizations),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDownloadsContent(
    BuildContext context,
    DownloadServiceState state,
    AppLocalizations localizations,
  ) {
    if (state.isLoading) {
      return _buildBookCardSkeletons(context);
    } else if (state.errorMessage != null) {
      return _buildErrorMessage(context, state.errorMessage!);
    } else if (state.books.isNotEmpty) {
      return _buildBookList(context, localizations, state.books);
    } else {
      return _buildEmptyState(
        context,
        Icons.download_done,
        localizations.noDownloadsFound,
      );
    }
  }

  Widget _buildBookCardSkeletons(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

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
                localizations.loadingBooks,
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

  Widget _buildErrorMessage(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList(
    BuildContext context,
    AppLocalizations localizations,
    List<dynamic> books,
  ) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.download_done,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .5),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.noDownloadsFound,
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
              return BookCardWidget(book: books[index], isSearchResult: false);
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
