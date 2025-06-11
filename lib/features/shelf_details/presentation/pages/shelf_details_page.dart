import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_bloc.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_event.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/main.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/book_author_model.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_book_item_model.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';
import 'package:calibre_web_companion/features/shelf_details/presentation/widgets/edit_shelf_dialog_widget.dart';

class ShelfDetailsPage extends StatelessWidget {
  final String shelfId;

  const ShelfDetailsPage({super.key, required this.shelfId});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create:
          (context) =>
              getIt<ShelfDetailsBloc>()..add(LoadShelfDetails(shelfId)),
      child: BlocConsumer<ShelfDetailsBloc, ShelfDetailsState>(
        listener: (context, state) {
          if (state.actionDetailsStatus == ShelfDetailsActionStatus.success) {
            if (state.actionMessage?.contains('deleted') == true) {
              Navigator.of(context).pop();
            }
            context.showSnackBar(state.actionMessage!, isError: false);
          } else if (state.actionDetailsStatus ==
              ShelfDetailsActionStatus.error) {
            context.showSnackBar(state.actionMessage!, isError: true);
          }

          if (state.status == ShelfDetailsStatus.error) {
            context.showSnackBar(
              "${localizations.errorLoadingData}: ${state.errorMessage}",
              isError: true,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.currentShelfDetail?.name ?? localizations.loading,
              ),
              actions: [
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: const Icon(Icons.edit_rounded),
                  ),
                  tooltip: localizations.editShelf,
                  onPressed:
                      () => _showEditShelfDialog(context, state, localizations),
                ),
                IconButton(
                  icon: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: const Icon(Icons.delete_rounded),
                  ),
                  tooltip: localizations.deleteShelf,
                  onPressed:
                      () =>
                          _showDeleteShelfDialog(context, state, localizations),
                ),
              ],
            ),
            body: _buildBody(context, state, localizations),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ShelfDetailsState state,
    AppLocalizations localizations,
  ) {
    if (state.status == ShelfDetailsStatus.loading) {
      return _buildLoadingSkeleton(context, localizations);
    }

    if (state.status == ShelfDetailsStatus.error) {
      return _buildErrorWidget(context, state, localizations);
    }

    if (state.currentShelfDetail == null) {
      return _buildEmptyState(context, localizations);
    }

    if (state.currentShelfDetail!.books.isEmpty) {
      return _buildEmptyShelfState(context, localizations);
    }

    return _buildBookGrid(context, state.currentShelfDetail!, localizations);
  }

  Widget _buildLoadingSkeleton(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final dummyBooks = List.generate(
      6,
      (index) => ShelfBookItem(
        id: 'dummy-$index',
        title: 'Loading Book Title',
        authors: [BookAuthor(name: 'Loading Author', id: 'author-id')],
        seriesName: index % 2 == 0 ? 'Loading Series' : null,
        seriesIndex: index % 2 == 0 ? '1' : null,
      ),
    );

    final dummyShelf = ShelfDetailsModel(
      name: 'Loading Shelf...',
      books: dummyBooks,
    );

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
      ),
      child: _buildBookGrid(context, dummyShelf, localizations),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    ShelfDetailsState state,
    AppLocalizations localizations,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ShelfDetailsBloc>().add(LoadShelfDetails(shelfId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 3),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.errorLoadingData,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(state.errorMessage ?? localizations.unknownError),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      () => context.read<ShelfDetailsBloc>().add(
                        LoadShelfDetails(shelfId),
                      ),
                  child: Text(localizations.tryAgain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ShelfDetailsBloc>().add(LoadShelfDetails(shelfId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 3),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.shelfNotFound,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyShelfState(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ShelfDetailsBloc>().add(LoadShelfDetails(shelfId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 3),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: .5),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.shelfIsEmpty,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  localizations.addBooksToShelf,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: .7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookGrid(
    BuildContext context,
    ShelfDetailsModel shelf,
    AppLocalizations localizations,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ShelfDetailsBloc>().add(LoadShelfDetails(shelfId));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.shelfContains(shelf.books.length),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.6,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildBookItem(context, shelf.books[index], localizations),
                childCount: shelf.books.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildBookItem(
    BuildContext context,
    ShelfBookItem book,
    AppLocalizations localizations,
  ) {
    return Card(
      elevation: 4.0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        // TODO: Implement navigation to book details page
        // () => Navigator.of(context).push(
        //   AppTransitions.createSlideRoute(
        //     BookDetailsPage(bookUuid: book.id),
        //   ),
        // ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Expanded(child: BookCoverImage(bookId: book.id)),
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
                    book.authors.map((a) => a.name).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  if (book.seriesName != null)
                    Text(
                      '${book.seriesName} ${book.seriesIndex ?? ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditShelfDialog(
    BuildContext context,
    ShelfDetailsState state,
    AppLocalizations localizations,
  ) {
    if (state.currentShelfDetail == null) return;

    showDialog(
      context: context,
      builder:
          (dialogContext) => EditShelfDialog(
            currentName: state.currentShelfDetail!.name,
            onEditShelf: (newName) {
              context.read<ShelfDetailsBloc>().add(EditShelf(shelfId, newName));

              if (context.read<ShelfViewBloc>().state.shelves.isNotEmpty) {
                context.read<ShelfViewBloc>().add(
                  EditShelfState(shelfId, newName),
                );
              }
            },
          ),
    );
  }

  void _showDeleteShelfDialog(
    BuildContext context,
    ShelfDetailsState state,
    AppLocalizations localizations,
  ) {
    if (state.currentShelfDetail == null) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localizations.deleteShelf),
          content: Text(
            localizations.deleteShelfConfirmation(
              state.currentShelfDetail!.name,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<ShelfDetailsBloc>().add(DeleteShelf(shelfId));

                if (context.read<ShelfViewBloc>().state.shelves.isNotEmpty) {
                  context.read<ShelfViewBloc>().add(
                    RemoveShelfFromState(shelfId),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(localizations.delete),
            ),
          ],
        );
      },
    );
  }
}
