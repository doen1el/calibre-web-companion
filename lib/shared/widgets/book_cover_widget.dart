import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/image_cache_manager.dart';

class BookCoverWidget extends StatelessWidget {
  final int bookId;

  const BookCoverWidget({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final coverUrl = '${apiService.getBaseUrl()}/opds/cover/$bookId';

    return CachedNetworkImage(
      cacheManager: CustomCacheManager(),
      imageUrl: coverUrl,
      key: ValueKey(bookId),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => _buildPlaceholder(context),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(77),
      child: Skeletonizer(
        enabled: true,
        effect: ShimmerEffect(
          baseColor: Theme.of(context).colorScheme.primary.withAlpha(51),
          highlightColor: Theme.of(context).colorScheme.primary.withAlpha(102),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(77),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
          size: 40,
        ),
      ),
    );
  }
}
