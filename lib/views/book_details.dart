import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/view_models/book_details_view_model.dart';
import 'package:calibre_web_companion/views/widgets/send_to_ereader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;

class BookDetails extends StatelessWidget {
  final String bookUuid;
  const BookDetails({super.key, required this.bookUuid});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<BookDetailsViewModel>(context);

    return FutureBuilder<BookItem>(
      future: viewModel.fetchBook(bookUuid: bookUuid),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading book details: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder:
                              (context) => BookDetails(
                                key: UniqueKey(),
                                bookUuid: bookUuid,
                              ),
                        ),
                      );
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle success state
        final book = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              book.title.length > 20
                  ? "${book.title.substring(0, 20)}..."
                  : book.title,
            ),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              // Bookmark toggle
              // IconButton(
              //   icon: Icon(
              //     viewModel.isBookmarked(book.id)
              //         ? Icons.bookmark
              //         : Icons.bookmark_outline,
              //     color:
              //         viewModel.isBookmarked(book.id)
              //             ? Theme.of(context).colorScheme.primary
              //             : null,
              //   ),
              //   onPressed: () => viewModel.toggleBookmark(book.id),
              //   tooltip: 'Bookmark',
              // ),
              // // Read/Unread toggle
              // IconButton(
              //   icon: Icon(
              //     viewModel.isRead(book.id)
              //         ? Icons.check_circle
              //         : Icons.check_circle_outline,
              //     color:
              //         viewModel.isRead(book.id)
              //             ? Theme.of(context).colorScheme.primary
              //             : null,
              //   ),
              //   onPressed: () => viewModel.toggleReadStatus(book.id),
              //   tooltip: 'Mark as Read',
              // ),
              // // Download button
              // IconButton(
              //   icon: const Icon(Icons.download),
              //   onPressed: () => _showDownloadOptions(context, viewModel, book),
              //   tooltip: 'Download',
              // ),
            ],
          ),
          body: _buildBookDetails(context, viewModel, book),
          // floatingActionButton: SendToEreader(book: book),
        );
      },
    );
  }

  /// Builds the book details view
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [viewModel]: The view model for the book details
  /// - [book]: The book item to display
  Widget _buildBookDetails(
    BuildContext context,
    BookDetailsViewModel viewModel,
    BookItem book,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image with gradient overlay
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              // Cover image
              _buildCoverImage(context, book.id),

              // Gradient overlay for better text visibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.5, 1.0],
                  ),
                ),
                height: 100,
                width: double.infinity,
              ),

              // Title and Author overlay
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${book.author}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Book details content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating section
                if (book.rating != null) ...[
                  _buildRating(book.rating!),
                  const SizedBox(height: 16),
                  const Divider(),
                ],

                // Series info if available
                if (book.series != null) ...[
                  _buildInfoRow(
                    context,
                    'Series',
                    book.seriesIndex != null
                        ? '${book.series} (Book ${book.seriesIndex})'
                        : book.series!,
                  ),
                  const SizedBox(height: 8),
                ],

                // Publication Info section
                _buildInfoSection(context, 'Publication Info', [
                  if (book.published != null)
                    _buildInfoRow(
                      context,
                      'Published',
                      intl.DateFormat('MMMM d, yyyy').format(book.published!),
                    ),
                  if (book.updated != null)
                    _buildInfoRow(
                      context,
                      'Updated',
                      intl.DateFormat('MMMM d, yyyy').format(book.updated!),
                    ),
                  if (book.publisher != null && book.publisher!.isNotEmpty)
                    _buildInfoRow(context, 'Publisher', book.publisher!),
                  if (book.language!.isNotEmpty)
                    _buildInfoRow(
                      context,
                      'Language',
                      _formatLanguage(book.language!),
                    ),
                ]),

                // File Info section
                const SizedBox(height: 16),
                _buildInfoSection(context, 'File Info', [
                  if (book.formats.isNotEmpty)
                    _buildInfoRow(
                      context,
                      'Format(s)',
                      book.formats.join(', '),
                    ),
                  if (book.fileSize != null)
                    _buildInfoRow(
                      context,
                      'Size',
                      _formatFileSize(book.fileSize!),
                    ),
                  _buildInfoRow(context, 'ID', book.uuid),
                ]),

                // Tags section
                if (book.categories.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTags(context, book.categories),
                ],

                // Description section
                if (book.summary!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.summary!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to create info sections
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [title]: The title of the section
  /// - [children]: The children widgets to display
  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final validChildren = children.where((w) => w is! SizedBox).toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...validChildren,
      ],
    );
  }

  /// Helper method to create info rows
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [label]: The label for the info row
  /// - [value]: The value for the info row
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  /// Formats a language code to a human-readable name
  ///
  /// Parameters:
  ///
  /// - [languageCode]: The language code to format
  String _formatLanguage(String languageCode) {
    // Maps language codes to human-readable names
    const languageMap = {
      'eng': 'English',
      'deu': 'German (Deutsch)',
      'fra': 'French (Français)',
      'spa': 'Spanish (Español)',
      'ita': 'Italian (Italiano)',
      'jpn': 'Japanese (日本語)',
      'rus': 'Russian (Русский)',
      'por': 'Portuguese (Português)',
      'chi': 'Chinese (中文)',
      'nld': 'Dutch (Nederlands)',
    };

    return languageMap[languageCode.toLowerCase()] ?? languageCode;
  }

  /// Formats a file size in bytes to a human-readable format
  ///
  /// Parameters:
  ///
  /// - [sizeInBytes]: The file size in bytes
  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Builds the cover image for the book
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [bookId]: The ID of the book to fetch the cover for
  Widget _buildCoverImage(BuildContext context, String bookId) {
    ApiService apiService = ApiService();
    final baseUrl = apiService.getBaseUrl();
    final username = apiService.getUsername();
    final password = apiService.getPassword();

    final authHeader =
        'Basic ${base64.encode(utf8.encode('$username:$password'))}';
    final coverUrl = '$baseUrl/opds/cover/$bookId';

    return SizedBox(
      height: 300,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: coverUrl,
        httpHeaders: {'Authorization': authHeader},
        fit: BoxFit.cover,
        placeholder:
            (context, url) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget:
            (context, url, error) => Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No Cover Available',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        memCacheWidth: 600,
        memCacheHeight: 900,
      ),
    );
  }

  /// Builds a list of tags
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [tags]: The list of tags to display
  Widget _buildTags(BuildContext context, List<String> tags) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            tags.map((tag) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  label: Text(tag),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
      ),
    );
  }

  /// Builds a rating widget
  ///
  /// Parameters:
  ///
  /// - [rating]: The rating to display
  Widget _buildRating(double rating) {
    final int filledStars = rating.floor();
    final bool hasHalfStar = (rating - filledStars) >= 0.5;
    final int maxStars = 10;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < maxStars; i++)
          Icon(
            i < filledStars
                ? Icons.star
                : (i == filledStars && hasHalfStar)
                ? Icons.star_half
                : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        const SizedBox(width: 8),
        Text(
          '${rating.toStringAsFixed(1)} / $maxStars',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  /// Shows download options for a book
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [viewModel]: The view model for the book details
  /// - [book]: The book item to download
  void _showDownloadOptions(
    BuildContext context,
    BookDetailsViewModel viewModel,
    BookItem book,
  ) {
    if (book.formats.length == 1) {
      // If only one format is available, download it directly
      _downloadBook(context, viewModel, book, book.formats[0]);
      return;
    }

    // Show modal bottom sheet with download options
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Download Format'),
                  leading: const Icon(Icons.download),
                ),
                const Divider(),
                ...book.formats.map((format) {
                  IconData icon;
                  switch (format.toLowerCase()) {
                    case 'epub':
                      icon = Icons.menu_book;
                      break;
                    case 'pdf':
                      icon = Icons.picture_as_pdf;
                      break;
                    case 'mobi':
                      icon = Icons.book_online;
                      break;
                    default:
                      icon = Icons.file_present;
                  }

                  return ListTile(
                    leading: Icon(icon),
                    title: Text(format.toUpperCase()),
                    onTap: () {
                      Navigator.pop(context);
                      _downloadBook(context, viewModel, book, format);
                    },
                  );
                }),
              ],
            ),
          ),
    );
  }

  /// Downloads a book in a specific format
  ///
  /// Parameters:
  ///
  /// - [context]: The current build context
  /// - [viewModel]: The view model for the book details
  /// - [book]: The book item to download
  /// - [format]: The format to download the book in
  void _downloadBook(
    BuildContext context,
    BookDetailsViewModel viewModel,
    BookItem book,
    String format,
  ) {
    // Start download
    viewModel.downloadBook(book.id, book.title);

    // Show snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${book.title} (${format.toUpperCase()})'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => viewModel.openDownloads(),
        ),
      ),
    );
  }
}
