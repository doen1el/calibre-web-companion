import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/widget_service.dart';
import 'package:calibre_web_companion/features/offline/data/repositories/offline_library_repository.dart';

@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null || uri.scheme != 'calibrewebcompanion') return;
  if (!uri.pathSegments.contains('refresh')) return;

  WidgetsFlutterBinding.ensureInitialized();

  final logger = Logger();
  final prefs = await SharedPreferences.getInstance();
  await ApiService().initialize();

  final widgetService = WidgetService(
    prefs: prefs,
    logger: logger,
    offlineRepository: OfflineLibraryRepository(prefs: prefs, logger: logger),
  );

  await widgetService.refreshShelf();
}
