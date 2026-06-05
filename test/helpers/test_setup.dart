import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/book_view/data/datasources/book_view_remote_datasource.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';
import 'package:calibre_web_companion/features/login/data/datasources/login_remote_datasource.dart';
import 'package:calibre_web_companion/features/login/data/models/login_credentials.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_env.dart';

Future<ApiService> setupIntegrationTest() async {
  SharedPreferences.setMockInitialValues({
    'base_url': TestEnv.baseUrl,
    'username': TestEnv.username,
    'password': TestEnv.password,
    'server_type': 'calibreWeb',
  });

  final prefs = await SharedPreferences.getInstance();
  if (!GetIt.instance.isRegistered<SharedPreferences>()) {
    GetIt.instance.registerSingleton<SharedPreferences>(prefs);
  }

  if (GetIt.instance.isRegistered<ApiService>()) {
    GetIt.instance.unregister<ApiService>();
  }
  final apiService = ApiService();
  GetIt.instance.registerSingleton<ApiService>(apiService);
  await apiService.initialize();

  final logger = Logger(level: Level.off);
  final loginDataSource = LoginRemoteDataSource(
    apiService: apiService,
    logger: logger,
  );

  final success = await loginDataSource.login(
    LoginCredentials(
      baseUrl: TestEnv.baseUrl,
      username: TestEnv.username,
      password: TestEnv.password,
    ),
    ServerType.calibreWeb,
  );

  if (!success) {
    throw Exception('Login failed during integration test setup.');
  }

  return apiService;
}

SharedPreferences testPrefs() => GetIt.instance<SharedPreferences>();

Future<BookViewModel> fetchFirstBook(ApiService api) async {
  final ds = BookViewRemoteDatasource(
    apiService: api,
    logger: Logger(level: Level.off),
    preferences: testPrefs(),
  );
  final books = await ds.fetchBooks(offset: 0, limit: 1);
  if (books.isEmpty) {
    throw Exception('Library is empty!');
  }
  return books.first;
}
