import 'package:shared_preferences/shared_preferences.dart';

class ReaderPreferences {
  static const String autoMarkReadKey = 'auto_mark_read_on_finish';

  static bool autoMarkRead(SharedPreferences prefs) =>
      prefs.getBool(autoMarkReadKey) ?? true;
}
