import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_bloc.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_event.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_state.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/main.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_book_item_model.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';
import 'package:calibre_web_companion/features/shelf_details/presentation/widgets/edit_shelf_dialog_widget.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

class ShelfDetailsPage extends StatelessWidget {
  final String shelfId;
  final String shelfTitle;
  final bool isPublic;

  const ShelfDetailsPage({
    super.key,
    required this.shelfId,
    required this.shelfTitle,
    required this.isPublic,
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

          return Scaffold(
            appBar: AppBar(
              title: Text(showPublic ? "$displayTitle (Public)" : displayTitle),
              actions:
                  state.isOpds
                      ? []
                      : [
                        IconButton(
                          icon: CircleAvatar(
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
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
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
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
        uuid: 'dummy-uuid-$index',
        title: 'Loading Book Title',
        authors: 'Loading Author',
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
        context.read<ShelfDetailsBloc>().add(
          LoadShelfDetails(shelfId, shelfTitle: shelfTitle),
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
                        LoadShelfDetails(shelfId, shelfTitle: shelfTitle),
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
          LoadShelfDetails(shelfId, shelfTitle: shelfTitle),
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
          LoadShelfDetails(shelfId, shelfTitle: shelfTitle),
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
    AppLocalizations localizations,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ShelfDetailsBloc>().add(
          LoadShelfDetails(shelfId, shelfTitle: shelfTitle),
        );
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
    return BlocBuilder<ShelfDetailsBloc, ShelfDetailsState>(
      builder: (context, state) {
        final bool isLoading = state.loadingBookId == book.id;

        return Card(
          elevation: 4.0,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookDetailsPage(
                        bookViewModel: BookViewModel(
                          id: int.parse(book.id),
                          uuid: book.uuid,
                          title: book.title,
                          authors: book.authors.toString(),
                          coverUrl: book.coverUrl,
                        ),
                        bookUuid: book.uuid,
                      ),
                ),
              );
            },

            child: Stack(
              children: [
                _buildCoverImage(context, book.id, book.coverUrl),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCoverImage(context, book.id, book.coverUrl),
                    ),
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
                            book.authors,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildCoverImage(
    BuildContext context,
    String bookId,
    String? coverUrl,
  ) {
    final apiService = ApiService();
    final baseUrl = apiService.getBaseUrl();

    String imageUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      final cleanCoverURL = coverUrl.split("/api/v1/opds/").last;
      imageUrl = '$baseUrl/$cleanCoverURL';
    } else {
      imageUrl = '$baseUrl/opds/cover/$bookId';
    }

    return FutureBuilder<Map<String, String>>(
      future: () async {
        final headers = apiService.getAuthHeaders(authMethod: AuthMethod.auto);

        final username = apiService.getUsername();
        final password = apiService.getPassword();
        if (username.isNotEmpty &&
            password.isNotEmpty &&
            !headers.containsKey('Authorization')) {
          headers['Authorization'] =
              'Basic ${base64.encode(utf8.encode('$username:$password'))}';
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          final headersJson = prefs.getString('custom_login_headers') ?? '[]';
          final List<dynamic> decodedList = jsonDecode(headersJson);

          for (final dynamic item in decodedList) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              String? key = map['key']?.toString();
              String? value = map['value']?.toString();

              if (key == null && map.isNotEmpty) {
                key = map.keys.first;
                value = map.values.first;
              }

              if (key != null && value != null) {
                if (value.contains('\${USERNAME}') && username.isNotEmpty) {
                  value = value.replaceAll('\${USERNAME}', username);
                }
                headers[key] = value;
              }
            }
          }
        } catch (e) {
          // Error loading custom headers; proceed without them
        }

        headers['Accept'] =
            'image/avif;q=0,image/webp;q=0,image/jpeg,image/png,*/*;q=0.5';
        headers['Cache-Control'] = 'no-transform';
        return headers;
      }(),
      builder: (context, snapshot) {
        final headers = snapshot.data ?? const <String, String>{};
        return CachedNetworkImage(
          imageUrl: imageUrl,
          httpHeaders: headers,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder:
              (context, url) => Container(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: .3),
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
                  child: const SizedBox(),
                ),
              ),
          errorWidget: (context, url, error) {
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.broken_image_rounded)),
            );
          },
          memCacheWidth: 300,
          memCacheHeight: 400,
        );
      },
    );
  }
}
