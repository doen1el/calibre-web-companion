import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/login/data/datasources/login_remote_datasource.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/di/injection_container.dart' as di;
import 'package:logger/web.dart';

import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_event.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_bloc.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_bloc.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_bloc.dart';
import 'package:calibre_web_companion/features/homepage/presentation/pages/home_page.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_event.dart';
import 'package:calibre_web_companion/features/me/bloc/me_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/data/models/theme_source.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/login/data/repositories/login_repository.dart';
import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/presentation/pages/login_page.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_bloc.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final GetIt getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection
  await di.init();

  // Load theme settings
  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  runApp(
    MultiBlocProvider(
      providers: [
        // BLoC Providers for new features
        BlocProvider<LoginBloc>(create: (_) => getIt<LoginBloc>()),
        BlocProvider<LoginSettingsBloc>(
          create:
              (_) => getIt<LoginSettingsBloc>()..add(const LoadLoginSettings()),
        ),
        BlocProvider<BookViewBloc>(
          create: (_) => getIt<BookViewBloc>()..add(const LoadViewSettings()),
        ),
        BlocProvider<MeBloc>(create: (_) => getIt<MeBloc>()),
        BlocProvider<DiscoverBloc>(create: (_) => getIt<DiscoverBloc>()),
        BlocProvider<DiscoverDetailsBloc>(
          create: (_) => getIt<DiscoverDetailsBloc>(),
        ),
        BlocProvider<ShelfViewBloc>(
          create: (_) => getIt<ShelfViewBloc>()..add(const LoadShelves()),
        ),
        BlocProvider<ShelfDetailsBloc>(
          create: (_) => getIt<ShelfDetailsBloc>(),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => getIt<SettingsBloc>()..add(LoadSettings()),
        ),
        BlocProvider<DownloadServiceBloc>(
          create: (_) => getIt<DownloadServiceBloc>(),
        ),
        BlocProvider<HomePageBloc>(create: (_) => getIt<HomePageBloc>()),
        BlocProvider<BookDetailsBloc>(
          create: (_) => di.getIt<BookDetailsBloc>(),
        ),
        BlocProvider<BookViewBloc>(
          create:
              (_) =>
                  getIt<BookViewBloc>()
                    ..add(const LoadViewSettings())
                    ..add(const LoadBooks()),
        ),
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
    return await LoginRepository(
      dataSource: getIt<LoginRemoteDataSource>(),
      logger: getIt<Logger>(),
    ).isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen:
          (previous, current) =>
              previous.themeMode != current.themeMode ||
              previous.themeSource != current.themeSource ||
              previous.selectedColorKey != current.selectedColorKey ||
              previous.languageCode != current.languageCode,

      builder: (context, settingsState) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            // Get the base seed color from settings
            final seedColor =
                settingsState.themeSource == ThemeSource.custom
                    ? settingsState.selectedColor
                    : Colors.lightGreen;

            // Create the color schemes
            final lightScheme =
                settingsState.themeSource == ThemeSource.system &&
                        lightDynamic != null
                    ? lightDynamic
                    : ColorScheme.fromSeed(
                      seedColor: seedColor,
                      brightness: Brightness.light,
                    );

            final darkScheme =
                settingsState.themeSource == ThemeSource.system &&
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
              themeMode: settingsState.themeMode,
              navigatorKey: navigatorKey,
              navigatorObservers: [routeObserver],
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(
                settingsState.languageCode ?? 'en', // Fallback to 'en' if null
              ),
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
                  return isLoggedIn ? const HomePage() : const LoginPage();
                },
              ),
            );
          },
        );
      },
    );
  }
}
