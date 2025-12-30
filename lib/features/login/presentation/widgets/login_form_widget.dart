import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/bloc/login_event.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/login/presentation/widgets/login_text_field.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _urlController = TextEditingController(text: 'https://');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load stored credentials when the form initializes
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        // Update text controllers when credentials are loaded from storage
        if (_urlController.text != state.url) {
          _urlController.text = state.url;
        }
        if (_usernameController.text != state.username) {
          _usernameController.text = state.username;
        }
        if (_passwordController.text != state.password) {
          _passwordController.text = state.password;
        }

        // Notify autofill service when login is successful
        if (state.status == LoginStatus.success) {
          TextInput.finishAutofillContext();
        }
      },
      builder: (context, state) {
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
                          segments: const [
                            ButtonSegment<ServerType>(
                              value: ServerType.calibreWeb,
                              label: Text('Calibre Web'),
                            ),
                            ButtonSegment<ServerType>(
                              value: ServerType.opds,
                              label: Text('Booklore / OPDS'),
                            ),
                          ],
                          selected: {state.serverType},
                          onSelectionChanged: (Set<ServerType> newSelection) {
                            context.read<LoginBloc>().add(
                              ChangeServerType(newSelection.first),
                            );
                          },
                          style: ButtonStyle(
                            visualDensity: VisualDensity.comfortable,
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
                          state.serverType == ServerType.opds
                              ? Icons.library_books_rounded
                              : Icons.menu_book_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      LoginTextField(
                        controller: _urlController,
                        labelText:
                            state.serverType == ServerType.opds
                                ? 'Booklore / OPDSURL'
                                : 'Calibre Web URL',
                        hintText:
                            state.serverType == ServerType.opds
                                ? 'https://your-booklore.com'
                                : 'https://your-calibre-web.com',
                        prefixIcon: Icons.link_rounded,
                        autofillHint: AutofillHints.url,
                        keyboardType: TextInputType.url,
                        onChanged:
                            (value) =>
                                context.read<LoginBloc>().add(EnterUrl(value)),
                      ),

                      if (state.serverType == ServerType.opds)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            left: 4,
                            bottom: 8,
                          ),
                          child: Text(
                            localizations.appAddsOPDSPath,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      LoginTextField(
                        controller: _usernameController,
                        labelText: localizations.username,
                        hintText: localizations.enterYourUsername,
                        prefixIcon: Icons.person_rounded,
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
                        prefixIcon: Icons.lock_rounded,
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

                      ElevatedButton(
                        onPressed:
                            state.status == LoginStatus.loading
                                ? null
                                : () => _handleLogin(context, localizations),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            state.status == LoginStatus.loading &&
                                    state.loadingType ==
                                        LoginLoadingType.standard
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  localizations.login,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
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
    String url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      context.showSnackBar(
        localizations.urlMustStartWithHttpOrHttps,
        isError: true,
      );
      return;
    }
    context.read<LoginBloc>().add(const SubmitSsoLogin());
  }

  void _handleLogin(BuildContext context, AppLocalizations localizations) {
    if (context.read<LoginBloc>().state.status == LoginStatus.loading) return;

    if (_urlController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      context.showSnackBar(localizations.pleaseFillInAllFields, isError: true);
      return;
    }

    String url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      context.showSnackBar(
        localizations.urlMustStartWithHttpOrHttps,
        isError: true,
      );
      return;
    }

    context.read<LoginBloc>().add(const SubmitLogin());
  }
}
