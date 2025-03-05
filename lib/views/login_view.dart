import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:calibre_web_companion/view_models/login_view_model.dart';
import 'package:calibre_web_companion/views/homepage_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final viewModel = Provider.of<LoginViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Login to Calibre Web")),
      body: Center(
        child: SingleChildScrollView(
          child: _buildLoginForm(context, viewModel),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                context: context,
                controller: _urlController,
                labelText: "Calibre Web URL",
                hintText: "Enter server URL",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context: context,
                controller: _usernameController,
                labelText: "Username",
                hintText: "Enter your username",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context: context,
                controller: _passwordController,
                labelText: "Password",
                hintText: "Enter your password",
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    viewModel.isLoading
                        ? null
                        : () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();

                          prefs.setString('base_url', _urlController.text);
                          prefs.setString('username', _usernameController.text);
                          prefs.setString('password', _passwordController.text);

                          final success = await viewModel.login(
                            _usernameController.text,
                            _passwordController.text,
                            _urlController.text,
                          );

                          if (success && mounted) {
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const HomepageView(),
                              ),
                            );
                          } else {
                            Fluttertoast.showToast(
                              msg: "Failed to login",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                            );
                          }
                        },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    viewModel.isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                        : const Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        hintText: hintText,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
