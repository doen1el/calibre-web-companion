import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_event.dart';
import 'package:calibre_web_companion/features/book_view/data/datasources/book_view_datasource.dart';
import 'package:calibre_web_companion/features/book_view/data/repositories/book_view_repository.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_bloc.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_bloc.dart';
import 'package:calibre_web_companion/features/discover_details/data/datasources/discover_details_datasource.dart';
import 'package:calibre_web_companion/features/discover_details/data/repositories/discover_details_repository.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_event.dart';
import 'package:calibre_web_companion/features/me/bloc/me_bloc.dart';
import 'package:calibre_web_companion/features/me/data/datasources/me_datasource.dart';
import 'package:calibre_web_companion/features/me/data/repositories/me_repositorie.dart';
import 'package:calibre_web_companion/features/me/presentation/pages/me_page.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_bloc.dart';
import 'package:calibre_web_companion/features/shelf_details/data/datasources/shelf_details_datasource.dart';
import 'package:calibre_web_companion/features/shelf_details/data/repositories/shelf_details_repositorie.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/datasources/shelf_view_datasource.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/repositories/shelf_view_repositorie.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Core
import 'package:calibre_web_companion/core/services/api_service.dart';

// Features - Login
import 'package:calibre_web_companion/features/login/data/datasources/login_datasource.dart';
import 'package:calibre_web_companion/features/login/data/repositories/login_repository.dart';
import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/presentation/pages/login_page.dart';

// Features - Login Settings
import 'package:calibre_web_companion/features/login_settings/data/datasources/login_settings_datasource.dart';
import 'package:calibre_web_companion/features/login_settings/data/repositories/login_settings_repository.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_bloc.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final GetIt getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection
  await setupDependencies();

  // Load theme settings
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  // final prefs = await SharedPreferences.getInstance();
  // final colorKey = prefs.getString('theme_color_key') ?? 'lightGreen';
  // final themeSourceIndex = prefs.getInt('theme_source') ?? ThemeSource.custom.index;

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
          create: (_) => getIt<BookViewBloc>()..add(const LoadSettings()),
        ),
      ],
      child: MyApp(savedThemeMode: savedThemeMode),
    ),
  );
}

// Setup dependency injection
Future<void> setupDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  // Register SharedPreferences
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register Services
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // Login Feature Dependencies
  getIt.registerLazySingleton<LoginDataSource>(
    () => LoginDataSource(apiService: getIt<ApiService>()),
  );

  getIt.registerLazySingleton<LoginRepository>(
    () => LoginRepository(dataSource: getIt<LoginDataSource>()),
  );

  // Login Settings Feature Dependencies
  getIt.registerLazySingleton<LoginSettingsDatasource>(
    () => LoginSettingsDatasource(preferences: sharedPreferences),
  );

  getIt.registerLazySingleton<LoginSettingsRepository>(
    () => LoginSettingsRepository(),
  );

  getIt.registerFactory<LoginSettingsBloc>(() => LoginSettingsBloc());

  // Book List Feature Dependencies
  getIt.registerLazySingleton<BookViewDatasource>(
    () => BookViewDatasource(preferences: getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<BookViewRepository>(
    () => BookViewRepository(datasource: getIt<BookViewDatasource>()),
  );

  getIt.registerFactory<BookViewBloc>(
    () => BookViewBloc(repository: getIt<BookViewRepository>()),
  );

  // Me Feature
  // DataSources
  getIt.registerLazySingleton<MeDataSource>(
    () => MeDataSource(apiService: getIt<ApiService>()),
  );

  // Repositories
  getIt.registerLazySingleton<MeRepository>(
    () => MeRepository(dataSource: getIt<MeDataSource>()),
  );

  // BLoCs
  getIt.registerFactory(() => MeBloc(repository: getIt<MeRepository>()));

  // Discover Feature
  getIt.registerFactory(() => DiscoverBloc());

  // Discover Details Feature
  getIt.registerLazySingleton<DiscoverDetailsDatasource>(
    () => DiscoverDetailsDatasource(apiService: getIt<ApiService>()),
  );

  getIt.registerLazySingleton<DiscoverDetailsRepository>(
    () => DiscoverDetailsRepository(
      dataSource: getIt<DiscoverDetailsDatasource>(),
    ),
  );

  getIt.registerFactory<DiscoverDetailsBloc>(
    () => DiscoverDetailsBloc(repository: getIt<DiscoverDetailsRepository>()),
  );

  // Shelf View Feature
  getIt.registerLazySingleton<ShelfViewDataSource>(
    () => ShelfViewDataSource(apiService: getIt<ApiService>()),
  );

  getIt.registerLazySingleton<ShelfViewRepository>(
    () => ShelfViewRepository(dataSource: getIt<ShelfViewDataSource>()),
  );

  getIt.registerFactory<ShelfViewBloc>(
    () => ShelfViewBloc(repository: getIt<ShelfViewRepository>()),
  );

  // Shelf Details Feature
  getIt.registerLazySingleton<ShelfDetailsDataSource>(
    () => ShelfDetailsDataSource(apiService: getIt<ApiService>()),
  );

  getIt.registerLazySingleton<ShelfDetailsRepository>(
    () => ShelfDetailsRepository(dataSource: getIt<ShelfDetailsDataSource>()),
  );

  getIt.registerFactory<ShelfDetailsBloc>(
    () => ShelfDetailsBloc(
      repository: getIt<ShelfDetailsRepository>(),
      shelfViewBloc: getIt<ShelfViewBloc>(),
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
  // Check if the user is logged in by looking for a session cookie
  Future<bool> _isLoggedIn() async {
    return await LoginRepository().isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Get the base seed color from settings
        final seedColor = Colors.lightGreen;

        // Create the color schemes
        final lightScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        );

        final darkScheme = ColorScheme.fromSeed(
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
              return isLoggedIn ? MePage() : const LoginPage();
            },
          ),
        );
      },
    );
  }
}
