import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
                ),
                const SizedBox(height: 16),

                // Username field
                _buildTextField(
                  context: context,
                  controller: _usernameController,
                  labelText: localizations.username,
                  hintText: localizations.enterYourUsername,
                  prefixIcon: Icons.person_rounded,
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

                // Login button with loading state
                viewModel.isLoading
                    ? Center(
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    )
                    : Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Material(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.0),
                          onTap:
                              () => _handleLogin(
                                viewModel,
                                localizations,
                                context,
                              ),
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
      ),
    );
  }

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
      Fluttertoast.showToast(
        msg: localizations.pleaseFillInAllFields,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    // Fix URL if needed (add https:// if missing)
    String url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
      _urlController.text = url;
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
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomepageView()),
      );
    } else if (mounted) {
      // Only show toast if error message is empty
      if (viewModel.errorMessage.isEmpty) {
        Fluttertoast.showToast(
          msg: localizations.failedToLognIn,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }
}
