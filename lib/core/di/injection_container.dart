import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/tag_service.dart';
import 'package:calibre_web_companion/core/services/webdav_sync_service.dart';
import 'package:calibre_web_companion/core/services/download_manager.dart';

import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/data/datasources/book_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/book_details/data/repositories/book_details_repository.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/data/datasources/book_view_remote_datasource.dart';
import 'package:calibre_web_companion/features/book_view/data/repositories/book_view_repository.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_bloc.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_bloc.dart';
import 'package:calibre_web_companion/features/discover_details/data/datasources/discover_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/discover_details/data/repositories/discover_details_repository.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/download_service/data/datasources/download_service_remote_datasource.dart';
import 'package:calibre_web_companion/features/download_service/data/repositories/download_service_repository.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_bloc.dart';
import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/data/datasources/login_remote_datasource.dart';
import 'package:calibre_web_companion/features/login/data/repositories/login_repository.dart';
import 'package:calibre_web_companion/features/login_settings/bloc/login_settings_bloc.dart';
import 'package:calibre_web_companion/features/login_settings/data/datasources/login_settings_local_datasource.dart';
import 'package:calibre_web_companion/features/login_settings/data/repositories/login_settings_repository.dart';
import 'package:calibre_web_companion/features/me/bloc/me_bloc.dart';
import 'package:calibre_web_companion/features/me/data/datasources/me_remote_datasource.dart';
import 'package:calibre_web_companion/features/me/data/repositories/me_repository.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:calibre_web_companion/features/settings/data/repositories/settings_repository.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_bloc.dart';
import 'package:calibre_web_companion/features/shelf_details/data/datasources/shelf_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/shelf_details/data/repositories/shelf_details_repository.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/datasources/shelf_view_remote_datasource.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/repositories/shelf_view_repository.dart';
import 'package:calibre_web_companion/features/book_details/data/repositories/reading_progress_repository.dart';

final GetIt getIt = GetIt.instance;

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
  getIt.registerLazySingleton<TagService>(
    () => TagService(apiService: getIt<ApiService>(), logger: logger),
  );

  getIt.registerLazySingleton<WebDavSyncService>(
    () => WebDavSyncService(logger: getIt()),
  );

  getIt.registerLazySingleton<DownloadManager>(
    () => DownloadManager(
      prefs: getIt<SharedPreferences>(),
      logger: getIt<Logger>(),
    ),
  );

  //! Features

  //? Login Feature
  // DataSources
  getIt.registerLazySingleton<LoginRemoteDataSource>(
    () => LoginRemoteDataSource(
      apiService: getIt<ApiService>(),
      logger: getIt<Logger>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<LoginRepository>(
    () => LoginRepository(
      dataSource: getIt<LoginRemoteDataSource>(),
      logger: getIt<Logger>(),
    ),
  );

  getIt.registerLazySingleton<ReadingProgressRepository>(
    () => ReadingProgressRepository(webDavService: getIt()),
  );

  // BLoCs
  getIt.registerFactory<LoginBloc>(
    () => LoginBloc(
      loginRepository: getIt<LoginRepository>(),
      logger: getIt<Logger>(),
    ),
  );

  //? Login Settings Feature
  // DataSources
  getIt.registerLazySingleton<LoginSettingsLocalDataSource>(
    () => LoginSettingsLocalDataSource(
      preferences: getIt<SharedPreferences>(),
      logger: getIt<Logger>(),
      apiService: getIt<ApiService>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<LoginSettingsRepository>(
    () => LoginSettingsRepository(
      loginSettingsLocalDataSource: getIt<LoginSettingsLocalDataSource>(),
      logger: getIt<Logger>(),
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
  getIt.registerLazySingleton<BookViewRemoteDatasource>(
    () => BookViewRemoteDatasource(preferences: getIt<SharedPreferences>()),
  );

  // Repositories
  getIt.registerLazySingleton<BookViewRepository>(
    () => BookViewRepository(
      datasource: getIt<BookViewRemoteDatasource>(),
      logger: getIt<Logger>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<BookViewBloc>(
    () => BookViewBloc(
      repository: getIt<BookViewRepository>(),
      logger: getIt<Logger>(),
    ),
  );

  //? Me Feature
  // DataSources
  getIt.registerLazySingleton<MeRemoteDataSource>(
    () => MeRemoteDataSource(
      apiService: getIt<ApiService>(),
      preferences: getIt<SharedPreferences>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<MeRepository>(
    () => MeRepository(dataSource: getIt<MeRemoteDataSource>()),
  );

  // BLoCs
  getIt.registerFactory<MeBloc>(
    () => MeBloc(repository: getIt<MeRepository>()),
  );

  //? Discover Feature
  // BLoCs
  getIt.registerFactory<DiscoverBloc>(
    () => DiscoverBloc(sharedPreferences: getIt<SharedPreferences>()),
  );

  //? Discover Details Feature
  // DataSources
  getIt.registerLazySingleton<DiscoverDetailsRemoteDatasource>(
    () => DiscoverDetailsRemoteDatasource(
      apiService: getIt<ApiService>(),
      logger: getIt<Logger>(),
      preferences: getIt<SharedPreferences>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<DiscoverDetailsRepository>(
    () => DiscoverDetailsRepository(
      dataSource: getIt<DiscoverDetailsRemoteDatasource>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<DiscoverDetailsBloc>(
    () => DiscoverDetailsBloc(repository: getIt<DiscoverDetailsRepository>()),
  );

  //? Shelf View Feature
  // DataSources
  getIt.registerLazySingleton<ShelfViewRemoteDataSource>(
    () => ShelfViewRemoteDataSource(
      preferences: getIt<SharedPreferences>(),
      apiService: getIt<ApiService>(),
      logger: getIt<Logger>(),
      shelfDetailsRemoteDataSource: getIt<ShelfDetailsRemoteDataSource>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<ShelfViewRepository>(
    () => ShelfViewRepository(dataSource: getIt<ShelfViewRemoteDataSource>()),
  );

  // BLoCs
  getIt.registerFactory<ShelfViewBloc>(
    () => ShelfViewBloc(repository: getIt<ShelfViewRepository>()),
  );

  //? Shelf Details Feature
  // DataSources
  getIt.registerLazySingleton<ShelfDetailsRemoteDataSource>(
    () => ShelfDetailsRemoteDataSource(
      apiService: getIt<ApiService>(),
      logger: getIt<Logger>(),
      preferences: getIt<SharedPreferences>(), // NEU
    ),
  );

  // Repositories
  getIt.registerLazySingleton<ShelfDetailsRepository>(
    () => ShelfDetailsRepository(
      dataSource: getIt<ShelfDetailsRemoteDataSource>(),
    ),
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
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(dataSource: getIt<SettingsLocalDataSource>()),
  );

  // BLoCs
  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(repository: getIt<SettingsRepository>()),
  );

  //? Download Service Feature
  // DataSources
  getIt.registerLazySingleton<DownloadServiceRemoteDataSource>(
    () => DownloadServiceRemoteDataSource(
      client: getIt<http.Client>(),
      logger: getIt<Logger>(),
      sharedPreferences: getIt<SharedPreferences>(),
      loginSettingsRepository: getIt<LoginSettingsRepository>(),
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

  //? Book Details Feature

  // DataSources
  getIt.registerLazySingleton<BookDetailsRemoteDatasource>(
    () => BookDetailsRemoteDatasource(
      apiService: getIt<ApiService>(),
      logger: getIt<Logger>(),
      tagService: getIt<TagService>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<BookDetailsRepository>(
    () => BookDetailsRepository(
      datasource: getIt<BookDetailsRemoteDatasource>(),
      logger: getIt<Logger>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<BookDetailsBloc>(
    () => BookDetailsBloc(
      repository: getIt<BookDetailsRepository>(),
      logger: logger,
      progressRepository: getIt<ReadingProgressRepository>(),
      downloadManager: getIt<DownloadManager>(),
    ),
  );
}
