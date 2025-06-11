import 'dart:io';

import '../utils/snack_bar.dart';
import 'widgets/book_card.dart';
import 'widgets/book_card_skeleton.dart';
import 'widgets/search_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../view_models/books_view_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum UploadStatus { loading, uploading, success, failed }

class CancellationToken {
  bool _isCancelled = false;

  /// Cancel the operation associated with this token
  void cancel() {
    _isCancelled = true;
  }

  /// Check if the token has been cancelled
  bool get isCancelled => _isCancelled;
}

class BooksView extends StatefulWidget {
  const BooksView({super.key});

  @override
  State<BooksView> createState() => _BookListViewState();
}

class _BookListViewState extends State<BooksView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksViewModel>().loadSettings();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  /// Listener for infinite scrolling
  void _scrollListener() {
    final viewModel = Provider.of<BooksViewModel>(context, listen: false);
    if (!viewModel.isLoading &&
        viewModel.hasMoreBooks &&
        _scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500) {
      viewModel.fetchMoreBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<BooksViewModel>();
    AppLocalizations localizations = AppLocalizations.of(context)!;

    if (viewModel.hasError) {
      context.showSnackBar(viewModel.errorMessage, isError: true);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.books),
        actions: [
          _buildColumnSelector(viewModel, localizations),
          _buildSortOptions(viewModel, localizations),
          _buildSearchButton(viewModel),
        ],
      ),
      body: Consumer<BooksViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.books.isEmpty && viewModel.isLoading) {
            return _buildBookGridSkeletons();
          }

          if (viewModel.books.isEmpty && viewModel.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizations.errorLoadingBooks,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(viewModel.errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.refreshBooks(),
                    child: Text(localizations.tryAgain),
                  ),
                ],
              ),
            );
          }

          if (viewModel.books.isEmpty) {
            return Center(child: Text(localizations.noBooksFound));
          }

          return _buildRefreshIndicatorAndGridView(viewModel);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final viewModel = context.read<BooksViewModel>();
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['epub', 'mobi', 'pdf'],
            allowMultiple: false,
          );

          if (result == null || result.files.isEmpty) {
            // ignore: use_build_context_synchronously
            context.showSnackBar(localizations.noFilesSelected, isError: true);
            return;
          }

          final book = File(result.files.single.path!);
          // ignore: use_build_context_synchronously
          _uploadEbook(context, localizations, viewModel, book);
        },
        tooltip: localizations.uploadEbook,

        child: Icon(Icons.upload_rounded),
      ),
    );
  }

  /// Builds the column selector popup menu
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The view model to use
  /// - `localizations`: The localizations to use
  Widget _buildColumnSelector(
    BooksViewModel viewModel,
    AppLocalizations localizations,
  ) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.grid_view_rounded),
      tooltip: localizations.columnsCount,
      onSelected: (int value) {
        viewModel.setColumnCount(value);
      },
      itemBuilder:
          (context) => [
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
                          viewModel.columnCount.toInt() == i
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

  Widget _buildBookGridSkeletons() {
    final viewModel = context.read<BooksViewModel>();
    final double aspectRatio = viewModel.columnCount <= 2 ? 0.7 : 0.9;

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: viewModel.columnCount.toInt(),
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

  /// Builds the sort options popup menu
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The view model to use
  Widget _buildSortOptions(
    BooksViewModel viewModel,
    AppLocalizations localizations,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: (String value) {
        final sortParts = value.split(':');
        if (sortParts.length == 2) {
          viewModel.setSorting(sortParts[0], sortParts[1]);
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
            // TODO: Fix sorting by added ascending
            // PopupMenuItem(
            //   value: 'added:asc',
            //   child: Text(localizations.oldestFirst),
            // ),
          ],
    );
  }

  /// Builds the search button
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The view model to use
  Widget _buildSearchButton(BooksViewModel viewModel) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () async {
        final searchQuery = await showDialog<String>(
          context: context,
          builder: (context) => SearchDialog(),
        );

        if (searchQuery != null) {
          viewModel.setSearchQuery(searchQuery);
        }
      },
    );
  }

  /// Builds the refresh indicator and grid view
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The view model to use
  Widget _buildRefreshIndicatorAndGridView(BooksViewModel viewModel) {
    final double aspectRatio = viewModel.columnCount <= 2 ? 0.7 : 0.9;

    return RefreshIndicator(
      onRefresh: () => viewModel.refreshBooks(),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: viewModel.columnCount.toInt(),
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount:
            viewModel.hasMoreBooks
                ? viewModel.books.length + 1
                : viewModel.books.length,
        itemBuilder: (context, index) {
          if (index == viewModel.books.length) {
            return BookCardSkeleton();
          }
          return BookCard(book: viewModel.books[index]);
        },
      ),
    );
  }

  /// Send the book to the e-reader using the provided code
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `viewModel`: The view model to use for downloading the book
  /// - `book`: The book to send
  /// - `code`: The 4-digit code to use for the transfer
  Future<void> _uploadEbook(
    BuildContext context,
    AppLocalizations localizations,
    BooksViewModel viewModel,
    File book,
  ) async {
    var logger = Logger();

    // Create transfer status notifier
    final transferStatus = ValueNotifier<UploadStatus>(UploadStatus.loading);
    String? errorMessage;

    final cancelToken = CancellationToken();

    // Show progress dialog
    _showUploadStatusSheet(
      context,
      localizations,
      transferStatus,
      errorMessage,
      () {
        cancelToken.cancel();
      },
    );

    try {
      logger.i("Starting upload process");

      transferStatus.value = UploadStatus.uploading;

      // Upload to send2ereader
      final result = await viewModel.uploadEbookToCalibre(book, cancelToken);

      transferStatus.value =
          result ? UploadStatus.success : UploadStatus.failed;

      if (result) {
        viewModel.refreshBooks();
      }
      logger.i("Set status to ${result ? 'success' : 'failed'}");
    } catch (e) {
      logger.e("Error in _sendToEReader: $e");
      errorMessage = e.toString();

      transferStatus.value = UploadStatus.failed;
    }
  }

  /// Show the transfer status sheet
  ///
  /// Parameters:
  ///
  /// - `context`: The current build context
  /// - `status`: The transfer status notifier
  /// - `errorMessage`: The error message to display
  void _showUploadStatusSheet(
    BuildContext context,
    AppLocalizations localizations,
    ValueNotifier<UploadStatus> status,
    String? errorMessage,
    VoidCallback? onCancel,
  ) {
    showModalBottomSheet(
      context: context,

      isDismissible: false,
      enableDrag: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: ValueListenableBuilder<UploadStatus>(
            valueListenable: status,
            builder: (context, currentStatus, _) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status icon
                      _buildStatusIcon(currentStatus),
                      const SizedBox(height: 20),

                      // Status text
                      Text(
                        _getStatusMessage(currentStatus, localizations),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Error message if available
                      if (errorMessage != null &&
                          currentStatus == UploadStatus.failed)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            errorMessage,
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Progress indicator for loading states
                      if (currentStatus == UploadStatus.loading ||
                          currentStatus == UploadStatus.uploading)
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
                              // If operation is in progress, call cancellation
                              if (currentStatus == UploadStatus.loading ||
                                  currentStatus == UploadStatus.uploading) {
                                if (onCancel != null) onCancel();
                              }

                              // Close the sheet
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
                                    currentStatus == UploadStatus.success ||
                                            currentStatus == UploadStatus.failed
                                        ? Icons.close
                                        : Icons.cancel_rounded,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    currentStatus == UploadStatus.success ||
                                            currentStatus == UploadStatus.failed
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
    );
  }

  /// Build the status icon based on the current status
  /// Parameters:
  ///
  /// - `status`: The current transfer status
  Widget _buildStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.loading:
        return const CircularProgressIndicator();
      case UploadStatus.uploading:
        return const Icon(Icons.upload_rounded, size: 48);
      case UploadStatus.success:
        return const Icon(Icons.check_circle, size: 48);
      case UploadStatus.failed:
        return const Icon(Icons.error_outline, size: 48);
    }
  }

  /// Get the status message based on the current status
  ///
  /// Parameters:
  ///
  /// - `status`: The current transfer status
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
        return localizations.successfullySentToEReader;
      case UploadStatus.failed:
        return localizations.uploadFailed;
    }
  }
}
