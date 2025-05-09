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
  String? _basePath;

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

  /// Returns the base path or an empty string
  String getBasePath() {
    return _basePath ?? '';
  }

  /// Initializes the API service with credentials from shared preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('base_url');
    _cookie = prefs.getString('calibre_web_session');
    _username = prefs.getString('username');
    _password = prefs.getString('password');
    _basePath = prefs.getString('base_path');
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
      if (response.body.length > 50) {
        _logger.d('Response body: ${response.body.substring(0, 50)}...');
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
    final uri = await _buildUri(endpoint, queryParams);
    final headers = await _getAuthHeaders(authMethod);

    _logger.d('Headers: $headers');
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
    String csrfSelector = 'input[name="csrf_token"]',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await _ensureInitialized();
    final uri = await _buildUri(endpoint, queryParams);
    final headers = await _getAuthHeaders(authMethod);
    headers['Content-Type'] = contentType;

    _logger.d('Headers: $headers');

    _logger.d('POST request to: $uri');

    // Handle CSRF token if needed
    String? csrfToken;
    String? cookies;

    if (useCsrf) {
      final csrfData = await fetchCsrfToken(endpoint, authMethod, csrfSelector);
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

    _logger.i("Headers: $headers");

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: encodedBody ?? "",
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
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Ensure URL is complete
    final fullUrl =
        endpoint.startsWith('http') ? endpoint : '$_baseUrl$endpoint';
    final headers = await _getAuthHeaders(authMethod);

    List<Map<String, String>> costumHeaders = [];

    final headersJson = prefs.getString('custom_login_headers') ?? '[]';

    final List<dynamic> decodedList = jsonDecode(headersJson);
    costumHeaders =
        decodedList
            .map((item) => Map<String, String>.from(item as Map))
            .toList();

    // Add custom headers
    if (costumHeaders.isNotEmpty) {
      for (var customHeader in costumHeaders) {
        headers.addAll(customHeader);
      }
    }

    _logger.d('Headers: $headers');

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
      _logger.d('CSRF token found: $csrfToken');
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
  Future<Uri> _buildUri(
    String endpoint,
    Map<String, String>? queryParams,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String basePath = prefs.getString('base_path') ?? '';

    // Normalise the base URL
    if (basePath.isNotEmpty) {
      if (!basePath.startsWith('/')) {
        basePath = '/$basePath';
      }
      if (basePath.endsWith('/')) {
        basePath = basePath.substring(0, basePath.length - 1);
      }
    }

    // Normalise the endpoint
    if (!endpoint.startsWith('/')) {
      endpoint = '/$endpoint';
    }

    final fullUrl = '$_baseUrl$basePath$endpoint';
    return Uri.parse(fullUrl).replace(queryParameters: queryParams);
  }

  /// Gets authentication headers based on the auth method
  ///
  /// Parameters:
  ///
  /// - `authMethod`: The authentication method to use
  Future<Map<String, String>> _getAuthHeaders(AuthMethod authMethod) async {
    final headers = <String, String>{};

    switch (authMethod) {
      case AuthMethod.basic:
        final username = _username ?? '';
        final password = _password ?? '';
        if (username.isNotEmpty && password.isNotEmpty) {
          final basicAuth =
              'Basic ${base64Encode(utf8.encode('$username:$password'))}';
          headers['Authorization'] = basicAuth;
        }
        break;

      case AuthMethod.cookie:
        final storedCookie = _cookie ?? '';
        if (storedCookie.isNotEmpty) {
          headers['Cookie'] = storedCookie;
        }
        break;
      case AuthMethod.none:
        break;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final customHeadersJson = prefs.getString('custom_login_headers') ?? '';
    if (customHeadersJson.isNotEmpty) {
      try {
        List<dynamic> decodedList = jsonDecode(customHeadersJson);
        for (var item in decodedList) {
          final headerMap = Map<String, String>.from(item as Map);
          if (headerMap.isNotEmpty) {
            final key = headerMap.keys.first;
            String value = headerMap.values.first;

            if (value.contains('\${USERNAME}')) {
              value = value.replaceAll('\${USERNAME}', _username ?? '');
            }

            if (key.isNotEmpty) {
              headers[key] = value;
            }
          }
        }
      } catch (e) {
        _logger.e('Failed to parse custom headers: $e');
      }
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
