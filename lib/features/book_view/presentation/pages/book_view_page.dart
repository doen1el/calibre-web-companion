import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:get_it/get_it.dart';

import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/offline/cubit/connectivity_cubit.dart';
import 'package:calibre_web_companion/features/offline/data/services/offline_backfill_service.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_event.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_state.dart';

import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';
import 'package:calibre_web_companion/shared/widgets/book_card_skeleton_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_list_tile_skeleton_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_card_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_list_tile_widget.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_view/presentation/widgets/search_dialog.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/pages/scan_book_page.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/scan_flow.dart';
import 'package:calibre_web_companion/shared/widgets/app_options_sheet.dart';
import 'package:calibre_web_companion/shared/widgets/book_view_mode_selector.dart';

class BookViewPage extends StatefulWidget {
  const BookViewPage({super.key});

  @override
  State<BookViewPage> createState() => _BookViewPageState();
}

class _BookViewPageState extends State<BookViewPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isUploadSheetShown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final bloc = context.read<BookViewBloc>();
    final state = bloc.state;

    if (!state.isLoading &&
        state.hasMoreBooks &&
        _scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500) {
      bloc.add(const LoadMoreBooks());
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocConsumer<BookViewBloc, BookViewState>(
      listenWhen:
          (previous, current) =>
              previous.uploadStatus != current.uploadStatus ||
              (current.hasError && !previous.hasError) ||
              (previous.isLoading && !current.isLoading),
      listener: (context, state) {
        if (state.uploadStatus == UploadStatus.loading ||
            state.uploadStatus == UploadStatus.uploading) {
          _showUploadStatusSheet(context, localizations);
        }

        if (state.hasError) {
          context.showSnackBar(state.errorMessage, isError: true);
          context.read<ConnectivityCubit>().reportFailure();
        }

        if (!state.isLoading && !state.hasError && state.books.isNotEmpty) {
          GetIt.instance<OfflineBackfillService>().run();
        }
      },
      builder: (context, state) {
        final bool isSearching = (state.searchQuery ?? '').isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: isSearching ? 8 : null,
            title:
                isSearching
                    ? _buildActiveSearchBar(
                      context,
                      state.searchQuery!,
                      localizations,
                    )
                    : Text(localizations.books),
            actions: [
              if (state.multiLibrary) _buildLibrarySelector(context, state),
              const BookViewModeSelector(),
              if (!state.isOpds) _buildSortOptions(context, localizations),
              if (!isSearching) _buildSearchButton(context, localizations),
            ],
          ),
          body: _buildBody(context, state, localizations),
          floatingActionButton:
              state.canAddBooks
                  ? FloatingActionButton(
                    onPressed:
                        () => _showAddBookOptions(context, localizations),
                    tooltip: localizations.addBook,
                    child: const Icon(Icons.add_rounded),
                  )
                  : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    BookViewState state,
    AppLocalizations localizations,
  ) {
    if (state.books.isEmpty && state.isLoading) {
      if (state.isListView) {
        return _buildBookListSkeletons(context);
      } else {
        return _buildBookGridSkeletons(state);
      }
    }

    if (state.books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noBooksFound,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(localizations.books),
              onPressed: () {
                context.read<BookViewBloc>().add(const LoadBooks());
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        context.read<BookViewBloc>().add(const RefreshBooks());
        return Future.value();
      },
      child:
          state.isListView
              ? ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount:
                    state.hasMoreBooks
                        ? state.books.length + 1
                        : state.books.length,
                itemBuilder: (context, index) {
                  if (index == state.books.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final book = state.books[index];
                  return BookListTile(
                    book: book,
                    onTap: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        AppTransitions.createSlideRoute(
                          BookDetailsPage(
                            bookViewModel: book,
                            bookUuid: book.uuid,
                          ),
                        ),
                      );

                      if (!context.mounted) return;

                      if (changed == true) {
                        context.read<BookViewBloc>().add(const RefreshBooks());
                      }
                    },
                  );
                },
              )
              : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: state.columnCount,
                  childAspectRatio: state.columnCount <= 2 ? 0.7 : 0.9,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount:
                    state.hasMoreBooks
                        ? state.books.length + 1
                        : state.books.length,
                itemBuilder: (context, index) {
                  if (index == state.books.length) {
                    return const BookCardSkeleton();
                  }
                  final book = state.books[index];
                  return BookCard(
                    bookId: book.id.toString(),
                    title: book.title,
                    authors: book.authors,
                    coverUrl: book.coverUrl,
                    readStatus: book.readStatus,
                    topLeftBadge: book.seriesBadge,
                    onTap: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        AppTransitions.createSlideRoute(
                          BookDetailsPage(
                            bookViewModel: book,
                            bookUuid: book.uuid,
                          ),
                        ),
                      );

                      if (!context.mounted) return;

                      if (changed == true) {
                        context.read<BookViewBloc>().add(const RefreshBooks());
                      }
                    },
                  );
                },
              ),
    );
  }

  Widget _buildBookListSkeletons(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 10,
      itemBuilder: (context, index) {
        return const BookListTileSkeleton();
      },
    );
  }

  Widget _buildBookGridSkeletons(BookViewState state) {
    final aspectRatio = state.columnCount <= 2 ? 0.7 : 0.9;

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: state.columnCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return const BookCardSkeleton();
      },
    );
  }

  Widget _buildLibrarySelector(BuildContext context, BookViewState state) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.library_books_rounded),
      tooltip: state.libraries[state.currentLibraryId] ?? 'Library',
      onSelected: (String libraryId) {
        context.read<BookViewBloc>().add(ChangeLibrary(libraryId));
      },
      itemBuilder:
          (BuildContext context) =>
              state.libraries.entries
                  .map(
                    (entry) => CheckedPopupMenuItem<String>(
                      value: entry.key,
                      checked: entry.key == state.currentLibraryId,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
    );
  }

  Widget _buildSortOptions(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: localizations.sorting,
      onSelected: (String value) {
        final sortParts = value.split(':');
        if (sortParts.length == 2) {
          context.read<BookViewBloc>().add(
            ChangeSort(sortBy: sortParts[0], sortOrder: sortParts[1]),
          );
        }
      },
      itemBuilder:
          (BuildContext context) => [
            PopupMenuItem(
              value: 'title:asc',
              child: Text(localizations.titleAZ),
            ),
            PopupMenuItem(
              value: 'title:desc',
              child: Text(localizations.titleZA),
            ),
            PopupMenuItem(
              value: 'authors:asc',
              child: Text(localizations.authorAZ),
            ),
            PopupMenuItem(
              value: 'authors:desc',
              child: Text(localizations.authorZA),
            ),
            PopupMenuItem(
              value: 'added:desc',
              child: Text(localizations.newestFirst),
            ),
            PopupMenuItem(
              value: 'series:asc',
              child: Text(localizations.seriesAZ),
            ),
            PopupMenuItem(
              value: 'series:desc',
              child: Text(localizations.seriesZA),
            ),
          ],
    );
  }

  void _showAddBookOptions(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final canLookupMetadata =
        context.read<BookViewBloc>().state.canLookupMetadata;

    showAppOptionsSheet(
      context,
      title: localizations.addBook,
      options: [
        if (canLookupMetadata)
          AppSheetOption(
            icon: Icons.qr_code_scanner_rounded,
            title: localizations.scan,
            subtitle: localizations.scanBarcodeDescription,
            onTap: () => _openScanner(context),
          ),
        if (canLookupMetadata)
          AppSheetOption(
            icon: Icons.keyboard_rounded,
            title: localizations.enterIsbn,
            subtitle: localizations.enterIsbnDescription,
            onTap: () => _startIsbnEntry(context),
          ),
        AppSheetOption(
          icon: Icons.upload_file_rounded,
          title: localizations.uploadFromDevice,
          subtitle: localizations.uploadFromDeviceDescription,
          onTap: () => _pickAndUploadBook(context, localizations),
        ),
      ],
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final added = await Navigator.of(
      context,
    ).push<bool>(AppTransitions.createSlideRoute(const ScanBookPage()));
    if (added == true && context.mounted) {
      context.read<BookViewBloc>().add(const RefreshBooks());
    }
  }

  Future<void> _startIsbnEntry(BuildContext context) async {
    final isbn = await promptForIsbn(context);
    if (isbn == null || isbn.isEmpty || !context.mounted) return;
    final added = await runIsbnLookupFlow(context, isbn);
    if (added && context.mounted) {
      context.read<BookViewBloc>().add(const RefreshBooks());
    }
  }

  Widget _buildSearchButton(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return IconButton(
      icon: const Icon(Icons.search),
      tooltip: localizations.search,
      onPressed: () => _openSearchDialog(context),
    );
  }

  Future<void> _openSearchDialog(
    BuildContext context, {
    String? initialQuery,
  }) async {
    final searchQuery = await showDialog<String>(
      context: context,
      builder: (context) => SearchDialog(initialQuery: initialQuery),
    );
    if (searchQuery != null && context.mounted) {
      context.read<BookViewBloc>().add(SearchBooks(searchQuery));
    }
  }

  Widget _buildActiveSearchBar(
    BuildContext context,
    String query,
    AppLocalizations localizations,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSearchDialog(context, initialQuery: query),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: scheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: scheme.onSecondaryContainer,
                tooltip: localizations.clearSearch,
                onPressed: () => _clearSearch(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSearch(BuildContext context) {
    context.read<BookViewBloc>().add(const SearchBooks(''));
  }

  Future<void> _pickAndUploadBook(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'mobi', 'fb2', 'cbr', 'djvu', 'cbz'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      if (!context.mounted) return;
      context.showSnackBar(localizations.noFilesSelected, isError: true);
      return;
    }

    final file = File(result.files.single.path!);
    if (!context.mounted) return;
    context.read<BookViewBloc>().add(UploadBook(file));
  }

  void _showUploadStatusSheet(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    if (_isUploadSheetShown) return;
    _isUploadSheetShown = true;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: BlocBuilder<BookViewBloc, BookViewState>(
            buildWhen:
                (previous, current) =>
                    previous.uploadStatus != current.uploadStatus ||
                    previous.errorMessage != current.errorMessage,
            builder: (context, state) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusIcon(state.uploadStatus),
                      const SizedBox(height: 20),

                      Text(
                        _getStatusMessage(state.uploadStatus, localizations),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (state.hasError &&
                          state.uploadStatus == UploadStatus.failed)
                        Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.errorMessage,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 20),

                      if (state.uploadStatus == UploadStatus.loading ||
                          state.uploadStatus == UploadStatus.uploading)
                        LinearProgressIndicator(
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),

                      const SizedBox(height: 20),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Material(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.0),
                            onTap: () {
                              if (state.uploadStatus == UploadStatus.loading ||
                                  state.uploadStatus ==
                                      UploadStatus.uploading) {
                                context.read<BookViewBloc>().add(
                                  const UploadCancel(),
                                );
                              } else if (state.uploadStatus ==
                                      UploadStatus.success ||
                                  state.uploadStatus == UploadStatus.failed) {
                                context.read<BookViewBloc>().add(
                                  const ResetUploadStatus(),
                                );
                              }

                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    state.uploadStatus ==
                                                UploadStatus.success ||
                                            state.uploadStatus ==
                                                UploadStatus.failed
                                        ? Icons.close
                                        : Icons.cancel_rounded,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    state.uploadStatus ==
                                                UploadStatus.success ||
                                            state.uploadStatus ==
                                                UploadStatus.failed
                                        ? localizations.close
                                        : localizations.cancel,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      _isUploadSheetShown = false;
    });
  }

  Widget _buildStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.loading:
        return const CircularProgressIndicator();
      case UploadStatus.uploading:
        return const Icon(Icons.upload_rounded, size: 48);
      case UploadStatus.success:
        return Icon(
          Icons.check_circle,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        );
      case UploadStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        );
      default:
        return const SizedBox();
    }
  }

  String _getStatusMessage(
    UploadStatus status,
    AppLocalizations localizations,
  ) {
    switch (status) {
      case UploadStatus.loading:
        return localizations.preparingUpload;
      case UploadStatus.uploading:
        return localizations.uploadingBook;
      case UploadStatus.success:
        return localizations.sucessfullyUploadedBook;
      case UploadStatus.failed:
        return localizations.uploadFailed;
      default:
        return '';
    }
  }
}
