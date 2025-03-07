import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml2json/xml2json.dart';
import 'package:html/parser.dart' as parser;

/// Authentication methods supported by the API
enum AuthMethod { none, cookie, basic }

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

  /// Returns the base URL or an empty string
  String getBaseUrl() {
    return _baseUrl ?? '';
  }

  /// Returns the username or an empty string
  String getUsername() {
    return _username ?? '';
  }

  /// Returns the password or an empty string
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

  void dispose() {
    _client.close();
  }

  /// Makes an authenticated GET request
  /// Returns the parsed JSON response or throws an exception
  ///
  /// Parameters:
  ///
  /// - `endpoint`: The API endpoint to request
  /// - `authMethod`: The authentication method to use
  /// - `queryParams`: Optional query parameters
  Future<Map<String, dynamic>> getJson(
    String endpoint,
    AuthMethod authMethod, {
    Map<String, String>? queryParams,
  }) async {
    final response = await get(endpoint, authMethod, queryParams: queryParams);
    try {
      if (response.body.length > 100) {
        _logger.d('Response body: ${response.body.substring(0, 100)}...');
      } else {
        _logger.d('Response body: ${response.body}');
      }
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to parse JSON response: $e');

      _logger.d('Response body: ${response.body}...');
      throw FormatException('Invalid JSON response: $e');
    }
  }

  /// Makes an authenticated GET request
  /// Returns the raw response object
  ///
  /// Parameters:
  ///
  /// - `endpoint`: The API endpoint to request
  /// - `authMethod`: The authentication method to use
  /// - `queryParams`: Optional query parameters
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

  /// Makes an authenticated POST request with optional CSRF token
  ///
  /// Parameters:
  ///
  /// - `endpoint`: The API endpoint to request
  /// - `queryParams`: Optional query parameters
  /// - `body`: The request body
  /// - `authMethod`: The authentication method to use
  /// - `contentType`: The content type of the request
  /// - `useCsrf`: Whether to fetch and include CSRF token
  /// - `csrfEndpoint`: The endpoint to fetch CSRF token from (defaults to same endpoint)
  /// - `csrfSelector`: CSS selector for the CSRF token input field
  Future<http.Response> post(
    String endpoint,
    Map<String, String>? queryParams,
    dynamic body,
    AuthMethod authMethod, {
    String contentType = 'application/json',
    bool useCsrf = false,
    String? csrfEndpoint,
    String csrfSelector = 'input[name="csrf_token"]',
    Map<String, String>? customHeaders,
  }) async {
    await _ensureInitialized();
    final uri = _buildUri(endpoint, queryParams);
    final headers = _getAuthHeaders(authMethod);
    headers['Content-Type'] = contentType;

    // Add custom headers if provided
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    _logger.d('POST request to: $uri');

    // Handle CSRF token if needed
    String? csrfToken;
    String? cookies;

    if (useCsrf) {
      final csrfData = await fetchCsrfToken(
        csrfEndpoint ?? endpoint,
        authMethod,
        csrfSelector,
      );
      csrfToken = csrfData['token'];
      cookies = csrfData['cookies'];

      if (cookies != null && !headers.containsKey('Cookie')) {
        headers['Cookie'] = cookies;
      }
    }

    // Prepare the body
    dynamic encodedBody;
    if (body is Map && useCsrf && csrfToken != null) {
      if (body is Map<String, dynamic>) {
        body['csrf_token'] = csrfToken;
      } else if (body is Map<String, String>) {
        body['csrf_token'] = csrfToken;
      }
    }

    encodedBody = _encodeBody(body, contentType);

    try {
      if (body == null && endpoint.contains('/ajax/toggleread/')) {
        // Create a manual request for more control over the exact format
        final request = http.Request('POST', uri);
        request.headers.addAll(headers);

        // Send an empty body but with the right Content-Length header
        request.body = '';

        final streamedResponse = await _client.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        _logger.i('POST response status: ${response.body}');
        _checkResponseStatus(response.statusCode);
        return response;
      }
      // Important change: Use an empty string instead of null when body is null
      final response = await _client.post(
        uri,
        headers: headers,
        body:
            encodedBody ??
            "", // This is the key change - provide empty string instead of null
      );
      _logger.i('POST response status: ${response.body}');
      _checkResponseStatus(response.statusCode);
      return response;
    } catch (e) {
      _logger.e('POST request failed: $e');
      rethrow;
    }
  }

  /// Makes an authenticated GET request and returns a StreamedResponse
  /// This is useful for downloading files or streaming large responses
  ///
  /// Parameters:
  ///
  /// - `endpoint`: The API endpoint to request
  /// - `authMethod`: The authentication method to use
  Future<http.StreamedResponse> getStream(
    String endpoint,
    AuthMethod authMethod,
  ) async {
    await _ensureInitialized();

    // Ensure URL is complete
    final fullUrl =
        endpoint.startsWith('http') ? endpoint : '$_baseUrl$endpoint';
    final headers = _getAuthHeaders(authMethod);

    _logger.d('GET stream request to: $fullUrl');
    _logger.d('Using ${authMethod.name} authentication');

    final request = http.Request('GET', Uri.parse(fullUrl));
    request.headers.addAll(headers);

    try {
      final response = await _client.send(request);
      _logger.i('Stream response status: ${response.statusCode}');
      _checkResponseStatus(response.statusCode);
      return response;
    } catch (e) {
      _logger.e('Stream request failed: $e');
      rethrow;
    }
  }

  /// Fetches a CSRF token from the specified endpoint
  ///
  /// Parameters:
  ///
  /// - `endpoint`: The endpoint to fetch the token from
  /// - `authMethod`: The authentication method to use
  /// - `selector`: CSS selector for the CSRF token input
  Future<Map<String, String?>> fetchCsrfToken(
    String endpoint,
    AuthMethod authMethod,
    String selector,
  ) async {
    _logger.d('Fetching CSRF token from: $endpoint');
    final response = await get(endpoint, authMethod);

    final document = parser.parse(response.body);
    final csrfElement = document.querySelector(selector);
    final csrfToken = csrfElement?.attributes['value'];

    if (csrfToken == null) {
      _logger.w(
        'CSRF token not found in the response using selector: $selector',
      );
    } else {
      _logger.d('CSRF token found');
    }

    return {'token': csrfToken, 'cookies': response.headers['set-cookie']};
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
  ///
  /// Parameters:
  ///
  /// - `endpoint`: The API endpoint to request
  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    return Uri.parse(
      '$_baseUrl$endpoint',
    ).replace(queryParameters: queryParams);
  }

  /// Gets authentication headers based on the auth method
  ///
  /// Parameters:
  ///
  /// - `authMethod`: The authentication method to use
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
  ///
  /// Parameters:
  ///
  /// - `body`: The request body to encode
  /// - `contentType`: The content type of the request
  dynamic _encodeBody(dynamic body, String contentType) {
    if (body is Map) {
      if (contentType == 'application/json') {
        return json.encode(body);
      } else if (contentType == 'application/x-www-form-urlencoded') {
        // Convert map to URL encoded string format key1=value1&key2=value2
        return body.entries
            .map(
              (e) =>
                  '${Uri.encodeComponent(e.key.toString())}=${Uri.encodeComponent(e.value.toString())}',
            )
            .join('&');
      }
    }
    return body;
  }

  /// Checks response status code and throws appropriate exceptions
  ///
  /// Parameters:
  ///
  /// - `statusCode`: The status code to check
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
  ///
  /// Parameters:
  ///
  /// - `endpoint`: The API endpoint to request
  /// - `authMethod`: The authentication method to use
  /// - `queryParams`: Optional query parameters
  Future<Map<String, dynamic>> getXmlAsJson(
    String endpoint,
    AuthMethod authMethod, {
    Map<String, String>? queryParams,
  }) async {
    final response = await get(endpoint, authMethod, queryParams: queryParams);
    try {
      // XML to JSON conversion
      final transformer = Xml2Json();
      transformer.parse(response.body);

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
