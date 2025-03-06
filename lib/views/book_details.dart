import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/view_models/book_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: _buildBookDetails(context, viewModel, book),
          // floatingActionButton: FloatingActionButton.extended(
          //   onPressed: () => _showDownloadOptions(context, viewModel, book),
          //   icon: const Icon(Icons.download_rounded),
          //   label: const Text('Download'),
          // ),
        );
      },
    );
  }

  Widget _buildBookDetails(
    BuildContext context,
    BookDetailsViewModel viewModel,
    BookItem book,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverImage(context, book.id),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Author section
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'by ${book.author}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                // // Rating section
                // if (book.ratings.isNotEmpty) ...[
                //   const SizedBox(height: 12),
                //   _buildRating(double.parse(book.ratings)),
                // ],

                // // Publication Info section
                // const SizedBox(height: 24),
                // _buildInfoSection(context, 'Publication Info', [
                //   if (book.pubdate.isNotEmpty)
                //     _buildInfoRow(
                //       context,
                //       'Published',
                //       _formatDate(book.pubdate),
                //     ),
                //   if (book.timestamp.isNotEmpty)
                //     _buildInfoRow(
                //       context,
                //       'Added',
                //       _formatDate(book.timestamp),
                //     ),
                //   if (book.series.isNotEmpty)
                //     _buildInfoRow(context, 'Series', book.series),
                //   if (book.languages.isNotEmpty)
                //     _buildInfoRow(
                //       context,
                //       'Language',
                //       _formatLanguages(book.languages),
                //     ),
                // ]),

                // // File Info section
                // const SizedBox(height: 16),
                // _buildInfoSection(context, 'File Info', [
                //   _buildInfoRow(context, 'Format', book.formats.join(', ')),
                //   if (book.formats.isNotEmpty)
                //     _buildInfoRow(context, 'Size', _formatSize(book)),
                //   _buildInfoRow(context, 'ID', book.uuid),
                // ]),

                // // Tags section
                // if (book.tags.isNotEmpty) ...[
                //   const SizedBox(height: 24),
                //   Text(
                //     'Tags',
                //     style: Theme.of(context).textTheme.titleMedium?.copyWith(
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                //   const SizedBox(height: 8),
                //   _buildTags(context, book.tags),
                // ],

                // // Description section
                // if (book.comments.isNotEmpty) ...[
                //   const SizedBox(height: 24),
                //   Text(
                //     'Description',
                //     style: Theme.of(context).textTheme.titleMedium?.copyWith(
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                //   const SizedBox(height: 8),
                //   Text(_stripHtml(book.comments)),
                // ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create info sections
  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final validChildren = children.toList();
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

  // Helper method to create info rows
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Format helpers
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatLanguages(List<String> language) {
    // Map language codes to full names
    const languageMap = {
      'eng': 'English',
      'deu': 'German',
      'fra': 'French',
      'spa': 'Spanish',
      'ita': 'Italian',
      // Add more as needed
    };

    return language
        .map((lang) => languageMap[lang.toLowerCase()] ?? lang)
        .join(', ');
  }

  String _formatSize(BookItem book) {
    try {
      // Extract size from format_metadata if available in your BookModel
      final size =
          2385074; // Hard-coded from your example, ideally from the model
      if (size < 1024) return '$size B';
      if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return '';
    }
  }

  String _stripHtml(String html) {
    // A simple HTML tag stripper
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  Widget _buildCoverImage(BuildContext context, String bookId) {
    ApiService apiService = ApiService();
    final baseUrl = apiService.getBaseUrl();
    final username = apiService.getUsername();
    final password = apiService.getPassword();

    // Basic Auth Header in Base64 generieren
    final authHeader =
        'Basic ${base64.encode(utf8.encode('$username:$password'))}';
    final coverUrl = '$baseUrl/opds/cover/$bookId';

    return CachedNetworkImage(
      imageUrl: coverUrl,
      httpHeaders: {'Authorization': authHeader},
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder:
          (context, url) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget:
          (context, url, error) =>
              const Center(child: Icon(Icons.book, size: 64)),
      // Cache Einstellungen optimieren
      memCacheWidth: 300, // Speichereffizienz verbessern
      memCacheHeight: 400,
    );
  }

  Widget _buildTags(BuildContext context, List<String> tags) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            tags
                .map(
                  (tag) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(tag),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildRating(double rating) {
    return Row(
      children: List.generate(
        10,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
        ),
      ),
    );
  }

  Widget _buildLanguages(List<String> languages) {
    return Row(
      children:
          languages
              .map(
                (language) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(label: Text(language)),
                ),
              )
              .toList(),
    );
  }

  // Add this method to your BookDetails class
  // void _showDownloadOptions(
  //   BuildContext context,
  //   BookDetailsViewModel viewModel,
  //   BookItem book,
  // ) {
  //   viewModel.downloadBook(book.id, format: 'epub');
  //   if (book.formats.length == 1) {
  //     // If only one format, download directly
  //     viewModel.downloadBook(book.id, format: book.formats[0].toLowerCase());
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text('Download started...')));
  //     return;
  //   }

  //   // Otherwise show format options
  //   showModalBottomSheet(
  //     context: context,
  //     builder:
  //         (context) => SafeArea(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               ListTile(
  //                 title: const Text('Download Format'),
  //                 leading: const Icon(Icons.download),
  //               ),
  //               const Divider(),
  //               ...book.formats.map((format) {
  //                 IconData icon;
  //                 switch (format.toLowerCase()) {
  //                   case 'epub':
  //                     icon = Icons.menu_book;
  //                     break;
  //                   case 'pdf':
  //                     icon = Icons.picture_as_pdf;
  //                     break;
  //                   case 'mobi':
  //                     icon = Icons.book_online;
  //                     break;
  //                   default:
  //                     icon = Icons.file_present;
  //                 }

  //                 return ListTile(
  //                   leading: Icon(icon),
  //                   title: Text(format.toUpperCase()),
  //                   onTap: () {
  //                     Navigator.pop(context);
  //                     viewModel.downloadBook(
  //                       book.id,
  //                       format: format.toLowerCase(),
  //                     );
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       SnackBar(content: Text('Downloading $format...')),
  //                     );
  //                   },
  //                 );
  //               }).toList(),
  //             ],
  //           ),
  //         ),
  //   );
  // }
}
