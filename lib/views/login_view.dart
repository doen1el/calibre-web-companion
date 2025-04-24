import 'package:calibre_web_companion/utils/app_transition.dart';
import 'package:calibre_web_companion/utils/snack_bar.dart';
import 'package:calibre_web_companion/views/login_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calibre_web_companion/view_models/login_view_model.dart';
import 'package:calibre_web_companion/views/homepage_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginState();
}

class _LoginState extends State<LoginView> {
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
    AppLocalizations localizations = AppLocalizations.of(context)!;
    final viewModel = Provider.of<LoginViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.loginToCalibreWb)),
      body: Center(
        child: SingleChildScrollView(
          child: _buildLoginForm(context, localizations, viewModel),
        ),
      ),
    );
  }

  /// Build the login form
  ///
  /// Parameters:
  ///
  /// - `context`: The BuildContext
  /// - `localizations`: The AppLocalizations
  ///   - `viewModel`: The LoginViewModel
  Widget _buildLoginForm(
    BuildContext context,
    AppLocalizations localizations,
    LoginViewModel viewModel,
  ) {
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
                  _buildTextField(
                    context: context,
                    controller: _urlController,
                    labelText: localizations.calibreWebUrl,
                    hintText: localizations.enterCalibreWebUrl,
                    prefixIcon: Icons.link_rounded,
                    autofillHint: AutofillHints.url,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),

                  // Username field
                  _buildTextField(
                    context: context,
                    controller: _usernameController,
                    labelText: localizations.username,
                    hintText: localizations.enterYourUsername,
                    prefixIcon: Icons.person_rounded,
                    autofillHint: AutofillHints.username,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  _buildTextField(
                    context: context,
                    controller: _passwordController,
                    labelText: localizations.password,
                    hintText: localizations.enterYourPassword,
                    obscureText: true,
                    prefixIcon: Icons.lock_rounded,
                    autofillHint: AutofillHints.password,
                    textInputAction: TextInputAction.done,
                    onSubmitted:
                        (_) => _handleLogin(viewModel, localizations, context),
                  ),

                  // Error message if any
                  if (viewModel.errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),

                  viewModel.isLoading
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
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12.0),
                                  bottomLeft: Radius.circular(12.0),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    bottomLeft: Radius.circular(12.0),
                                  ),
                                  onTap:
                                      () => _handleLogin(
                                        viewModel,
                                        localizations,
                                        context,
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
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer,
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
                                // ignore: deprecated_member_use
                              ).colorScheme.onPrimaryContainer.withOpacity(0.3),
                            ),

                            Expanded(
                              flex: 1,
                              child: Material(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12.0),
                                  bottomRight: Radius.circular(12.0),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(12.0),
                                    bottomRight: Radius.circular(12.0),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      AppTransitions.createSlideRoute(
                                        const LoginSettings(),
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
  }

  /// Build a text field
  ///
  /// Parameters:
  ///
  /// - `context`: The BuildContext
  /// - `controller`: The TextEditingController
  /// - `labelText`: The label text of the text field
  /// - `prefixIcon`: The icon to display before the text field
  /// - `hintText`: The hint text of the text field
  /// - `obscureText`: Whether the text field should obscure the text
  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
    bool obscureText = false,
    String? autofillHint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    final ValueNotifier<bool> isObscureTextNotifier = ValueNotifier<bool>(
      obscureText,
    );

    return ValueListenableBuilder<bool>(
      valueListenable: isObscureTextNotifier,
      builder: (context, isObscureText, _) {
        return TextField(
          controller: controller,
          autofillHints: autofillHint != null ? [autofillHint] : null,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          obscureText: isObscureText,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon:
                obscureText
                    ? IconButton(
                      icon: Icon(
                        isObscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        isObscureTextNotifier.value = !isObscureText;
                      },
                    )
                    : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
          ),
        );
      },
    );
  }

  /// Handle login
  ///
  /// Parameters:
  ///
  /// - `viewModel`: The LoginViewModel
  /// - `localizations`: The AppLocalizations
  /// - `context`: The BuildContext
  Future<void> _handleLogin(
    LoginViewModel viewModel,
    AppLocalizations localizations,
    BuildContext context,
  ) async {
    // Don't try to log in if already loading
    if (viewModel.isLoading) return;

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
    }

    // Save to shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('base_url', url);
    prefs.setString('username', _usernameController.text);
    prefs.setString('password', _passwordController.text);

    // Attempt login
    final success = await viewModel.login(
      _usernameController.text,
      _passwordController.text,
      url,
    );

    if (success && mounted) {
      Navigator.of(
        // ignore: use_build_context_synchronously
        context,
      ).pushReplacement(AppTransitions.createSlideRoute(const HomepageView()));
    } else if (mounted) {
      // Only show toast if error message is empty
      if (viewModel.errorMessage.isEmpty) {
        // ignore: use_build_context_synchronously
        context.showSnackBar(localizations.failedToLognIn, isError: true);
      }
    }
  }
}
