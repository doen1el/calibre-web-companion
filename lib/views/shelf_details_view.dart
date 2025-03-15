import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/models/shelf_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/utils/snack_bar.dart';
import 'package:calibre_web_companion/view_models/shelf_view_model.dart';
import 'package:calibre_web_companion/views/book_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ShelfDetailsView extends StatefulWidget {
  final String shelfId;
  const ShelfDetailsView({super.key, required this.shelfId});

  @override
  ShelfDetailsViewState createState() => ShelfDetailsViewState();
}

class ShelfDetailsViewState extends State<ShelfDetailsView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = context.read<ShelfViewModel>();
        viewModel.getShelf(widget.shelfId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ShelfViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.currentShelf?.name ?? localizations.loading),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.edit_rounded),
            ),
            tooltip: localizations.editShelf,
            onPressed:
                () => _showEditShelfDialog(context, viewModel, localizations),
          ),
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.delete_rounded),
            ),
            tooltip: localizations.deleteShelf,
            onPressed:
                () => _showDeleteShelfDialog(context, viewModel, localizations),
          ),
        ],
      ),
      body: _buildBody(context, viewModel, localizations),
    );
  }

  /// Build the body of the view
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The view model to use
  /// - `localizations`: The localized strings
  Widget _buildBody(
    BuildContext context,
    ShelfViewModel viewModel,
    AppLocalizations localizations,
  ) {
    if (viewModel.isLoading) {
      return Skeletonizer(
        effect: ShimmerEffect(
          // ignore: deprecated_member_use
          baseColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          highlightColor: Theme.of(
            context,
            // ignore: deprecated_member_use
          ).colorScheme.primary.withOpacity(0.4),
        ),
        child: _buildSkeletonContent(context, localizations),
      );
    }

    if (viewModel.currentShelf!.books.isEmpty) {
      return _buildEmptyState(context, localizations);
    }

    return _buildBookGrid(
      context,
      viewModel.currentShelf!,
      localizations,
      viewModel,
    );
  }

  /// Build a empty state
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `localizations`: The localized strings
  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return RefreshIndicator(
      onRefresh: () => context.read<ShelfViewModel>().getShelf(widget.shelfId),
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
                // ignore: deprecated_member_use
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
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
                      // ignore: deprecated_member_use
                    ).colorScheme.onSurface.withOpacity(0.7),
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

  /// Build a skeleton content
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `localizations`: The localized strings
  Widget _buildSkeletonContent(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final dummyBooks = List.generate(
      6,
      (index) => ShelfBookItem(
        id: 'dummy-$index',
        title: 'Dummy Title',
        authors: [BookAuthor(name: 'Author Name', id: 'author-id')],
        seriesName: index % 2 == 0 ? 'Dummy Series' : null,
        seriesIndex: index % 2 == 0 ? '1' : null,
      ),
    );

    final dummyShelf = ShelfDetailModel(
      name: 'Loading Shelf...',
      books: dummyBooks,
    );

    return _buildBookGrid(
      context,
      dummyShelf,
      localizations,
      context.read<ShelfViewModel>(),
    );
  }

  /// Build a grid of books
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `shelf`: The shelf to build the grid for
  /// - `localizations`: The localized strings
  /// - `viewModel`: The view model to use
  Widget _buildBookGrid(
    BuildContext context,
    ShelfDetailModel shelf,
    AppLocalizations localizations,
    ShelfViewModel viewModel,
  ) {
    return RefreshIndicator(
      onRefresh: () => context.read<ShelfViewModel>().getShelf(widget.shelfId),
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
                (context, index) => _buildBookItem(
                  context,
                  shelf,
                  shelf.books[index],
                  localizations,
                  viewModel,
                ),
                childCount: shelf.books.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  /// Build a book item
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `shelf`: The shelf the book is in
  /// - `book`: The book to build the item for
  /// - `localizations`: The localized strings
  /// - `viewModel`: The view model to use
  Widget _buildBookItem(
    BuildContext context,
    ShelfDetailModel shelf,
    ShelfBookItem book,
    AppLocalizations localizations,
    ShelfViewModel viewModel,
  ) {
    final isLoading = ValueNotifier<bool>(false);

    return Card(
      elevation: 4.0,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () async {
              isLoading.value = true;

              try {
                String res = await viewModel.openBookDetails(
                  book.authors,
                  book.title,
                );

                if (res.isEmpty) {
                  // ignore: use_build_context_synchronously
                  context.showSnackBar(
                    localizations.errorLoadingBooks,
                    isError: true,
                  );
                } else {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BookDetails(bookUuid: res),
                    ),
                  );
                }
              } finally {
                isLoading.value = false;
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCoverImage(context, book.id)),

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

          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, loading, _) {
              return loading
                  ? Positioned.fill(
                    child: Container(
                      color: Theme.of(
                        context,
                        // ignore: deprecated_member_use
                      ).colorScheme.secondaryContainer.withOpacity(0.7),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  /// Build the cover image for a book
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `bookId`: The ID of the book to get the cover for
  Widget _buildCoverImage(BuildContext context, String bookId) {
    ApiService apiService = ApiService();
    final baseUrl = apiService.getBaseUrl();
    final username = apiService.getUsername();
    final password = apiService.getPassword();

    final authHeader =
        'Basic ${base64.encode(utf8.encode('$username:$password'))}';
    final coverUrl = '$baseUrl/opds/cover/$bookId';

    return CachedNetworkImage(
      imageUrl: coverUrl,
      httpHeaders: {'Authorization': authHeader},
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder:
          (context, url) => Container(
            color: Theme.of(
              context,
              // ignore: deprecated_member_use
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Skeletonizer(
              enabled: true,
              effect: ShimmerEffect(
                baseColor: Theme.of(
                  context,
                  // ignore: deprecated_member_use
                ).colorScheme.primary.withOpacity(0.2),
                highlightColor: Theme.of(
                  context,
                  // ignore: deprecated_member_use
                ).colorScheme.primary.withOpacity(0.4),
              ),
              child: SizedBox(),
            ),
          ),
      errorWidget:
          (context, url, error) =>
              const Center(child: Icon(Icons.book, size: 64)),
      memCacheWidth: 300,
      memCacheHeight: 400,
    );
  }

  /// Shows a dialog to edit the shelf name
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The view model to use
  /// - `localizations`: The localized strings
  void _showEditShelfDialog(
    BuildContext context,
    ShelfViewModel viewModel,
    AppLocalizations localizations,
  ) {
    final controller = TextEditingController(
      text: viewModel.currentShelf?.name,
    );
    bool isEditing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.editShelf),
              content: SizedBox(
                width: double.maxFinite,
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: localizations.shelfName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit_rounded),
                  ),
                  autofocus: true,
                  enabled: !isEditing,
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isEditing ? null : () => Navigator.of(context).pop(),
                  child: Text(localizations.cancel),
                ),
                ElevatedButton(
                  onPressed:
                      isEditing
                          ? null
                          : () async {
                            if (controller.text.trim().isEmpty) {
                              context.showSnackBar(
                                localizations.shelfNameRequired,
                                isError: true,
                              );

                              return;
                            }

                            setState(() {
                              isEditing = true;
                            });

                            final res = await viewModel.editShelf(
                              widget.shelfId,
                              controller.text,
                            );

                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();

                            if (res) {
                              // ignore: use_build_context_synchronously
                              context.showSnackBar(
                                localizations.successfullyEditedShelf,
                                isError: false,
                              );

                              await viewModel.getShelf(widget.shelfId);
                              await viewModel.loadShelfs();
                            } else {
                              // ignore: use_build_context_synchronously
                              context.showSnackBar(
                                localizations.failedToEditShelf,
                                isError: true,
                              );
                            }
                          },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEditing)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      if (isEditing) const SizedBox(width: 8),
                      Text(
                        isEditing ? localizations.editing : localizations.edit,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a dialog to confirm the deletion of a shelf
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The view model to use
  /// - `localizations`: The localized strings
  void _showDeleteShelfDialog(
    BuildContext context,
    ShelfViewModel viewModel,
    AppLocalizations localizations,
  ) {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.deleteShelf),
              content: Text(
                localizations.deleteShelfConfirmation(
                  viewModel.currentShelf!.name,
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isDeleting ? null : () => Navigator.of(context).pop(),
                  child: Text(localizations.cancel),
                ),
                ElevatedButton(
                  onPressed:
                      isDeleting
                          ? null
                          : () async {
                            setState(() {
                              isDeleting = true;
                            });

                            bool res = await viewModel.deleteShelf(
                              widget.shelfId,
                            );

                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();

                            if (res) {
                              // ignore: use_build_context_synchronously
                              context.showSnackBar(
                                localizations.successfullyDeletedShelf,
                                isError: false,
                              );

                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();

                              await viewModel.loadShelfs();
                            } else {
                              // ignore: use_build_context_synchronously
                              context.showSnackBar(
                                localizations.failedToDeleteShelf,
                                isError: true,
                              );
                            }
                          },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDeleting)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      if (isDeleting) const SizedBox(width: 8),
                      Text(
                        isDeleting
                            ? localizations.deleting
                            : localizations.delete,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
