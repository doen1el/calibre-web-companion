import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:calibre_web_companion/view_models/books_view_model.dart';
import 'package:calibre_web_companion/view_models/homepage_view_model.dart';
import 'package:calibre_web_companion/view_models/login_view_model.dart';
import 'package:calibre_web_companion/view_models/main_view_model.dart';
import 'package:calibre_web_companion/views/homepage_view.dart';
import 'package:calibre_web_companion/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => HomepageViewModel()),
        ChangeNotifierProvider(create: (_) => BooksViewModel()..refreshBooks()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Check if the user is logged in by looking for a session cookie
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('calibre_web_session');
    return cookie != null;
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.lightGreen,
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.lightGreen,
      ),
      initial: AdaptiveThemeMode.light,
      builder:
          (theme, darkTheme) => MaterialApp(
            title: 'Calibre-Web-Companion',
            theme: theme,
            darkTheme: darkTheme,
            home: FutureBuilder<bool>(
              future: _isLoggedIn(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final isLoggedIn = snapshot.data ?? false;
                return isLoggedIn ? const HomepageView() : const LoginView();
              },
            ),
          ),
    );
  }
}
