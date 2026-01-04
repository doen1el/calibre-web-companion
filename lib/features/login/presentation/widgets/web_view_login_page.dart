import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:logger/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/homepage/presentation/pages/home_page.dart';
import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/bloc/login_event.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';

class WebViewLoginPage extends StatefulWidget {
  final String redirectUrl;
  final String baseUrl;
  final String? username;
  final String? password;

  const WebViewLoginPage({
    super.key,
    required this.redirectUrl,
    required this.baseUrl,
    this.username,
    this.password,
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
    _clearSession();
  }

  Future<void> _clearSession() async {
    _logger.i('Clearing previous session...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('calibre_web_session');
      await prefs.remove('calibre_web_cookie');
      await GetIt.I<ApiService>().initialize();
    } catch (e) {
      _logger.w('Error clearing session: $e');
    }
  }

  bool _isLoginSuccessPage(String url) {
    try {
      final currentUri = Uri.parse(url);
      final baseUri = Uri.parse(widget.baseUrl);
      if (currentUri.host != baseUri.host) return false;
      if (currentUri.path == '/' || currentUri.path.isEmpty) return true;
      if (currentUri.path.contains('/login')) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  String _cookieHeaderFromCookies(List<Cookie> cookies) {
    final map = <String, String>{};
    for (final c in cookies) {
      final name = c.name.trim();
      final value = c.value;
      if (name.isEmpty || value.isEmpty) continue;
      map[name] = value;
    }
    return map.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Future<List<Cookie>> _safeGetCookies(String url) async {
    try {
      return await _cookieManager.getCookies(url: WebUri(url));
    } catch (e) {
      return const <Cookie>[];
    }
  }

  Future<void> _extractCookiesAndFinish() async {
    if (_isExtracting) return;
    setState(() => _isExtracting = true);

    try {
      final baseUri = Uri.parse(widget.baseUrl);
      final origin = baseUri.origin;

      final candidates =
          <String>{
            if (_currentUrl.isNotEmpty) _currentUrl,
            widget.baseUrl,
            '$origin/',
            '$origin/login',
            '$origin/login/',
          }.toList();

      final allCookies = <Cookie>[];
      for (final url in candidates) {
        allCookies.addAll(await _safeGetCookies(url));
      }

      final userAgent = await _webViewController?.evaluateJavascript(
        source: 'navigator.userAgent',
      );

      final cookieHeader = _cookieHeaderFromCookies(allCookies);
      final hasSession = cookieHeader.contains('session=');

      if (cookieHeader.isNotEmpty && hasSession) {
        _logger.i('Cookies extracted. Delegating to Bloc...');

        if (!mounted) return;

        context.read<LoginBloc>().add(
          FinalizeSsoLogin(
            cookieHeader: cookieHeader,
            userAgent: userAgent?.toString() ?? '',
            baseUrl: widget.baseUrl,
            username: widget.username,
            password: widget.password,
          ),
        );
      } else {
        _logger.w('No session cookie found yet.');
        if (mounted) setState(() => _isExtracting = false);
      }
    } catch (e) {
      _logger.e('Error extracting cookies: $e');
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state.status == LoginStatus.success) {
          _logger.i('SSO Login finalized via Bloc. Navigating home.');
          context.showSnackBar(localizations.loginSuccessfull, isError: false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else if (state.status == LoginStatus.failure) {
          _logger.e('SSO Finalization failed: ${state.errorMessage}');
          setState(() => _isExtracting = false);
          context.showSnackBar(
            state.errorMessage ?? 'Login failed',
            isError: true,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.ssoLogin),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _webViewController?.reload(),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isLoading || _isExtracting) const LinearProgressIndicator(),

            if (_currentUrl.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                width: double.infinity,
                child: Text(
                  _currentUrl,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
                },
                onLoadStop: (controller, url) async {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                      _currentUrl = url.toString();
                    });
                  }

                  final urlString = url.toString();
                  if (_isLoginSuccessPage(urlString)) {
                    await _extractCookiesAndFinish();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
