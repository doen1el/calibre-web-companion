import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/views/book_details.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BookCard extends StatelessWidget {
  final BookItem book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookDetails(bookUuid: book.uuid),
            ),
          );
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
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the cover image
  ///
  /// Parameters:
  ///
  /// - `context`: BuildContext
  /// - `bookId`: String
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
}
