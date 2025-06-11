import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/login/presentation/widgets/login_text_field.dart';
import 'package:calibre_web_companion/features/login_settings/presentation/pages/login_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/bloc/login_event.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

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

    return BlocBuilder<LoginBloc, LoginState>(
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
                      // App logo or icon
                      Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Server URL field
                      LoginTextField(
                        controller: _urlController,
                        labelText: localizations.calibreWebUrl,
                        hintText: localizations.enterCalibreWebUrl,
                        prefixIcon: Icons.link_rounded,
                        autofillHint: AutofillHints.url,
                        keyboardType: TextInputType.url,
                        onChanged:
                            (value) =>
                                context.read<LoginBloc>().add(EnterUrl(value)),
                      ),
                      const SizedBox(height: 16),

                      // Username field
                      LoginTextField(
                        controller: _usernameController,
                        labelText: localizations.username,
                        hintText: localizations.enterYourUsername,
                        prefixIcon: Icons.person_rounded,
                        autofillHint: AutofillHints.username,
                        onChanged:
                            (value) => context.read<LoginBloc>().add(
                              EnterUsername(value),
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      LoginTextField(
                        controller: _passwordController,
                        labelText: localizations.password,
                        hintText: localizations.enterYourPassword,
                        obscureText: true,
                        prefixIcon: Icons.lock_rounded,
                        autofillHint: AutofillHints.password,
                        textInputAction: TextInputAction.done,
                        onChanged:
                            (value) => context.read<LoginBloc>().add(
                              EnterPassword(value),
                            ),
                        onSubmitted:
                            (_) => _handleLogin(context, localizations),
                      ),

                      // Error message if any
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

                      state.isLoading
                          ? Center(
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          )
                          : Card(
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
                                          () => _handleLogin(
                                            context,
                                            localizations,
                                          ),
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        child: Row(
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: .3),
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

  void _handleLogin(BuildContext context, AppLocalizations localizations) {
    // Don't try to log in if already loading
    if (context.read<LoginBloc>().state.isLoading) return;

    // Validate inputs
    if (_urlController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      context.showSnackBar(localizations.pleaseFillInAllFields, isError: true);
      return;
    }

    // Fix URL if needed (add https:// if missing)
    String url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      context.showSnackBar(
        localizations.urlMustStartWithHttpOrHttps,
        isError: true,
      );
      return;
    }

    // Dispatch login event
    context.read<LoginBloc>().add(const SubmitLogin());
  }
}
