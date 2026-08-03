import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_source_settings.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IsbnSourcesPage extends StatefulWidget {
  const IsbnSourcesPage({super.key});

  @override
  State<IsbnSourcesPage> createState() => _IsbnSourcesPageState();
}

class _IsbnSourcesPageState extends State<IsbnSourcesPage> {
  final Map<IsbnMetadataSource, TextEditingController> _credentialControllers =
      {};

  IsbnSourceSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _credentialControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await IsbnSourceSettings.load();
    if (!mounted) return;
    for (final source in IsbnMetadataSource.values) {
      if (!source.acceptsCredential) continue;
      _credentialControllers[source] = TextEditingController(
        text: settings.credentialFor(source),
      );
    }
    setState(() => _settings = settings);
  }

  Future<void> _persist(IsbnSourceSettings settings) async {
    setState(() => _settings = settings);
    await settings.save();
  }

  void _toggle(IsbnMetadataSource source, bool value) {
    final settings = _settings;
    if (settings == null) return;
    final enabled = Set<IsbnMetadataSource>.from(settings.enabled);
    value ? enabled.add(source) : enabled.remove(source);
    _persist(settings.copyWith(enabled: enabled));
  }

  void _setCredential(IsbnMetadataSource source, String value) {
    final settings = _settings;
    if (settings == null) return;
    final credentials = Map<IsbnMetadataSource, String>.from(
      settings.credentials,
    );
    credentials[source] = value.trim();
    _persist(settings.copyWith(credentials: credentials));
  }

  String _description(AppLocalizations localizations, IsbnMetadataSource s) =>
      switch (s) {
        IsbnMetadataSource.openLibrary =>
          localizations.isbnSourceOpenLibraryDescription,
        IsbnMetadataSource.googleBooks =>
          localizations.isbnSourceGoogleBooksDescription,
        IsbnMetadataSource.bnf => localizations.isbnSourceBnfDescription,
        IsbnMetadataSource.hardcover =>
          localizations.isbnSourceHardcoverDescription,
        IsbnMetadataSource.isbnDb => localizations.isbnSourceIsbnDbDescription,
      };

  String _label(IsbnMetadataSource source) =>
      source == IsbnMetadataSource.bnf
          ? 'BnF — Bibliothèque nationale de France'
          : source.label;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = _settings;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.isbnMetadataSources)),
      body:
          settings == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        localizations.isbnMetadataSourcesDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (settings.activeSources.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localizations.isbnSourceNoneEnabled,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        localizations.isbnSourceOrderHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      proxyDecorator:
                          (child, index, animation) => Material(
                            type: MaterialType.transparency,
                            child: child,
                          ),
                      itemCount: settings.order.length,
                      onReorderItem:
                          (oldIndex, newIndex) => _persist(
                            settings.withMovedSource(oldIndex, newIndex),
                          ),
                      itemBuilder: (context, index) {
                        final source = settings.order[index];
                        return _buildSourceCard(
                          context,
                          localizations,
                          settings,
                          source,
                          index,
                          key: ValueKey(source.id),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSourceCard(
    BuildContext context,
    AppLocalizations localizations,
    IsbnSourceSettings settings,
    IsbnMetadataSource source,
    int index, {
    required Key key,
  }) {
    final theme = Theme.of(context);
    final enabled = settings.enabled.contains(source);

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_label(source), style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        _description(localizations, source),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (value) => _toggle(source, value),
                ),
              ],
            ),

            if (source.acceptsCredential &&
                (enabled || source.requiresCredential)) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _credentialControllers[source],
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        labelText: switch (source) {
                          IsbnMetadataSource.hardcover =>
                            localizations.isbnSourceApiToken,
                          IsbnMetadataSource.googleBooks =>
                            localizations.isbnSourceApiKeyOptional,
                          _ => localizations.isbnSourceApiKey,
                        },
                        prefixIcon: const Icon(Icons.key_rounded),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 14.0,
                        ),
                      ),
                      onChanged: (value) => _setCredential(source, value),
                    ),
                    if (source == IsbnMetadataSource.googleBooks) ...[
                      const SizedBox(height: 6),
                      Text(
                        localizations.isbnSourceGoogleBooksKeyHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed:
                            () => launchUrl(
                              Uri.parse(source.infoUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text(localizations.isbnSourceGetCredential),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
