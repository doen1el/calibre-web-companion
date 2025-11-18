import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:calibre_web_companion/features/discover_details/data/models/discover_details_model.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';

class BookCard extends StatelessWidget {
  final String bookId;
  final String title;
  final String authors;
  final VoidCallback? onTap;
  final bool isLoading;

  const BookCard({
    super.key,
    required this.bookId,
    required this.title,
    required this.authors,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: isLoading ? null : onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child:
                        book.coverUrl != null
                            ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: FutureBuilder<Map<String, String>>(
                                future: () async {
                                  final api = ApiService();
                                  final headers = <String, String>{};
                                  final cookie = await api.getCookieHeader();
                                  if (cookie != null &&
                                      cookie.trim().isNotEmpty) {
                                    headers['Cookie'] = cookie;
                                  }
                                  final custom =
                                      await api.getProcessedCustomHeaders();
                                  headers.addAll(custom);
                                  final username = api.getUsername();
                                  final password = api.getPassword();
                                  if (username.isNotEmpty &&
                                      password.isNotEmpty) {
                                    headers['Authorization'] =
                                        'Basic ${base64.encode(utf8.encode('$username:$password'))}';
                                  }
                                  headers['Accept'] =
                                      'image/avif;q=0,image/webp;q=0,image/jpeg,image/png,*/*;q=0.5';
                                  headers['Cache-Control'] = 'no-transform';
                                  return headers;
                                }(),
                                builder: (context, snapshot) {
                                  final headers =
                                      snapshot.data ?? const <String, String>{};
                                  return CachedNetworkImage(
                                    imageUrl: book.coverUrl!,
                                    httpHeaders: headers,
                                    fit: BoxFit.cover,
                                    errorWidget:
                                        (context, error, stackTrace) =>
                                            Image.network(
                                              book.coverUrl!,
                                              headers: headers,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stack) =>
                                                      _buildPlaceholder(
                                                        context,
                                                      ),
                                            ),
                                  );
                                },
                              ),
                            )
                            : _buildPlaceholder(context),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authors,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
                    ).colorScheme.surface.withValues(alpha: .6),
                    borderRadius: borderRadius,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
