import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:calibre_web_companion/shared/widgets/app_skeletonizer.dart';

import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_bloc.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_event.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_state.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';
import 'package:calibre_web_companion/shared/widgets/book_card_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_cover_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_view_mode_selector.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/main.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_book_item_model.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';
import 'package:calibre_web_companion/features/shelf_details/presentation/widgets/edit_shelf_dialog_widget.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/presentation/pages/magic_shelf_edit_page.dart';

class ShelfDetailsPage extends StatelessWidget {
  final String shelfId;
  final String shelfTitle;
  final bool isPublic;
  final bool isMagic;
  final String? icon;

  const ShelfDetailsPage({
    super.key,
    required this.shelfId,
    required this.shelfTitle,
    required this.isPublic,
    this.isMagic = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create:
          (context) =>
              getIt<ShelfDetailsBloc>()..add(
                LoadShelfDetails(
                  shelfId,
                  shelfTitle: shelfTitle,
                  isPublic: isPublic,
                  isMagic: isMagic,
                  icon: icon,
                ),
              ),
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
          final shelf = state.currentShelfDetail;
          final bool showPublic = shelf?.isPublic ?? isPublic;

          String displayTitle = shelf?.name ?? shelfTitle;

          if (displayTitle.endsWith(' (Public)')) {
            displayTitle = displayTitle.substring(0, displayTitle.length - 9);
          }

          final scaffold = Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMagic && (state.magicIcon ?? icon) != null) ...[
                    Text(state.magicIcon ?? icon!),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(displayTitle, overflow: TextOverflow.ellipsis),
                  ),
                  if (showPublic) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.public_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              actions: [
                const BookViewModeSelector(),
                if (isMagic)
                  ..._buildMagicActions(context, localizations)
                else if (!state.isOpds) ...[
                  IconButton(
                    icon: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: const Icon(Icons.edit_rounded),
                    ),
                    tooltip: localizations.editShelf,
                    onPressed:
                        () => _showEditShelfDialog(
                          context,
                          state,
                          localizations,
                          displayTitle,
                        ),
                  ),
                  IconButton(
                    icon: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: const Icon(Icons.delete_rounded),
                    ),
                    tooltip: localizations.deleteShelf,
                    onPressed:
                        () => _showDeleteShelfDialog(
                          context,
                          state,
                          localizations,
                        ),
                  ),
                ],
              ],
            ),
            body: _buildBody(context, state, localizations),
          );

          if (!isMagic) return scaffold;

          return BlocListener<ShelfViewBloc, ShelfViewState>(
            listenWhen: (p, c) => p.magicActionStatus != c.magicActionStatus,
            listener: (context, sv) {
              if (sv.magicActionStatus == MagicShelfActionStatus.success &&
                  (sv.magicActionMessage == 'deleted' ||
                      sv.magicActionMessage == 'hidden')) {
                Navigator.of(context).pop();
              }
            },
            child: scaffold,
          );
        },
      ),
    );
  }

  List<Widget> _buildMagicActions(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    Widget action(IconData iconData, String tooltip, VoidCallback onPressed) {
      return IconButton(
        icon: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(iconData),
        ),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }

    return [
      action(
        Icons.edit_rounded,
        localizations.editMagicShelf,
        () => _openMagicEditor(context),
      ),
      PopupMenuButton<String>(
        icon: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: const Icon(Icons.more_vert_rounded),
        ),
        onSelected: (value) {
          switch (value) {
            case 'duplicate':
              context.read<ShelfViewBloc>().add(DuplicateMagicShelf(shelfId));
              break;
            case 'delete':
              _showMagicDeleteDialog(context, localizations);
              break;
          }
        },
        itemBuilder:
            (context) => [
              PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    const Icon(Icons.copy_rounded),
                    const SizedBox(width: 12),
                    Text(localizations.duplicateShelf),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(localizations.deleteShelf),
                  ],
                ),
              ),
            ],
      ),
    ];
  }

  Future<void> _openMagicEditor(BuildContext context) async {
    final shelfViewBloc = context.read<ShelfViewBloc>();
    final detailsBloc = context.read<ShelfDetailsBloc>();
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder:
            (_) => BlocProvider.value(
              value: shelfViewBloc,
              child: MagicShelfEditPage(
                shelfId: shelfId,
                fallbackName: shelfTitle,
                fallbackIcon: icon,
              ),
            ),
      ),
    );

    var newTitle = shelfTitle;
    var newIcon = icon;
    if (result is ({String name, String icon})) {
      newTitle = result.name;
      newIcon = result.icon;
    }
    detailsBloc.add(
      LoadShelfDetails(
        shelfId,
        shelfTitle: newTitle,
        isMagic: true,
        icon: newIcon,
      ),
    );
  }

  void _showMagicDeleteDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final bloc = context.read<ShelfViewBloc>();
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(localizations.deleteShelf),
            content: Text(localizations.deleteShelfConfirmation(shelfTitle)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(localizations.cancel),
              ),
              AppDialogButton.destructive(
                label: localizations.delete,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  bloc.add(DeleteMagicShelf(shelfId));
                },
              ),
            ],
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

    return _buildBookGrid(
      context,
      state.currentShelfDetail!,
      state,
      localizations,
    );
  }

  Widget _buildLoadingSkeleton(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final dummyBooks = List.generate(
      6,
      (index) => ShelfBookItem(
        id: 'dummy-$index',
        uuid: 'dummy-uuid-$index',
        title: 'Loading Book Title',
        authors: 'Loading Author',
      ),
    );

    final dummyShelf = ShelfDetailsModel(
      name: 'Loading Shelf...',
      books: dummyBooks,
    );

    return AppSkeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
      ),
      child: _buildBookGrid(
        context,
        dummyShelf,
        const ShelfDetailsState(),
        localizations,
      ),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    ShelfDetailsState state,
    AppLocalizations localizations,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ShelfDetailsBloc>().add(
          LoadShelfDetails(shelfId, shelfTitle: shelfTitle, isMagic: isMagic),
        );
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
                        LoadShelfDetails(
                          shelfId,
                          shelfTitle: shelfTitle,
                          isMagic: isMagic,
                        ),
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
        context.read<ShelfDetailsBloc>().add(
          LoadShelfDetails(shelfId, shelfTitle: shelfTitle, isMagic: isMagic),
        );
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
        context.read<ShelfDetailsBloc>().add(
          LoadShelfDetails(shelfId, shelfTitle: shelfTitle, isMagic: isMagic),
        );
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
    ShelfDetailsState state,
    AppLocalizations localizations,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ShelfDetailsBloc>().add(
          LoadShelfDetails(shelfId, shelfTitle: shelfTitle, isMagic: isMagic),
        );
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (state.hasMoreBooks &&
              !state.isLoadingMore &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 600) {
            context.read<ShelfDetailsBloc>().add(LoadMoreShelfDetails(shelfId));
          }
          return false;
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
            _buildBooksSliver(context, shelf),
            SliverToBoxAdapter(
              child: _buildPaginationFooter(context, state, localizations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(
    BuildContext context,
    ShelfDetailsState state,
    AppLocalizations localizations,
  ) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.hasMoreBooks) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<ShelfDetailsBloc>().add(
                LoadMoreShelfDetails(shelfId),
              );
            },
            icon: const Icon(Icons.expand_more_rounded),
            label: Text(localizations.loadMore),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }

  Widget _buildBooksSliver(BuildContext context, ShelfDetailsModel shelf) {
    final viewState = context.watch<BookViewBloc>().state;

    if (viewState.isListView) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildShelfBookListTile(context, shelf.books[index]),
            ),
            childCount: shelf.books.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: viewState.columnCount,
          childAspectRatio: viewState.columnCount <= 2 ? 0.7 : 0.9,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildShelfBookCard(context, shelf.books[index]),
          childCount: shelf.books.length,
        ),
      ),
    );
  }

  Widget _buildShelfBookCard(BuildContext context, ShelfBookItem book) {
    return BlocBuilder<ShelfDetailsBloc, ShelfDetailsState>(
      buildWhen:
          (previous, current) =>
              previous.loadingBookId != current.loadingBookId,
      builder: (context, state) {
        return BookCard(
          bookId: book.id,
          coverUrl: book.coverUrl,
          title: book.title,
          authors: book.authors,
          isLoading: state.loadingBookId == book.id,
          onTap: () => _openShelfBook(context, book),
        );
      },
    );
  }

  Widget _buildShelfBookListTile(BuildContext context, ShelfBookItem book) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openShelfBook(context, book),
        // Ripple feedback on long-press (no action).
        onLongPress: () {},
        child: SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: BookCoverWidget(
                  bookId: int.tryParse(book.id) ?? 0,
                  coverUrl: book.coverUrl,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.authors,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
  }

  void _openShelfBook(BuildContext context, ShelfBookItem book) {
    final cleanUuid = book.id.toLowerCase().replaceAll('urn:uuid:', '');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => BookDetailsPage(
              bookUuid: cleanUuid,
              bookViewModel: BookViewModel(
                id: 0,
                uuid: cleanUuid,
                title: book.title,
                authors: book.authors,
              ),
            ),
      ),
    );
  }

  void _showEditShelfDialog(
    BuildContext context,
    ShelfDetailsState state,
    AppLocalizations localizations,
    String cleanTitle,
  ) {
    if (state.currentShelfDetail == null) return;

    showDialog(
      context: context,
      builder:
          (dialogContext) => EditShelfDialog(
            currentName: cleanTitle,
            isPublic: state.currentShelfDetail!.isPublic,
            onEditShelf: (newName, isPublic) {
              context.read<ShelfDetailsBloc>().add(
                EditShelf(shelfId, newName, isPublic: isPublic),
              );

              if (context.read<ShelfViewBloc>().state.shelves.isNotEmpty) {
                context.read<ShelfViewBloc>().add(
                  EditShelfState(shelfId, newName, isPublic: isPublic),
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
            AppDialogButton.destructive(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<ShelfDetailsBloc>().add(DeleteShelf(shelfId));

                if (context.read<ShelfViewBloc>().state.shelves.isNotEmpty) {
                  context.read<ShelfViewBloc>().add(
                    RemoveShelfFromState(shelfId),
                  );
                }
              },
              label: localizations.delete,
            ),
          ],
        );
      },
    );
  }
}
