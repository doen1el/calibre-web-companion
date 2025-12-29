import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/homepage/presentation/pages/home_page.dart';

class WebViewLoginPage extends StatefulWidget {
  final String redirectUrl;
  final String baseUrl;

  const WebViewLoginPage({
    super.key,
    required this.redirectUrl,
    required this.baseUrl,
  });

  @override
  State<WebViewLoginPage> createState() => _WebViewLoginPageState();
}

class _WebViewLoginPageState extends State<WebViewLoginPage> {
  InAppWebViewController? _webViewController;
  final CookieManager _cookieManager = CookieManager.instance();

  final Logger _logger = Logger();
  bool _isLoading = true;
  String _currentUrl = '';
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.redirectUrl;
  }

  Future<void> _extractCookiesAndFinish() async {
    if (_isExtracting) return;
    setState(() {
      _isExtracting = true;
    });

    try {
      _logger.i('Extracting cookies from successful authentication');
      await Future.delayed(const Duration(milliseconds: 500));

      final List<Cookie> cookies = await _cookieManager.getCookies(
        url: WebUri(widget.baseUrl),
      );

      _logger.d(
        'Extracted cookies: ${cookies.map((c) => '${c.name}=${c.value}').join('; ')}',
      );

      final sessionCookieExists = cookies.any((c) => c.name == 'session');

      if (sessionCookieExists) {
        final prefs = await SharedPreferences.getInstance();

        final cookieString = cookies
            .map((c) => '${c.name}=${c.value}')
            .join('; ');

        await prefs.setString('calibre_web_session', cookieString);

        await ApiService().initialize();
        _logger.i('Successfully saved authentication cookies');

        if (mounted) {
          context.showSnackBar('Authentication successful!', isError: false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      } else {
        _logger.w('Session cookie not found after authentication');
        if (mounted) {
          context.showSnackBar(
            'Authentication completed but no session found',
            isError: true,
          );
          setState(() {
            _isExtracting = false;
          });
        }
      }
    } catch (e) {
      _logger.e('Error extracting cookies: $e');
      if (mounted) {
        context.showSnackBar(
          'Error completing authentication: $e',
          isError: true,
        );
        setState(() {
          _isExtracting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.ssoLogin),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                _currentUrl,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.redirectUrl)),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                    _currentUrl = url.toString();
                  });
                }
                _logger.d('Page started loading: $url');
              },
              onLoadStop: (controller, url) async {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _currentUrl = url.toString();
                  });
                }
                _logger.d('Page finished loading: $url');
                if (url.toString().startsWith(widget.baseUrl) &&
                    !_isExtracting) {
                  await _extractCookiesAndFinish();
                }
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                _logger.e(
                  'HTTP Error: ${errorResponse.statusCode} for ${request.url}',
                );
              },
              onReceivedError: (controller, request, error) {
                _logger.e(
                  'Web Resource Error: ${error.description} for ${request.url}',
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              localizations.pleaseLoginWithYourSSOAccount,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
