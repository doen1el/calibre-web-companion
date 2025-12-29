import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    return FutureBuilder<Map<String, String>>(
      future: _getHeaders(apiService),
      builder: (context, snapshot) {
        final headers = snapshot.data ?? const <String, String>{};

        return CachedNetworkImage(
          cacheManager: CustomCacheManager(),
          imageUrl: coverUrl,
          httpHeaders: headers,
          key: ValueKey(bookId),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => _buildPlaceholder(context),
          errorWidget: (context, url, error) => _buildErrorWidget(context),
        );
      },
    );
  }

  Future<Map<String, String>> _getHeaders(ApiService api) async {
    final headers = <String, String>{};

    final cookieHeaders = api.getAuthHeaders(authMethod: AuthMethod.cookie);
    if (cookieHeaders.containsKey('Cookie')) {
      headers['Cookie'] = cookieHeaders['Cookie']!;
    }

    final username = api.getUsername();
    final password = api.getPassword();
    if (username.isNotEmpty && password.isNotEmpty) {
      headers['Authorization'] =
          'Basic ${base64.encode(utf8.encode('$username:$password'))}';
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final headersJson = prefs.getString('custom_login_headers') ?? '[]';
      final List<dynamic> decodedList = jsonDecode(headersJson);

      for (final dynamic item in decodedList) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          String? key;
          String? value;

          if (map.containsKey('key') && map.containsKey('value')) {
            key = map['key']?.toString();
            value = map['value']?.toString();
          } else if (map.isNotEmpty) {
            key = map.keys.first;
            value = map.values.first;
          }

          if (key != null && value != null) {
            if (value.contains('\${USERNAME}') && username.isNotEmpty) {
              value = value.replaceAll('\${USERNAME}', username);
            }
            headers[key] = value;
          }
        }
      }
    } catch (e) {
      // Error parsing custom headers; proceed without them
    }

    headers['Accept'] =
        'image/avif;q=0,image/webp;q=0,image/jpeg,image/png,*/*;q=0.5';
    headers['Cache-Control'] = 'no-transform';

    return headers;
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
