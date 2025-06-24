import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';

class BookCard extends StatelessWidget {
  final BookViewModel book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            AppTransitions.createSlideRoute(
              BookDetailsPage(bookListModel: book, bookUuid: book.uuid),
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
                    book.authors,
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

  Widget _buildCoverImage(BuildContext context, int bookId) {
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
              child: SizedBox(),
            ),
          ),
      errorWidget: (context, url, error) => const SizedBox(),
      memCacheWidth: 300,
      memCacheHeight: 400,
    );
  }
}
