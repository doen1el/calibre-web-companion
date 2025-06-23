import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:calibre_web_companion/features/book_view/data/datasources/book_view_remote_datasource.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml2json/xml2json.dart';
import 'package:html/parser.dart' as parser;
import 'package:http_parser/http_parser.dart' show MediaType;

/// Authentication methods supported by the API
enum AuthMethod { none, cookie, basic }

/// Authentication systems for proxies
enum AuthSystem {
  none,
  authelia,
  cloudflareZeroTrust,
  swag,
  traefik,
  nginxProxy,
  custom,
}

/// Service class to handle API requests with various authentication methods
class ApiService {
  final Logger _logger = Logger();
  final http.Client _client = http.Client();
  String? _baseUrl;
  String? _cookie;
  String? _username;
  String? _password;
  String? _basePath;
  AuthSystem _authSystem = AuthSystem.none;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal();

  /// Returns the base URL or an empty string
  /// Returns the base URL with base path if available
  String getBaseUrl() {
    if (_basePath == null || _basePath!.isEmpty) {
      // If no base path, return just the base URL
      _logger.d('Base URL (no path): $_baseUrl');
      return _baseUrl!;
    } else {
      // Normalize base path by removing leading/trailing slashes
      final normalizedBasePath = _basePath!.trim();
      String basePath = normalizedBasePath;

      if (basePath.startsWith('/')) {
        basePath = basePath.substring(1);
      }
      if (basePath.endsWith('/')) {
        basePath = basePath.substring(0, basePath.length - 1);
      }

      // Combine base URL with normalized path
      final fullUrl = basePath.isEmpty ? _baseUrl : '$_baseUrl/$basePath';

      _logger.d('Base URL with path: $fullUrl');
      return fullUrl!;
    }
  }

  String getUrl(String endpoint) {
    final uri = _buildUri(endpoint: endpoint);
    return uri.toString();
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
    _basePath = prefs.getString('base_path') ?? '';

    final authSystemString = prefs.getString('auth_system') ?? 'none';
    try {
      _authSystem = AuthSystem.values.firstWhere(
        (e) => e.toString().split('.').last == authSystemString,
        orElse: () => AuthSystem.none,
      );
    } catch (e) {
      _authSystem = AuthSystem.none;
    }

    _logger.i('Initialized API service with auth system: $_authSystem');
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
  Future<Map<String, dynamic>> getJson({
    String endpoint = '',
    AuthMethod authMethod = AuthMethod.basic,
    Map<String, String> queryParams = const {},
  }) async {
    final response = await get(
      endpoint: endpoint,
      authMethod: authMethod,
      queryParams: queryParams,
    );
    try {
      if (response.body.length > 50) {
        _logger.d('Response body: ${response.body.substring(0, 50)}...');
      } else {
        _logger.d('Response body: ${response.body}');
      }

      return _sanitizeJsonResponse(response.body);
    } catch (e) {
      _logger.e('Failed to parse JSON response: $e');

      _logger.d('Response body: ${response.body}...');
      throw FormatException('Invalid JSON response: $e');
    }
  }

  /// Sanitizes JSON response that contains HTML in the comments field
  /// Sanitizes JSON response that contains HTML in the comments field
  Map<String, dynamic> _sanitizeJsonResponse(String responseBody) {
    try {
      // First attempt to parse normally
      return json.decode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      _logger.w('Failed to parse JSON response: $e');

      // Try a more aggressive approach - completely replace the comments field
      String sanitized = responseBody;

      // Step 1: Find the comments field
      int commentsPos = sanitized.indexOf('"comments"');
      if (commentsPos >= 0) {
        // Step 2: Find where the value starts (after the colon and opening quote)
        int valueStart = sanitized.indexOf(':', commentsPos);
        if (valueStart >= 0) {
          valueStart = sanitized.indexOf('"', valueStart);
          if (valueStart >= 0) {
            // Step 3: Find where the next field starts (after closing quote and comma)
            int nextFieldPos = -1;
            bool escaped = false;

            // Walk through the string to find the end of the value
            for (int i = valueStart + 1; i < sanitized.length; i++) {
              if (escaped) {
                escaped = false;
                continue;
              }

              if (sanitized[i] == '\\') {
                escaped = true;
                continue;
              }

              if (sanitized[i] == '"' && !escaped) {
                nextFieldPos = i + 1;
                break;
              }
            }

            if (nextFieldPos > 0) {
              // Step 4: Replace the comments content with empty value
              sanitized =
                  '${sanitized.substring(0, valueStart)}""${sanitized.substring(nextFieldPos)}';

              try {
                return json.decode(sanitized) as Map<String, dynamic>;
              } catch (e2) {
                _logger.e('Still failed after sanitizing comments: $e2');
              }
            }
          }
        }
      }

      // If we couldn't fix it with the above approach, try a simpler regex replacement
      try {
        final simpleReplacement = responseBody.replaceAll(
          RegExp(r'"comments"\s*:\s*".*?"', dotAll: true),
          '"comments":""',
        );
        return json.decode(simpleReplacement) as Map<String, dynamic>;
      } catch (e3) {
        _logger.e('Failed with regex replacement: $e3');
      }

      // Last resort - create a dummy response
      _logger.e('Could not sanitize JSON, returning dummy response');
      return {'error': 'Failed to parse JSON', 'comments': '', 'formats': []};
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
  Future<Map<String, dynamic>> getXmlAsJson({
    String endpoint = '',
    AuthMethod authMethod = AuthMethod.basic,
    Map<String, String> queryParams = const {},
  }) async {
    final transformer = Xml2Json();

    final response = await get(
      endpoint: endpoint,
      authMethod: authMethod,
      queryParams: queryParams,
    );
    try {
      if (response.body.length > 50) {
        _logger.d('Response body: ${response.body.substring(0, 50)}...');
      } else {
        _logger.d('Response body: ${response.body}');
      }

      transformer.parse(response.body);

      String jsonString = transformer.toParkerWithAttrs();

      return json.decode(jsonString) as Map<String, dynamic>;
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
  Future<http.Response> get({
    String endpoint = '',
    AuthMethod authMethod = AuthMethod.basic,
    Map<String, String> queryParams = const {},
  }) async {
    await _ensureInitialized();
    final uri = _buildUri(endpoint: endpoint, queryParams: queryParams);
    final headers = _getAuthHeaders(authMethod: authMethod);

    // Add processed custom headers for auth system
    final customHeaders = await _processCustomHeaders();
    headers.addAll(customHeaders);

    _logger.d('GET request to: $uri');
    _logger.d(
      'Using ${authMethod.name} authentication with ${_authSystem.name} proxy system',
    );
    _logger.d('Headers: $headers');

    try {
      final response = await _client.get(uri, headers: headers);
      _logger.i('Response status: ${response.statusCode}');
      _checkResponseStatus(statusCode: response.statusCode);
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
  /// - `csrfSelector`: CSS selector for the CSRF token input field
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
  /// - `csrfSelector`: CSS selector for the CSRF token input field
  /// - `files`: Optional list of files to upload as multipart/form-data
  Future<http.Response> post({
    String endpoint = '',
    AuthMethod authMethod = AuthMethod.basic,
    Map<String, String> queryParams = const {},
    dynamic body,
    String contentType = 'application/json',
    bool useCsrf = false,
    String csrfSelector = 'input[name="csrf_token"]',
    List<http.MultipartFile>? files, // New parameter for file uploads
  }) async {
    await _ensureInitialized();
    final uri = _buildUri(endpoint: endpoint, queryParams: queryParams);

    // Add processed custom headers for auth system
    final customHeaders = await _processCustomHeaders();

    // If we need to handle CSRF protection, use a two-step process
    if (useCsrf) {
      _logger.i('Making CSRF-protected POST request to: $uri');

      // STEP 1: Make initial GET request to fetch CSRF token
      final getHeaders = _getAuthHeaders(authMethod: authMethod);
      getHeaders.addAll(customHeaders);
      getHeaders['Accept'] = 'text/html,application/xhtml+xml,application/xml';

      final getResponse = await _client.get(uri, headers: getHeaders);
      _logger.d(
        'GET response status for CSRF fetch: ${getResponse.statusCode}',
      );

      if (getResponse.statusCode != 200) {
        _logger.e(
          'Initial GET request for CSRF token failed: ${getResponse.statusCode}',
        );
        throw Exception(
          'Failed to fetch CSRF token: ${getResponse.statusCode}',
        );
      }

      // Extract CSRF token from HTML
      final document = parser.parse(getResponse.body);
      final csrfElement = document.querySelector(csrfSelector);
      final csrfToken = csrfElement?.attributes['value'];

      if (csrfToken == null) {
        _logger.e('Could not find CSRF token using selector: $csrfSelector');
        throw Exception('CSRF token not found');
      }

      // Extract new session cookie if available
      String sessionCookie = _cookie ?? '';
      if (getResponse.headers.containsKey('set-cookie')) {
        final setCookieHeader = getResponse.headers['set-cookie']!;
        final sessionMatch = RegExp(
          r'session=([^;]+)',
        ).firstMatch(setCookieHeader);
        if (sessionMatch != null && sessionMatch.groupCount >= 1) {
          sessionCookie = 'session=${sessionMatch.group(1)}';
        }
      }

      // Check if we need a multipart request (for file uploads)
      if (files != null && files.isNotEmpty) {
        // STEP 2: Make multipart POST request with extracted CSRF token
        final request = http.MultipartRequest('POST', uri);

        // Add headers (omitting Content-Type as it will be set by MultipartRequest)
        request.headers['Cookie'] = sessionCookie;
        request.headers['X-CSRFToken'] = csrfToken;
        request.headers['X-Requested-With'] = 'XMLHttpRequest';
        request.headers['Referer'] = uri.toString();
        request.headers['Origin'] =
            '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ":${uri.port}" : ""}';

        // Add custom headers
        request.headers.addAll(customHeaders);

        // Add fields from body
        if (body is Map) {
          final bodyMap = body as Map;
          bodyMap.forEach((key, value) {
            request.fields[key.toString()] = value.toString();
          });
        }

        // Add CSRF token as a field
        request.fields['csrf_token'] = csrfToken;

        // Add files
        request.files.addAll(files);

        _logger.d('Multipart POST request headers: ${request.headers}');
        _logger.d('Multipart POST request fields: ${request.fields}');
        _logger.d(
          'Multipart POST request files: ${request.files.length} files',
        );

        try {
          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);
          _logger.i('Multipart POST response status: ${response.statusCode}');
          _checkResponseStatus(statusCode: response.statusCode);
          return response;
        } catch (e) {
          _logger.e('Multipart POST request failed: $e');
          rethrow;
        }
      } else {
        // Regular POST with CSRF token
        final postHeaders = {
          'Content-Type': contentType,
          'Cookie': sessionCookie,
          'X-CSRFToken': csrfToken,
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': uri.toString(),
          'Origin':
              '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ":${uri.port}" : ""}',
        };
        postHeaders.addAll(customHeaders);

        // Add CSRF token to body if it's a map
        Map<String, dynamic> finalBody;
        if (body is Map) {
          if (body is Map<String, dynamic>) {
            finalBody = Map<String, dynamic>.from(body);
          } else {
            finalBody = Map<String, dynamic>.from(
              body.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
          finalBody['csrf_token'] = csrfToken;
        } else {
          finalBody = {'csrf_token': csrfToken};
        }

        final encodedBody = _encodeBody(
          body: finalBody,
          contentType: contentType,
        );

        _logger.d('CSRF-protected POST headers: $postHeaders');
        _logger.d('CSRF-protected POST body: $encodedBody');

        try {
          final response = await _client.post(
            uri,
            headers: postHeaders,
            body: encodedBody,
          );
          _logger.i(
            'CSRF-protected POST response status: ${response.statusCode}',
          );
          _checkResponseStatus(statusCode: response.statusCode);
          return response;
        } catch (e) {
          _logger.e('CSRF-protected POST request failed: $e');
          rethrow;
        }
      }
    } else {
      // Standard POST without CSRF protection
      if (files != null && files.isNotEmpty) {
        // Handle multipart request without CSRF
        final request = http.MultipartRequest('POST', uri);

        // Add auth headers
        final headers = _getAuthHeaders(authMethod: authMethod);
        headers.addAll(customHeaders);
        request.headers.addAll(headers);

        // Add fields from body
        if (body is Map) {
          final bodyMap = body as Map;
          bodyMap.forEach((key, value) {
            request.fields[key.toString()] = value.toString();
          });
        }

        // Add files
        request.files.addAll(files);

        _logger.d('Multipart POST request to: $uri');
        _logger.d('Multipart headers: ${request.headers}');

        try {
          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);
          _logger.i('Multipart POST response status: ${response.statusCode}');
          _checkResponseStatus(statusCode: response.statusCode);
          return response;
        } catch (e) {
          _logger.e('Multipart POST request failed: $e');
          rethrow;
        }
      } else {
        // Standard POST request without CSRF protection or files
        final headers = _getAuthHeaders(authMethod: authMethod);
        headers['Content-Type'] = contentType;
        headers.addAll(customHeaders);

        _logger.d('POST request to: $uri');
        _logger.d(
          'Using ${authMethod.name} authentication with ${_authSystem.name} proxy system',
        );
        _logger.d('Headers: $headers');

        final encodedBody = _encodeBody(body: body, contentType: contentType);

        try {
          final response = await _client.post(
            uri,
            headers: headers,
            body: encodedBody ?? "",
          );
          _logger.i('POST response status: ${response.statusCode}');
          _checkResponseStatus(statusCode: response.statusCode);
          return response;
        } catch (e) {
          _logger.e('POST request failed: $e');
          rethrow;
        }
      }
    }
  }

  /// Makes an authenticated GET request and returns a StreamedResponse
  /// This is useful for downloading files or streaming large responses
  ///
  /// Parameters:
  ///
  /// - `endpoint`: The API endpoint to request
  /// - `authMethod`: The authentication method to use
  Future<http.StreamedResponse> getStream({
    String endpoint = '',
    AuthMethod authMethod = AuthMethod.basic,
    Map<String, String> queryParams = const {},
  }) async {
    await _ensureInitialized();
    final uri = _buildUri(endpoint: endpoint, queryParams: queryParams);

    // Create a request using the URI
    final request = http.Request('GET', uri);
    final headers = _getAuthHeaders(authMethod: authMethod);

    // Add processed custom headers for auth system
    final customHeaders = await _processCustomHeaders();
    headers.addAll(customHeaders);

    request.headers.addAll(headers);

    _logger.d('GET stream request to: ${uri.toString()}');
    _logger.d(
      'Using ${authMethod.name} authentication with ${_authSystem.name} proxy system',
    );
    _logger.d('Headers: $headers');

    try {
      final response = await _client.send(request);
      _logger.i('Stream response status: ${response.statusCode}');
      _checkResponseStatus(statusCode: response.statusCode);
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
  Future<Map<String, String?>> fetchCsrfToken({
    String endpoint = '',
    AuthMethod authMethod = AuthMethod.basic,
    String selector = 'input[name="csrf_token"]',
  }) async {
    _logger.d('Fetching CSRF token from: $endpoint');
    final response = await get(endpoint: endpoint, authMethod: authMethod);

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

  /// Builds a URI for API requests with proper base path handling
  ///
  /// Parameters:
  ///
  /// - `endpoint`: The API endpoint to request
  /// - `queryParams`: Optional query parameters
  Uri _buildUri({
    required String endpoint,
    Map<String, String> queryParams = const {},
  }) {
    // Skip base path processing for absolute URLs
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return Uri.parse(endpoint).replace(queryParameters: queryParams);
    }

    // Process base path
    String fullPath = endpoint;
    if (_basePath != null && _basePath!.isNotEmpty) {
      // Normalize paths by removing leading/trailing slashes for clean joining
      final normalizedBasePath = _basePath!.trim();
      final normalizedEndpoint = endpoint.trim();

      String basePath = normalizedBasePath;
      if (basePath.startsWith('/')) {
        basePath = basePath.substring(1);
      }
      if (basePath.endsWith('/')) {
        basePath = basePath.substring(0, basePath.length - 1);
      }

      String endpointPath = normalizedEndpoint;
      if (endpointPath.startsWith('/')) {
        endpointPath = endpointPath.substring(1);
      }

      // Join paths with a single slash
      if (basePath.isEmpty) {
        fullPath = '/$endpointPath';
      } else {
        fullPath = '/$basePath/$endpointPath';
      }
    } else if (!endpoint.startsWith('/')) {
      // Ensure endpoint starts with slash if no base path
      fullPath = '/$endpoint';
    }

    _logger.d('Built URL: $_baseUrl$fullPath');
    return Uri.parse(
      '$_baseUrl$fullPath',
    ).replace(queryParameters: queryParams);
  }

  /// Process custom headers, replacing placeholders with actual values
  Future<Map<String, String>> _processCustomHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final headersJson = prefs.getString('custom_login_headers') ?? '[]';

    final List<dynamic> decodedList = jsonDecode(headersJson);
    final List<Map<String, String>> customHeaders =
        decodedList
            .map((item) => Map<String, String>.from(item as Map))
            .toList();

    Map<String, String> processedHeaders = {};

    for (var header in customHeaders) {
      String key = header.keys.first;
      String value = header.values.first;

      // Replace username placeholder if available
      if (value.contains('\${USERNAME}') && _username != null) {
        value = value.replaceAll('\${USERNAME}', _username!);
      }

      processedHeaders[key] = value;
    }

    return processedHeaders;
  }

  /// Gets authentication headers based on the auth method
  ///
  /// Parameters:
  ///
  /// - `authMethod`: The authentication method to use
  Map<String, String> _getAuthHeaders({
    AuthMethod authMethod = AuthMethod.basic,
  }) {
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
  dynamic _encodeBody({dynamic body, String contentType = 'application/json'}) {
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
  void _checkResponseStatus({int statusCode = 200}) {
    if (statusCode == 401) {
      throw Exception('Authentication failed. Please log in again.');
    } else if (statusCode >= 500) {
      throw Exception('Server error: $statusCode');
    } else if (statusCode >= 400) {
      throw Exception('Request failed with status $statusCode');
    }
  }

  /// Uploads a file to the specified endpoint with cancellation support
  ///
  /// Parameters:
  /// - `file`: The file to upload
  /// - `endpoint`: The endpoint to upload to (e.g., '/upload')
  /// - `cancelToken`: Optional token to cancel the operation
  /// - `formFieldName`: The name of the form field for the file
  /// - `additionalFields`: Additional form fields to include
  /// - `timeoutSeconds`: Timeout in seconds
  ///
  /// Returns a map with upload result information
  Future<Map<String, dynamic>> uploadFile({
    File? file,
    String endpoint = '',
    CancellationToken? cancelToken,
    String formFieldName = 'btn-upload',
    Map<String, String> additionalFields = const {'btn-upload2': ''},
    int timeoutSeconds = 60,
    AuthMethod authMethod = AuthMethod.cookie,
  }) async {
    await _ensureInitialized();

    if (file == null) {
      throw ArgumentError('File parameter is required');
    }

    _logger.i('Starting upload of file: ${file.path.split('/').last}');

    // Check for cancellation before starting
    if (cancelToken?.isCancelled == true) {
      _logger.i('Upload cancelled before starting');
      return {'success': false, 'cancelled': true};
    }

    // Get CSRF token
    final csrfResult = await fetchCsrfToken(
      endpoint: '/',
      authMethod: authMethod,
      selector: 'input[name="csrf_token"]',
    );

    // Check for cancellation after token fetch
    if (cancelToken?.isCancelled == true) {
      _logger.i('Upload cancelled after CSRF token fetch');
      return {'success': false, 'cancelled': true};
    }

    final csrfToken = csrfResult['token'];
    if (csrfToken == null) {
      throw Exception('Failed to get CSRF token for upload');
    }

    // Prepare upload request
    final uri = _buildUri(endpoint: endpoint);
    final request = http.MultipartRequest('POST', uri);

    // Add authentication cookies
    request.headers['Cookie'] = csrfResult['cookies'] ?? '';

    // Add CSRF token
    request.fields['csrf_token'] = csrfToken;

    // Add any additional fields
    additionalFields.forEach((key, value) {
      request.fields[key] = value;
    });

    // Add custom headers for auth system
    final customHeaders = await _processCustomHeaders();
    request.headers.addAll(customHeaders);

    // Add the file
    final fileName = file.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();

    // Determine content type based on file extension
    String contentType = 'application/octet-stream';
    if (fileExtension == 'epub') {
      contentType = 'application/epub+zip';
    } else if (fileExtension == 'pdf') {
      contentType = 'application/pdf';
    } else if (fileExtension == 'mobi') {
      contentType = 'application/x-mobipocket-ebook';
    }

    // Check for cancellation before file preparation
    if (cancelToken?.isCancelled == true) {
      _logger.i('Upload cancelled before file preparation');
      return {'success': false, 'cancelled': true};
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        formFieldName,
        file.path,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );

    // Send request
    final client = http.Client();
    try {
      // Check for cancellation before sending request
      if (cancelToken?.isCancelled == true) {
        _logger.i('Upload cancelled before sending request');
        client.close();
        return {'success': false, 'cancelled': true};
      }

      // Create completer to allow cancellation during request
      final completer = Completer<http.StreamedResponse>();

      // Start the request
      final futureResponse = client.send(request);

      // Complete with the response when it arrives
      futureResponse
          .then((value) {
            if (!completer.isCompleted) {
              completer.complete(value);
            }
          })
          .catchError((error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          });

      // Set up a cancellation listener
      if (cancelToken != null) {
        // Check periodically if cancellation is requested
        Timer.periodic(Duration(milliseconds: 100), (timer) {
          if (cancelToken.isCancelled && !completer.isCompleted) {
            timer.cancel();
            completer.completeError(Exception('Operation cancelled'));
            client.close();
          }

          // Stop timer if completer is already completed
          if (completer.isCompleted) {
            timer.cancel();
          }
        });
      }

      // Wait for the response with timeout
      final streamedResponse = await completer.future.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          _logger.e('Upload request timed out');
          throw TimeoutException('Upload request timed out');
        },
      );

      // Check for cancellation after receiving response
      if (cancelToken?.isCancelled == true) {
        _logger.i('Upload cancelled after receiving response');
        return {'success': false, 'cancelled': true};
      }

      final response = await http.Response.fromStream(streamedResponse);

      _logger.i('Upload response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 302) {
        _logger.i('File uploaded successfully: $fileName');
        return {
          'success': true,
          'statusCode': response.statusCode,
          'response': response,
        };
      } else {
        _logger.e('Failed to upload file: Status ${response.statusCode}');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'response': response,
          'error': 'Upload failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      if (cancelToken?.isCancelled == true) {
        _logger.i('Upload was cancelled: $e');
        return {'success': false, 'cancelled': true};
      }

      _logger.e('Error uploading file: $e');
      return {'success': false, 'error': 'Upload error: $e'};
    } finally {
      client.close();
    }
  }
}
