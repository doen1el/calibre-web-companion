import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:calibre_web_companion/core/di/injection_container.dart';
import 'package:calibre_web_companion/features/book_details/data/datasources/book_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/book_details/data/models/metadata_models.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';

class MetadataSearchDialog extends StatefulWidget {
  final String initialQuery;

  const MetadataSearchDialog({super.key, required this.initialQuery});

  @override
  State<MetadataSearchDialog> createState() => _MetadataSearchDialogState();
}

class _MetadataSearchDialogState extends State<MetadataSearchDialog> {
  late TextEditingController _searchController;
  final BookDetailsRemoteDatasource _repository =
      getIt<BookDetailsRemoteDatasource>();

  List<MetadataProvider> _providers = [];
  final Set<String> _selectedProviderIds = {};
  List<MetadataSearchResult>? _results;
  bool _isLoading = false;
  bool _showProviders = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadProviders();
    if (widget.initialQuery.trim().isNotEmpty) {
      await _search();
    }
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    final providers = await _repository.getMetadataProviders();
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _selectedProviderIds.addAll(
        providers.where((p) => p.active).map((p) => p.id),
      );
      _isLoading = false;
    });
  }

  Future<void> _search() async {
    if (_searchController.text.trim().isEmpty) return;
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final results = await _repository.searchMetadata(
        _searchController.text,
        _selectedProviderIds.toList(),
      );
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          '${localizations.searchFailed}: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.travel_explore_rounded, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.fetchMetadata,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: localizations.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: localizations.search,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _search,
                        ),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: Icon(
                      _showProviders
                          ? Icons.filter_list_off_rounded
                          : Icons.filter_list_rounded,
                    ),
                    onPressed:
                        () => setState(() => _showProviders = !_showProviders),
                    tooltip: localizations.providers,
                  ),
                ],
              ),
            ),

            if (_showProviders && _providers.isNotEmpty)
              Container(
                height: 160,
                margin: const EdgeInsets.only(top: 12, right: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _providers.length,
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    return CheckboxListTile(
                      title: Text(provider.name),
                      value: _selectedProviderIds.contains(provider.id),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.trailing,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedProviderIds.add(provider.id);
                          } else {
                            _selectedProviderIds.remove(provider.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            Expanded(child: _buildResults(context, localizations, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    AppLocalizations localizations,
    ColorScheme scheme,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results == null) {
      return _buildEmpty(
        context,
        scheme,
        Icons.travel_explore_rounded,
        localizations.searchForMetadata,
      );
    }
    if (_results!.isEmpty) {
      return _buildEmpty(
        context,
        scheme,
        Icons.search_off_rounded,
        localizations.noBooksFound,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(right: 8),
      itemCount: _results!.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = _results![index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 44,
              height: 64,
              child:
                  result.coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: result.coverUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, _) => Container(
                              color: scheme.surfaceContainerHighest,
                            ),
                        errorWidget:
                            (_, _, _) => Container(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                      )
                      : Container(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
            ),
          ),
          title: Text(
            result.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              result.authors,
              [
                result.sourceId,
                result.pubdate,
              ].where((s) => s.isNotEmpty).join(' • '),
            ].where((s) => s.isNotEmpty).join('\n'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          onTap: () => _showMergeDialog(result),
        );
      },
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    ColorScheme scheme,
    IconData icon,
    String message,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMergeDialog(MetadataSearchResult result) async {
    final selection = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => _MetadataMergeDialog(result: result),
    );

    if (selection != null && mounted) {
      Navigator.of(context).pop({'result': result, 'selection': selection});
    }
  }
}

class _MetadataMergeDialog extends StatefulWidget {
  final MetadataSearchResult result;

  const _MetadataMergeDialog({required this.result});

  @override
  State<_MetadataMergeDialog> createState() => _MetadataMergeDialogState();
}

class _MetadataMergeDialogState extends State<_MetadataMergeDialog> {
  final Map<String, bool> _selection = {
    'title': true,
    'authors': true,
    'publisher': true,
    'rating': true,
    'pubdate': true,
    'description': true,
    'tags': true,
    'series': true,
    'languages': true,
    'cover': true,
  };

  String _labelFor(String key, AppLocalizations l) {
    switch (key) {
      case 'title':
        return l.title;
      case 'authors':
        return l.authors;
      case 'publisher':
        return l.publisher;
      case 'rating':
        return l.rating;
      case 'pubdate':
        return l.published;
      case 'description':
        return l.description;
      case 'tags':
        return l.tags;
      case 'series':
        return l.series;
      case 'languages':
        return l.languages;
      case 'cover':
        return l.cover;
      default:
        return key;
    }
  }

  String _valueFor(String key, AppLocalizations l) {
    final r = widget.result;
    switch (key) {
      case 'title':
        return r.title;
      case 'authors':
        return r.authors;
      case 'publisher':
        return r.publisher;
      case 'rating':
        return r.rating > 0 ? r.rating.toString() : '';
      case 'pubdate':
        return r.pubdate;
      case 'description':
        return r.description;
      case 'tags':
        return r.tags.join(', ');
      case 'series':
        return r.series.isNotEmpty ? '${r.series} #${r.seriesIndex}' : '';
      case 'languages':
        return r.languages.join(', ');
      case 'cover':
        return r.coverUrl.isNotEmpty ? l.coverImage : '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(localizations.selectMetadataToImport),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              _selection.keys.map((key) {
                final value = _valueFor(key, localizations);
                if (value.isEmpty) return const SizedBox.shrink();

                return CheckboxListTile(
                  title: Text(_labelFor(key, localizations)),
                  subtitle: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: _selection[key],
                  controlAffinity: ListTileControlAffinity.trailing,
                  onChanged: (val) => setState(() => _selection[key] = val!),
                  dense: true,
                );
              }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        AppDialogButton(
          onPressed: () => Navigator.of(context).pop(_selection),
          label: localizations.apply,
        ),
      ],
    );
  }
}
