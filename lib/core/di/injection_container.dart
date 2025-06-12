import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';

import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/data/datasources/book_view_datasource.dart';
import 'package:calibre_web_companion/features/book_view/data/repositories/book_view_repository.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_bloc.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_bloc.dart';
import 'package:calibre_web_companion/features/discover_details/data/datasources/discover_details_datasource.dart';
import 'package:calibre_web_companion/features/discover_details/data/repositories/discover_details_repository.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/download_service/data/datasources/download_service_remote_datasource.dart';
import 'package:calibre_web_companion/features/download_service/data/repositories/download_service_repository.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_bloc.dart';
import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/data/datasources/login_datasource.dart';
import 'package:calibre_web_companion/features/login/data/repositories/login_repository.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_bloc.dart';
import 'package:calibre_web_companion/features/login_settings/data/datasources/login_settings_datasource.dart';
import 'package:calibre_web_companion/features/login_settings/data/repositories/login_settings_repository.dart';
import 'package:calibre_web_companion/features/me/bloc/me_bloc.dart';
import 'package:calibre_web_companion/features/me/data/datasources/me_datasource.dart';
import 'package:calibre_web_companion/features/me/data/repositories/me_repositorie.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:calibre_web_companion/features/settings/data/repositories/settings_repositorie.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_bloc.dart';
import 'package:calibre_web_companion/features/shelf_details/data/datasources/shelf_details_datasource.dart';
import 'package:calibre_web_companion/features/shelf_details/data/repositories/shelf_details_repositorie.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/datasources/shelf_view_datasource.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/repositories/shelf_view_repositorie.dart';

final GetIt getIt = GetIt.instance;

/// Initializes the dependency injection container.
Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final logger = Logger();
  final client = http.Client();

  //! Core
  // Singletons
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerLazySingleton<Logger>(() => logger);
  getIt.registerLazySingleton<http.Client>(() => client);

  // Services
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  //! Features

  //? Login Feature
  // DataSources
  getIt.registerLazySingleton<LoginDataSource>(
    () => LoginDataSource(apiService: getIt<ApiService>()),
  );

  // Repositories
  getIt.registerLazySingleton<LoginRepository>(
    () => LoginRepository(dataSource: getIt<LoginDataSource>()),
  );

  // BLoCs
  getIt.registerFactory<LoginBloc>(
    () => LoginBloc(loginRepository: getIt<LoginRepository>()),
  );

  //? Login Settings Feature
  // DataSources
  getIt.registerLazySingleton<LoginSettingsDatasource>(
    () => LoginSettingsDatasource(preferences: getIt<SharedPreferences>()),
  );

  // Repositories
  getIt.registerLazySingleton<LoginSettingsRepository>(
    () => LoginSettingsRepository(
      loginSettingsDatasource: getIt<LoginSettingsDatasource>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<LoginSettingsBloc>(
    () => LoginSettingsBloc(
      loginSettingsRepository: getIt<LoginSettingsRepository>(),
    ),
  );

  //? Book View Feature
  // DataSources
  getIt.registerLazySingleton<BookViewDatasource>(
    () => BookViewDatasource(preferences: getIt<SharedPreferences>()),
  );

  // Repositories
  getIt.registerLazySingleton<BookViewRepository>(
    () => BookViewRepository(datasource: getIt<BookViewDatasource>()),
  );

  // BLoCs
  getIt.registerFactory<BookViewBloc>(
    () => BookViewBloc(repository: getIt<BookViewRepository>()),
  );

  //? Me Feature
  // DataSources
  getIt.registerLazySingleton<MeDataSource>(
    () => MeDataSource(apiService: getIt<ApiService>()),
  );

  // Repositories
  getIt.registerLazySingleton<MeRepository>(
    () => MeRepository(dataSource: getIt<MeDataSource>()),
  );

  // BLoCs
  getIt.registerFactory<MeBloc>(
    () => MeBloc(repository: getIt<MeRepository>()),
  );

  //? Discover Feature
  // BLoCs
  getIt.registerFactory<DiscoverBloc>(() => DiscoverBloc());

  //? Discover Details Feature
  // DataSources
  getIt.registerLazySingleton<DiscoverDetailsDatasource>(
    () => DiscoverDetailsDatasource(apiService: getIt<ApiService>()),
  );

  // Repositories
  getIt.registerLazySingleton<DiscoverDetailsRepository>(
    () => DiscoverDetailsRepository(
      dataSource: getIt<DiscoverDetailsDatasource>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<DiscoverDetailsBloc>(
    () => DiscoverDetailsBloc(repository: getIt<DiscoverDetailsRepository>()),
  );

  //? Shelf View Feature
  // DataSources
  getIt.registerLazySingleton<ShelfViewDataSource>(
    () => ShelfViewDataSource(apiService: getIt<ApiService>()),
  );

  // Repositories
  getIt.registerLazySingleton<ShelfViewRepository>(
    () => ShelfViewRepository(dataSource: getIt<ShelfViewDataSource>()),
  );

  // BLoCs
  getIt.registerFactory<ShelfViewBloc>(
    () => ShelfViewBloc(repository: getIt<ShelfViewRepository>()),
  );

  //? Shelf Details Feature
  // DataSources
  getIt.registerLazySingleton<ShelfDetailsDataSource>(
    () => ShelfDetailsDataSource(apiService: getIt<ApiService>()),
  );

  // Repositories
  getIt.registerLazySingleton<ShelfDetailsRepository>(
    () => ShelfDetailsRepository(dataSource: getIt<ShelfDetailsDataSource>()),
  );

  // BLoCs
  getIt.registerFactory<ShelfDetailsBloc>(
    () => ShelfDetailsBloc(
      repository: getIt<ShelfDetailsRepository>(),
      shelfViewBloc: getIt<ShelfViewBloc>(),
    ),
  );

  //? Settings Feature
  // DataSources
  getIt.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSource(
      logger: getIt<Logger>(),
      sharedPreferences: getIt<SharedPreferences>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<SettingsRepositorie>(
    () => SettingsRepositorie(dataSource: getIt<SettingsLocalDataSource>()),
  );

  // BLoCs
  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(repository: getIt<SettingsRepositorie>()),
  );

  //? Download Service Feature
  // DataSources
  getIt.registerLazySingleton<DownloadServiceRemoteDataSource>(
    () => DownloadServiceRemoteDataSource(
      client: getIt<http.Client>(),
      logger: getIt<Logger>(),
      sharedPreferences: getIt<SharedPreferences>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<DownloadServiceRepository>(
    () => DownloadServiceRepository(
      remoteDataSource: getIt<DownloadServiceRemoteDataSource>(),
      logger: getIt<Logger>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<DownloadServiceBloc>(
    () => DownloadServiceBloc(
      repository: getIt<DownloadServiceRepository>(),
      logger: getIt<Logger>(),
    ),
  );

  //? Home Feature
  // BLoCs
  getIt.registerFactory<HomePageBloc>(() => HomePageBloc());
}
