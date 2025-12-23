import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_event.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_state.dart';

import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';
import 'package:calibre_web_companion/shared/widgets/book_card_skeleton_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_card_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_list_tile_widget.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_view/presentation/widgets/search_dialog.dart';

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
              (current.hasError && !previous.hasError),
      listener: (context, state) {
        if (state.uploadStatus == UploadStatus.loading ||
            state.uploadStatus == UploadStatus.uploading) {
          _showUploadStatusSheet(context, localizations);
        }

        if (state.hasError) {
          context.showSnackBar(state.errorMessage, isError: true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.books),
            actions: [
              _buildColumnSelector(context, state, localizations),
              _buildSortOptions(context, localizations),
              _buildSearchButton(context),
            ],
          ),
          body: _buildBody(context, state, localizations),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _pickAndUploadBook(context, localizations),
            tooltip: localizations.uploadEbook,
            child: const Icon(Icons.upload_rounded),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    BookViewState state,
    AppLocalizations localizations,
  ) {
    // TODO: Add Book List Skeleton for when loading in List View
    if (state.books.isEmpty && state.isLoading) {
      return _buildBookGridSkeletons(state);
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
                    onTap: () {
                      Navigator.of(context).push(
                        AppTransitions.createSlideRoute(
                          BookDetailsPage(
                            bookViewModel: book,
                            bookUuid: book.uuid,
                          ),
                        ),
                      );
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
                    onTap: () {
                      Navigator.of(context).push(
                        AppTransitions.createSlideRoute(
                          BookDetailsPage(
                            bookViewModel: book,
                            bookUuid: book.uuid,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
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

  Widget _buildColumnSelector(
    BuildContext context,
    BookViewState state,
    AppLocalizations localizations,
  ) {
    return PopupMenuButton<dynamic>(
      icon: Icon(
        state.isListView ? Icons.view_list_rounded : Icons.grid_view_rounded,
      ),
      tooltip: localizations.columnsCount,
      onSelected: (dynamic value) {
        if (value == 'list') {
          context.read<BookViewBloc>().add(const SetViewMode(true));
        } else if (value is int) {
          context.read<BookViewBloc>().add(ChangeColumnCount(value));
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'list',
              child: Row(
                children: [
                  Icon(
                    Icons.view_list,
                    color:
                        state.isListView
                            ? Theme.of(context).colorScheme.primary
                            : null,
                  ),
                  const SizedBox(width: 8),
                  Text(localizations.listView),
                ],
              ),
            ),
            const PopupMenuDivider(),
            for (int i = 1; i <= 5; i++)
              PopupMenuItem<int>(
                value: i,
                child: Row(
                  children: [
                    Icon(
                      i == 1
                          ? Icons.looks_one
                          : i == 2
                          ? Icons.looks_two
                          : i == 3
                          ? Icons.looks_3
                          : i == 4
                          ? Icons.looks_4
                          : Icons.looks_5,
                      color:
                          !state.isListView && state.columnCount == i
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                    const SizedBox(width: 8),
                    Text('$i ${localizations.columns}'),
                  ],
                ),
              ),
          ],
    );
  }

  Widget _buildSortOptions(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
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
          ],
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () async {
        final searchQuery = await showDialog<String>(
          context: context,
          builder: (context) => const SearchDialog(),
        );

        if (searchQuery != null) {
          if (!context.mounted) return;
          context.read<BookViewBloc>().add(SearchBooks(searchQuery));
        }
      },
    );
  }

  Future<void> _pickAndUploadBook(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    final result = await FilePicker.platform.pickFiles(
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
