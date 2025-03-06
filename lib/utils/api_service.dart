import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml2json/xml2json.dart';

/// Authentication methods supported by the API
enum AuthMethod { cookie, basic }

/// Service class to handle API requests with various authentication methods
class ApiService {
  final Logger _logger = Logger();
  final http.Client _client = http.Client();
  String? _baseUrl;
  String? _cookie;
  String? _username;
  String? _password;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal();

  String getBaseUrl() {
    return _baseUrl ?? '';
  }

  String getUsername() {
    return _username ?? '';
  }

  String getPassword() {
    return _password ?? '';
  }

  /// Initializes the API service with credentials from shared preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('base_url');
    _cookie = prefs.getString('calibre_web_session');
    _username = prefs.getString('username');
    _password = prefs.getString('password');
  }

  /// Closes the HTTP client when the service is no longer needed
  void dispose() {
    _client.close();
  }

  /// Makes an authenticated GET request
  /// Returns the parsed JSON response or throws an exception
  Future<Map<String, dynamic>> getJson(
    String endpoint,
    AuthMethod authMethod, {
    Map<String, String>? queryParams,
  }) async {
    final response = await get(endpoint, authMethod, queryParams: queryParams);
    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to parse JSON response: $e');
      final previewLength =
          response.body.length > 100 ? 100 : response.body.length;
      _logger.d(
        'Response body: ${response.body.substring(0, previewLength)}...',
      );
      throw FormatException('Invalid JSON response: $e');
    }
  }

  /// Makes an authenticated GET request
  /// Returns the raw response object
  Future<http.Response> get(
    String endpoint,
    AuthMethod authMethod, {
    Map<String, String>? queryParams,
  }) async {
    await _ensureInitialized();
    final uri = _buildUri(endpoint, queryParams);
    final headers = _getAuthHeaders(authMethod);

    _logger.d('GET request to: $uri');
    _logger.d('Using ${authMethod.name} authentication');

    try {
      final response = await _client.get(uri, headers: headers);
      _logger.i('Response status: ${response.statusCode}');
      _checkResponseStatus(response.statusCode);
      return response;
    } catch (e) {
      _logger.e('Request failed: $e');
      rethrow;
    }
  }

  /// Makes an authenticated POST request
  Future<http.Response> post(
    String endpoint,
    Map<String, String>? queryParams,
    dynamic body,
    AuthMethod authMethod, {
    String contentType = 'application/json',
  }) async {
    await _ensureInitialized();
    final uri = _buildUri(endpoint, queryParams);
    final headers = _getAuthHeaders(authMethod);
    headers['Content-Type'] = contentType;

    _logger.d('POST request to: $uri');

    // Convert body to appropriate format
    dynamic encodedBody = _encodeBody(body, contentType);

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: encodedBody,
      );
      _logger.i('POST response status: ${response.statusCode}');
      _checkResponseStatus(response.statusCode);
      return response;
    } catch (e) {
      _logger.e('POST request failed: $e');
      rethrow;
    }
  }

  /// Downloads a binary file with appropriate authentication
  Future<http.StreamedResponse> download(
    String url,
    AuthMethod authMethod,
  ) async {
    await _ensureInitialized();

    // Ensure URL is complete
    final fullUrl = url.startsWith('http') ? url : '$_baseUrl$url';
    _logger.d('Downloading from: $fullUrl');

    final headers = _getAuthHeaders(authMethod);
    final request = http.Request('GET', Uri.parse(fullUrl));
    request.headers.addAll(headers);

    try {
      final response = await _client.send(request);
      _logger.i('Download response status: ${response.statusCode}');
      _checkResponseStatus(response.statusCode);
      return response;
    } catch (e) {
      _logger.e('Download request failed: $e');
      rethrow;
    }
  }

  /// Fetch image data with authentication
  Future<Uint8List?> fetchImage(String url, AuthMethod authMethod) async {
    try {
      final response = await get(url, authMethod);
      return (response.statusCode == 200) ? response.bodyBytes : null;
    } catch (e) {
      _logger.e('Error fetching image: $e');
      return null;
    }
  }

  /// Ensures credentials are loaded before making requests
  Future<void> _ensureInitialized() async {
    if (_baseUrl == null) {
      await initialize();

      if (_baseUrl == null) {
        throw Exception(
          'Server URL is missing. Please configure the app settings.',
        );
      }
    }
  }

  /// Builds a URI for API requests
  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    return Uri.parse(
      '$_baseUrl$endpoint',
    ).replace(queryParameters: queryParams);
  }

  /// Gets authentication headers based on the auth method
  Map<String, String> _getAuthHeaders(AuthMethod authMethod) {
    Map<String, String> headers = {};

    if (authMethod == AuthMethod.cookie && _cookie != null) {
      headers['Cookie'] = _cookie!;
    } else if (_username != null && _password != null) {
      headers['Authorization'] =
          'Basic ${base64.encode(utf8.encode('$_username:$_password'))}';
    }

    return headers;
  }

  /// Encodes request body based on content type
  dynamic _encodeBody(dynamic body, String contentType) {
    if (body is Map<String, dynamic> && contentType == 'application/json') {
      return json.encode(body);
    }
    return body;
  }

  /// Checks response status code and throws appropriate exceptions
  void _checkResponseStatus(int statusCode) {
    if (statusCode == 401) {
      throw Exception('Authentication failed. Please log in again.');
    } else if (statusCode >= 500) {
      throw Exception('Server error: $statusCode');
    } else if (statusCode >= 400) {
      throw Exception('Request failed with status $statusCode');
    }
  }

  /// Makes an authenticated GET request and converts XML response to JSON using Parker format
  /// Returns the parsed JSON response or throws an exception
  Future<Map<String, dynamic>> getXmlAsJson(
    String endpoint,
    AuthMethod authMethod, {
    Map<String, String>? queryParams,
  }) async {
    final response = await get(endpoint, authMethod, queryParams: queryParams);
    try {
      // XML zu JSON konvertieren mit Parker-Format (flacher und ohne $ Zeichen)
      final transformer = Xml2Json();
      transformer.parse(response.body);
      _logger.d('Parsed XML response to JSON: ${transformer.toParker()}');

      // Parker-Format verwenden - einfacher zu parsen als Badgerfish
      String jsonString = transformer.toParkerWithAttrs();

      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to parse XML response to JSON: $e');
      final previewLength =
          response.body.length > 100 ? 100 : response.body.length;
      _logger.d(
        'Response body: ${response.body.substring(0, previewLength)}...',
      );
      throw FormatException('Invalid XML response: $e');
    }
  }
}
