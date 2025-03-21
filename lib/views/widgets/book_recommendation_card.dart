import 'package:calibre_web_companion/models/book_recommendation_model.dart';
import 'package:calibre_web_companion/view_models/settings_view_mode.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BookRecommendationCard extends StatelessWidget {
  final BookRecommendation recommendation;
  final bool isLoading;
  final int loadingRecommendationId;
  final VoidCallback onDownload;
  final VoidCallback? onTap;

  const BookRecommendationCard({
    super.key,
    required this.recommendation,
    required this.isLoading,
    required this.loadingRecommendationId,
    required this.onDownload,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: recommendation.coverUrl,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Theme.of(
                            context,
                            // ignore: deprecated_member_use
                          ).colorScheme.surfaceContainerHighest.withOpacity(
                            0.3,
                          ),
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
                    errorWidget: (context, url, error) => const SizedBox(),
                  ),
                  viewModel.isDownloaderEnabled
                      ? Positioned(
                        bottom: 8,
                        right: 8,
                        child: FloatingActionButton.small(
                          heroTag: "download_${recommendation.id}",
                          onPressed: onDownload,
                          child:
                              isLoading &&
                                      loadingRecommendationId ==
                                          recommendation.id
                                  ? SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.download_rounded),
                        ),
                      )
                      : const SizedBox(),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation.author.join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
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
      ),
    );
  }
}
