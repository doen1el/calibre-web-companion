import 'package:adaptive_theme/adaptive_theme.dart';
import 'view_models/book_details_view_model.dart';
import 'view_models/book_list_view_model.dart';
import 'view_models/book_metadata_edit_view_model.dart';
import 'view_models/book_recommendation_view_model.dart';
import 'view_models/books_view_model.dart';
import 'view_models/download_service_view_model.dart';
import 'view_models/homepage_view_model.dart';
import 'view_models/login_settings_view_model.dart';
import 'view_models/login_view_model.dart';
import 'view_models/main_view_model.dart';
import 'view_models/me_view_model.dart';
import 'view_models/settings_view_mode.dart';
import 'view_models/shelf_view_model.dart';
import 'views/homepage_view.dart';
import 'views/login_view.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  // Get the saved color key from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final colorKey = prefs.getString('theme_color_key') ?? 'lightGreen';
  final themeSourceIndex =
      prefs.getInt('theme_source') ?? ThemeSource.custom.index;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => HomepageViewModel()),
        ChangeNotifierProvider(create: (_) => BooksViewModel()..refreshBooks()),
        ChangeNotifierProvider(create: (_) => BookDetailsViewModel()),
        ChangeNotifierProvider(create: (_) => MeViewModel()..getStats()),
        ChangeNotifierProvider(create: (_) => BookListViewModel()),
        ChangeNotifierProvider(
          create:
              (_) => SettingsViewModel(
                navigatorKey: navigatorKey,
                initialColorKey: colorKey,
                initialThemeSource: ThemeSource.values[themeSourceIndex],
              )..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => DownloadServiceViewModel()),
        ChangeNotifierProvider(create: (_) => ShelfViewModel()..loadShelfs()),
        ChangeNotifierProvider(
          create: (_) => LoginSettingsViewModel()..loadHeaders(),
        ),
        ChangeNotifierProvider(create: (_) => BookMetadataEditViewModel()),
        ChangeNotifierProvider(create: (_) => BookRecommendationsViewModel()),
      ],
      child: MyApp(savedThemeMode: savedThemeMode),
    ),
  );
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;

  const MyApp({super.key, this.savedThemeMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // Check if the user is logged in by looking for a session cookie
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('calibre_web_session');
    return cookie != null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, settingsViewModel, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            // Get the base seed color from settings
            final seedColor =
                settingsViewModel.themeSource == ThemeSource.custom
                    ? settingsViewModel.selectedColor
                    : Colors.lightGreen;

            // Create the color schemes
            final lightScheme =
                settingsViewModel.themeSource == ThemeSource.system &&
                        lightDynamic != null
                    ? lightDynamic
                    : ColorScheme.fromSeed(
                      seedColor: seedColor,
                      brightness: Brightness.light,
                    );

            final darkScheme =
                settingsViewModel.themeSource == ThemeSource.system &&
                        darkDynamic != null
                    ? darkDynamic
                    : ColorScheme.fromSeed(
                      seedColor: seedColor,
                      brightness: Brightness.dark,
                    );

            // Create the themes
            final lightTheme = ThemeData(
              useMaterial3: true,
              colorScheme: lightScheme,
            );

            final darkTheme = ThemeData(
              useMaterial3: true,
              colorScheme: darkScheme,
            );

            return MaterialApp(
              title: 'Calibre-Web-Companion',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: settingsViewModel.currentTheme,
              navigatorKey: navigatorKey,
              navigatorObservers: [routeObserver],
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              debugShowCheckedModeBanner: false,
              localeResolutionCallback: (locale, supportedLocales) {
                // If the locale of the device is supported, use it
                if (locale != null) {
                  for (final supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode == locale.languageCode) {
                      return supportedLocale;
                    }
                  }
                }
                // else use the default one
                return const Locale('en');
              },
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
            );
          },
        );
      },
    );
  }
}
