import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/bloc/login_event.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/login/presentation/widgets/login_text_field.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/login_settings/presentation/pages/login_settings_page.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isHttps = true;
  bool _opdsRequiresAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginBloc>().add(const LoadStoredCredentials());
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleProtocol() {
    setState(() {
      _isHttps = !_isHttps;
    });
    _updateBlocUrl();
  }

  void _updateBlocUrl() {
    final protocol = _isHttps ? 'https://' : 'http://';
    final domain = _urlController.text;
    context.read<LoginBloc>().add(EnterUrl('$protocol$domain'));
  }

  void _onUrlChanged(String value) {
    String cleanValue = value;
    bool protocolChanged = false;

    if (value.startsWith('https://')) {
      _isHttps = true;
      cleanValue = value.substring(8);
      protocolChanged = true;
    } else if (value.startsWith('http://')) {
      _isHttps = false;
      cleanValue = value.substring(7);
      protocolChanged = true;
    }

    if (protocolChanged) {
      _urlController.text = cleanValue;
      _urlController.selection = TextSelection.fromPosition(
        TextPosition(offset: cleanValue.length),
      );
      setState(() {});
    }

    _updateBlocUrl();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        final currentUiUrl =
            '${_isHttps ? "https://" : "http://"}${_urlController.text}';

        if (state.url.isNotEmpty && state.url != currentUiUrl) {
          if (state.url.startsWith('https://')) {
            _isHttps = true;
            _urlController.text = state.url.substring(8);
          } else if (state.url.startsWith('http://')) {
            _isHttps = false;
            _urlController.text = state.url.substring(7);
          } else {
            _urlController.text = state.url;
          }
          setState(() {});
        }

        if (_usernameController.text != state.username) {
          _usernameController.text = state.username;
        }
        if (_passwordController.text != state.password) {
          _passwordController.text = state.password;
        }

        if (state.status == LoginStatus.success) {
          TextInput.finishAutofillContext();
        }
      },
      builder: (context, state) {
        String urlLabel;
        String urlHint;
        String? urlHelper;
        IconData typeIcon;

        switch (state.serverType) {
          case ServerType.calibreWeb:
            urlLabel = 'Calibre Web URL';
            urlHint = 'your-calibre-web.com';
            typeIcon = Icons.menu_book_rounded;
            break;
          case ServerType.booklore:
            urlLabel = 'Booklore URL';
            urlHint = 'your-booklore.com';
            urlHelper = localizations.appendsBookLorePath;
            typeIcon = Icons.auto_stories_rounded;
            break;
          case ServerType.opds:
            urlLabel = 'OPDS URL';
            urlHint = 'www.gutenberg.org/ebooks/search.opds';
            typeIcon = Icons.rss_feed_rounded;
            break;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: SegmentedButton<ServerType>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<ServerType>(
                              value: ServerType.calibreWeb,
                              label: Text('Calibre'),
                            ),
                            ButtonSegment<ServerType>(
                              value: ServerType.booklore,
                              label: Text('Booklore'),
                            ),
                            ButtonSegment<ServerType>(
                              value: ServerType.opds,
                              label: Text('OPDS (beta)'),
                            ),
                          ],
                          selected: {state.serverType},
                          onSelectionChanged: (Set<ServerType> newSelection) {
                            context.read<LoginBloc>().add(
                              ChangeServerType(newSelection.first),
                            );
                          },
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Center(
                        child: Icon(
                          typeIcon,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      LoginTextField(
                        controller: _urlController,
                        labelText: urlLabel,
                        hintText: urlHint,
                        helperText: urlHelper,
                        prefix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: TextButton(
                                onPressed: _toggleProtocol,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(60, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _isHttps ? 'https://' : 'http://',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 24,
                              width: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        autofillHint: AutofillHints.url,
                        keyboardType: TextInputType.url,
                        onChanged: _onUrlChanged,
                      ),

                      const SizedBox(height: 16),

                      if (state.serverType == ServerType.opds) ...[
                        SwitchListTile(
                          title: const Text(
                            'Authentication required',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          value: _opdsRequiresAuth,
                          onChanged: (bool value) {
                            setState(() {
                              _opdsRequiresAuth = value;
                            });
                            if (!value) {
                              _usernameController.clear();
                              _passwordController.clear();
                              context.read<LoginBloc>().add(
                                const EnterUsername(''),
                              );
                              context.read<LoginBloc>().add(
                                const EnterPassword(''),
                              );
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeThumbColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (state.serverType != ServerType.opds ||
                          _opdsRequiresAuth) ...[
                        LoginTextField(
                          controller: _usernameController,
                          labelText: localizations.username,
                          hintText: localizations.enterYourUsername,
                          prefix: const Icon(Icons.person_rounded),
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          onChanged:
                              (value) => context.read<LoginBloc>().add(
                                EnterUsername(value),
                              ),
                        ),

                        const SizedBox(height: 16),

                        LoginTextField(
                          controller: _passwordController,
                          labelText: localizations.password,
                          hintText: localizations.enterYourPassword,
                          obscureText: true,
                          prefix: const Icon(Icons.lock_rounded),
                          autofillHint: AutofillHints.password,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          onChanged:
                              (value) => context.read<LoginBloc>().add(
                                EnterPassword(value),
                              ),
                          onSubmitted:
                              (_) => _handleLogin(context, localizations),
                        ),
                      ],

                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 24),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Material(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12.0),
                                  bottomLeft: Radius.circular(12.0),
                                ),
                                child: InkWell(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    bottomLeft: Radius.circular(12.0),
                                  ),
                                  onTap:
                                      state.status == LoginStatus.loading
                                          ? null
                                          : () => _handleLogin(
                                            context,
                                            localizations,
                                          ),
                                  child: Container(
                                    height: 50,
                                    alignment: Alignment.center,
                                    child:
                                        state.status == LoginStatus.loading &&
                                                state.loadingType ==
                                                    LoginLoadingType.standard
                                            ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.login_rounded,
                                                  color:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  localizations.login,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onPrimaryContainer,
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 50,
                              width: 1,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer.withAlpha(80),
                            ),
                            Expanded(
                              flex: 1,
                              child: Material(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12.0),
                                  bottomRight: Radius.circular(12.0),
                                ),
                                child: InkWell(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12.0),
                                    bottomRight: Radius.circular(12.0),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      AppTransitions.createSlideRoute(
                                        const LoginSettingsPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 50,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.settings,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (state.serverType == ServerType.calibreWeb) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                localizations.or,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed:
                              state.status == LoginStatus.loading
                                  ? null
                                  : () =>
                                      _handleSsoLogin(context, localizations),
                          icon: const Icon(Icons.login),
                          label: Text(localizations.ssoLogin),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSsoLogin(BuildContext context, AppLocalizations localizations) {
    if (context.read<LoginBloc>().state.status == LoginStatus.loading) return;

    if (_urlController.text.isEmpty) {
      context.showSnackBar(localizations.pleaseEnterSSOUrl, isError: true);
      return;
    }
    String fullUrl =
        '${_isHttps ? "https://" : "http://"}${_urlController.text.trim()}';

    context.read<LoginBloc>().add(EnterUrl(fullUrl));
    context.read<LoginBloc>().add(const SubmitSsoLogin());
  }

  void _handleLogin(BuildContext context, AppLocalizations localizations) {
    if (context.read<LoginBloc>().state.status == LoginStatus.loading) return;

    final state = context.read<LoginBloc>().state;
    final bool credentialsRequired =
        state.serverType != ServerType.opds || _opdsRequiresAuth;

    if (_urlController.text.isEmpty ||
        (credentialsRequired &&
            (_usernameController.text.isEmpty ||
                _passwordController.text.isEmpty))) {
      context.showSnackBar(localizations.pleaseFillInAllFields, isError: true);
      return;
    }

    String domain = _urlController.text.trim();
    final serverType = state.serverType;

    if (serverType == ServerType.booklore) {
      if (!domain.endsWith('/api/v1/opds')) {
        if (domain.endsWith('/')) {
          domain = domain.substring(0, domain.length - 1);
        }
        domain = '$domain/api/v1/opds';

        _urlController.text = domain;
      }
    }

    String fullUrl = '${_isHttps ? "https://" : "http://"}$domain';

    context.read<LoginBloc>().add(EnterUrl(fullUrl));
    context.read<LoginBloc>().add(const SubmitLogin());
  }
}
