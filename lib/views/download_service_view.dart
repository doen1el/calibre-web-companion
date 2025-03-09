import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/models/download_service_model.dart';
import 'package:calibre_web_companion/view_models/download_service_view_model.dart';
import 'package:calibre_web_companion/views/widgets/costum_text_field.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DownloadServiceView extends StatelessWidget {
  const DownloadServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DownloadServiceViewModel>();
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.downloadService)),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: localizations.search),
                Tab(
                  text:
                      '${localizations.downloads} ${_getDownloadsCount(viewModel)}',
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSearchTab(context, localizations, viewModel),
                  _buildDownloadsTab(context, viewModel, localizations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDownloadsCount(DownloadServiceViewModel viewModel) {
    final count = viewModel.books.length;
    return count > 0 ? '($count)' : '';
  }

  Widget _buildSearchTab(
    BuildContext context,
    AppLocalizations localizations,
    DownloadServiceViewModel viewModel,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(context, viewModel, localizations),
          if (viewModel.isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
          if (viewModel.searchResults.isNotEmpty)
            _buildBookList(
              context,
              viewModel,
              localizations,
              viewModel.searchResults,
              isSearchResults: true,
            ),
        ],
      ),
    );
  }

  Widget _buildDownloadsTab(
    BuildContext context,
    DownloadServiceViewModel viewModel,
    AppLocalizations localizations,
  ) {
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
                  onPressed: () => viewModel.getDownloadStatus(),
                ),
              ],
            ),
          ),
          if (viewModel.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
          if (viewModel.error != null)
            _buildErrorMessage(context, viewModel.error!),
          if (!viewModel.isLoading && viewModel.error == null)
            _buildBookList(context, viewModel, localizations, viewModel.books),
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

  Widget _buildSearchBar(
    BuildContext context,
    DownloadServiceViewModel viewModel,
    AppLocalizations localizations,
  ) {
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
              child: CostumTextField(
                context: context,
                controller: searchController,
                labelText: localizations.searchForABook,
                onSubmitted: (value) => viewModel.searchBooks(value),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => viewModel.searchBooks(searchController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList(
    BuildContext context,
    DownloadServiceViewModel viewModel,
    AppLocalizations localizations,
    List<Book> books, {
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                isSearchResults
                    ? localizations.noBooksFound
                    : localizations.noDownloadsFound,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
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
              final book = books[index];
              return _buildBookCard(
                context,
                viewModel,
                localizations,
                book,
                isSearchResults,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(
    BuildContext context,
    DownloadServiceViewModel viewModel,
    AppLocalizations localizations,
    Book book,
    bool isSearchResult,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          // Optional: Show more details or action sheet
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover and basic info header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover image
                _buildBookCover(context, book),

                // Book details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          book.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Author
                        _buildInfoRow(
                          context,
                          Icons.person,
                          book.author,
                          Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 4),

                        // Publisher
                        _buildInfoRow(
                          context,
                          Icons.business,
                          book.publisher,
                          Theme.of(context).colorScheme.secondary,
                          textStyle: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),

                        // Year - only show if we have a valid year
                        if (book.year > 0) ...[
                          _buildInfoRow(
                            context,
                            Icons.calendar_today,
                            book.year.toString(),
                            Theme.of(context).colorScheme.secondary,
                            textStyle: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                        ],

                        // Format, size and language badges
                        _buildInfoBadges(context, book),

                        // Status indicator (only for downloads)
                        if (!isSearchResult &&
                            book.status !=
                                DownloadServiceStatus.notDownloaded) ...[
                          const SizedBox(height: 8),
                          _buildStatusIndicator(context, localizations, book),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Show error message if applicable
            if (!isSearchResult &&
                book.status == DownloadServiceStatus.error &&
                book.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  '${localizations.error}: ${book.errorMessage}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(
                  context,
                  viewModel,
                  localizations,
                  book,
                  isSearchResult,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    DownloadServiceViewModel viewModel,
    AppLocalizations localizations,
    Book book,
    bool isSearchResult,
  ) {
    final buttons = <Widget>[];

    if (isSearchResult) {
      // For search results, show download button
      buttons.add(
        ElevatedButton(
          onPressed: () async {
            await viewModel.downloadBook(book.id);
            await viewModel.getDownloadStatus();
            Fluttertoast.showToast(
              msg: localizations.addedBookToTheDownloadQueue,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
          child: Text(
            localizations.download,
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
        ),
      );
    } else {
      // For downloads, show status-specific buttons
      switch (book.status) {
        case DownloadServiceStatus.error:
          buttons.add(
            ElevatedButton.icon(
              onPressed: () => viewModel.downloadBook(book.id),
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.onError,
              ),
              label: Text(
                localizations.retry,
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          );
          break;
        case DownloadServiceStatus.done:
          break;
        default:
          break;
      }
    }

    return buttons;
  }

  Widget _buildBookCover(BuildContext context, Book book) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12.0),
        bottomLeft: Radius.circular(0.0),
      ),
      child: SizedBox(
        width: 120,
        height: 180,
        child:
            book.preview.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: book.preview,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => _buildCoverPlaceholder(context),
                  maxWidthDiskCache: 120,
                  maxHeightDiskCache: 180,
                )
                : _buildCoverPlaceholder(context),
      ),
    );
  }

  Widget _buildCoverPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text,
    Color iconColor, {
    TextStyle? textStyle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadges(BuildContext context, Book book) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (book.format.isNotEmpty)
          _buildInfoBadge(
            context,
            book.format.toUpperCase(),
            color: Theme.of(context).colorScheme.primaryContainer,
            textColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        if (book.size.isNotEmpty)
          _buildInfoBadge(
            context,
            book.size,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            textColor: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        if (book.language.isNotEmpty)
          _buildInfoBadge(
            context,
            book.language.toUpperCase(),
            color: Theme.of(context).colorScheme.secondaryContainer,
            textColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
      ],
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    AppLocalizations localizations,
    Book book,
  ) {
    // Get status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (book.status) {
      case DownloadServiceStatus.available:
        statusColor = Colors.blue;
        statusIcon = Icons.download_rounded;
        statusText = localizations.available;
        break;
      case DownloadServiceStatus.downloading:
        statusColor = Colors.amber;
        statusIcon = Icons.downloading_rounded;
        statusText = localizations.downloading;
        break;
      case DownloadServiceStatus.done:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline_rounded;
        statusText = localizations.completed;
        break;
      case DownloadServiceStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline_rounded;
        statusText = localizations.failed;
        break;
      case DownloadServiceStatus.queued:
        statusColor = Colors.purple;
        statusIcon = Icons.queue_rounded;
        statusText = localizations.queued;
        break;
      case DownloadServiceStatus.notDownloaded:
        statusColor = Colors.grey;
        statusIcon = Icons.download_rounded;
        statusText = localizations.notDownloaded;
        break;
    }

    return Row(
      children: [
        Icon(statusIcon, size: 16, color: statusColor),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(
    BuildContext context,
    String text, {
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
