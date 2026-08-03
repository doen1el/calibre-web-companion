import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IsbnSourceSettings {
  static const String enabledKey = 'isbn_sources_enabled';
  static const String orderKey = 'isbn_sources_order';

  final Set<IsbnMetadataSource> enabled;

  final List<IsbnMetadataSource> order;
  final Map<IsbnMetadataSource, String> credentials;

  const IsbnSourceSettings({
    required this.enabled,
    this.order = IsbnMetadataSource.values,
    this.credentials = const {},
  });

  static Future<IsbnSourceSettings> load([SharedPreferences? prefs]) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    final stored = preferences.getStringList(enabledKey);

    final enabled =
        stored == null
            ? IsbnMetadataSource.defaultEnabled.toSet()
            : stored
                .map(IsbnMetadataSource.fromId)
                .whereType<IsbnMetadataSource>()
                .toSet();

    final credentials = <IsbnMetadataSource, String>{};
    for (final source in IsbnMetadataSource.values) {
      if (!source.acceptsCredential) continue;
      final value = preferences.getString(source.credentialKey)?.trim() ?? '';
      if (value.isNotEmpty) credentials[source] = value;
    }

    return IsbnSourceSettings(
      enabled: enabled,
      order: _readOrder(preferences.getStringList(orderKey)),
      credentials: credentials,
    );
  }

  static List<IsbnMetadataSource> _readOrder(List<String>? stored) {
    if (stored == null) return IsbnMetadataSource.values;

    final known =
        stored
            .map(IsbnMetadataSource.fromId)
            .whereType<IsbnMetadataSource>()
            .toList();
    return [
      ...known,
      ...IsbnMetadataSource.values.where((s) => !known.contains(s)),
    ];
  }

  Future<void> save([SharedPreferences? prefs]) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    await preferences.setStringList(
      enabledKey,
      enabled.map((s) => s.id).toList(),
    );
    await preferences.setStringList(orderKey, order.map((s) => s.id).toList());
    for (final source in IsbnMetadataSource.values) {
      if (!source.acceptsCredential) continue;
      await preferences.setString(
        source.credentialKey,
        credentials[source] ?? '',
      );
    }
  }

  String credentialFor(IsbnMetadataSource source) => credentials[source] ?? '';

  bool isUsable(IsbnMetadataSource source) {
    if (!enabled.contains(source)) return false;
    return !source.requiresCredential || credentialFor(source).isNotEmpty;
  }

  List<IsbnMetadataSource> get activeSources => order.where(isUsable).toList();

  IsbnSourceSettings withMovedSource(int oldIndex, int newIndex) {
    final reordered = List<IsbnMetadataSource>.from(order);
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    return copyWith(order: reordered);
  }

  IsbnSourceSettings copyWith({
    Set<IsbnMetadataSource>? enabled,
    List<IsbnMetadataSource>? order,
    Map<IsbnMetadataSource, String>? credentials,
  }) {
    return IsbnSourceSettings(
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
      credentials: credentials ?? this.credentials,
    );
  }
}
