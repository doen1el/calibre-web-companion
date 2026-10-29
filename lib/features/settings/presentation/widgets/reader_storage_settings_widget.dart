import 'package:calibre_web_companion/core/services/reader_cache_service.dart';
import 'package:calibre_web_companion/features/reader/data/reader_preferences.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderStorageSettingsWidget extends StatefulWidget {
  const ReaderStorageSettingsWidget({super.key});

  @override
  State<ReaderStorageSettingsWidget> createState() =>
      _ReaderStorageSettingsWidgetState();
}

class _ReaderStorageSettingsWidgetState
    extends State<ReaderStorageSettingsWidget> {
  final ReaderCacheService _cache = GetIt.instance<ReaderCacheService>();
  final SharedPreferences _prefs = GetIt.instance<SharedPreferences>();

  late bool _autoMarkRead = ReaderPreferences.autoMarkRead(_prefs);
  late bool _cacheEnabled = _cache.isEnabled;
  late int _limitMb = _cache.limitMb;
  int? _usedBytes;

  @override
  void initState() {
    super.initState();
    _refreshUsage();
  }

  Future<void> _refreshUsage() async {
    final used = await _cache.usedBytes();
    if (mounted) setState(() => _usedBytes = used);
  }

  String _formatSize(int bytes) {
    const mb = 1024 * 1024;
    if (bytes >= 1024 * mb) {
      return '${(bytes / (1024 * mb)).toStringAsFixed(1)} GB';
    }
    return '${(bytes / mb).toStringAsFixed(bytes < 10 * mb ? 1 : 0)} MB';
  }

  Card _card(BuildContext context, Widget child) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: theme.colorScheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      children: [
        _card(
          context,
          _toggleRow(
            context,
            icon: Icons.task_alt_rounded,
            title: localizations.autoMarkAsRead,
            description: localizations.autoMarkAsReadDescription,
            value: _autoMarkRead,
            onChanged: (value) async {
              setState(() => _autoMarkRead = value);
              await _prefs.setBool(ReaderPreferences.autoMarkReadKey, value);
            },
          ),
        ),
        _card(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _toggleRow(
                context,
                icon: Icons.sd_storage_rounded,
                title: localizations.readerCache,
                description: localizations.readerCacheDescription,
                value: _cacheEnabled,
                onChanged: (value) async {
                  setState(() => _cacheEnabled = value);
                  await _cache.setEnabled(value);
                  await _refreshUsage();
                },
              ),
              if (_cacheEnabled) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizations.readerCacheLimit,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _limitMb,
                      underline: const SizedBox.shrink(),
                      items:
                          ReaderCacheService.limitOptionsMb
                              .map(
                                (mb) => DropdownMenuItem(
                                  value: mb,
                                  child: Text(_formatSize(mb * 1024 * 1024)),
                                ),
                              )
                              .toList(),
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => _limitMb = value);
                        await _cache.setLimitMb(value);
                        await _refreshUsage();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _usedBytes == null
                            ? ''
                            : localizations.readerCacheUsage(
                              _formatSize(_usedBytes!),
                            ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          (_usedBytes ?? 0) == 0
                              ? null
                              : () async {
                                await _cache.clear();
                                await _refreshUsage();
                              },
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: Text(localizations.readerCacheClear),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
