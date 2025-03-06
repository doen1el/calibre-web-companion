import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/api_service.dart';
import 'package:calibre_web_companion/views/book_details.dart';
import 'package:flutter/material.dart';

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
            // Cover-Bild
            Expanded(child: _buildCoverImage(context, book.id)),

            // Buch-Informationen
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
}
