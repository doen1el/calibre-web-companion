import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

import 'package:calibre_web_companion/core/services/api_service.dart';

class _ApiServiceFileService extends FileService {
  final ApiService _apiService = ApiService();

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final http.Response response = await _apiService.get(
      endpoint: url,
      authMethod: AuthMethod.auto,
    );

    final contentType = response.headers['content-type'];
    if (response.statusCode == 200 &&
        contentType != null &&
        contentType.startsWith('image/')) {
      return _HttpFileServiceResponse(response);
    } else {
      throw HttpException(
        'Failed to load image: ${response.statusCode}, Content-Type: $contentType',
      );
    }
  }
}

class _HttpFileServiceResponse extends FileServiceResponse {
  final http.Response _response;

  _HttpFileServiceResponse(this._response);

  @override
  Stream<List<int>> get content => Stream.value(_response.bodyBytes);

  @override
  int get contentLength =>
      _response.contentLength ?? _response.bodyBytes.length;

  @override
  String get eTag => _response.headers['etag'] ?? '';

  @override
  String get fileExtension {
    final contentType = _response.headers['content-type'];
    if (contentType != null) {
      final extension = contentType.split('/').last.replaceAll('jpeg', 'jpg');
      return '.$extension';
    }
    return '.jpg';
  }

  String get originalUrl => _response.request?.url.toString() ?? '';

  @override
  int get statusCode => _response.statusCode;

  @override
  DateTime get validTill {
    final cacheControl = _response.headers['cache-control'];
    if (cacheControl != null) {
      final maxAge = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
      if (maxAge != null) {
        final seconds = int.parse(maxAge.group(1)!);
        return DateTime.now().add(Duration(seconds: seconds));
      }
    }
    return DateTime.now().add(const Duration(days: 7));
  }
}

class CustomCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'customImageCache';

  static final CustomCacheManager _instance = CustomCacheManager._();
  factory CustomCacheManager() {
    return _instance;
  }

  CustomCacheManager._()
    : super(
        Config(
          key,
          fileService: _ApiServiceFileService(),
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 200,
        ),
      );
}
