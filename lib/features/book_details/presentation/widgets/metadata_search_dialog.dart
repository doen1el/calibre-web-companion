import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:calibre_web_companion/core/di/injection_container.dart';
import 'package:calibre_web_companion/features/book_details/data/datasources/book_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/book_details/data/models/metadata_models.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

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
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    final providers = await _repository.getMetadataProviders();
    setState(() {
      _providers = providers;
      _selectedProviderIds.addAll(
        providers.where((p) => p.active).map((p) => p.id),
      );
      _isLoading = false;
    });
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final results = await _repository.searchMetadata(
        _searchController.text,
        _selectedProviderIds.toList(),
      );
      setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "Fetch Metadata",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: localizations.search,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _search,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showProviders ? Icons.filter_list_off : Icons.filter_list,
                  ),
                  onPressed:
                      () => setState(() => _showProviders = !_showProviders),
                  tooltip: "Providers",
                ),
              ],
            ),

            if (_showProviders && _providers.isNotEmpty)
              Container(
                height: 150,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _providers.length,
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    return CheckboxListTile(
                      title: Text(provider.name),
                      value: _selectedProviderIds.contains(provider.id),
                      dense: true,
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

            const SizedBox(height: 16),

            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _results == null
                      ? Center(
                        child: Text(
                          "Select providers and search for metadata",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                      : _results!.isEmpty
                      ? Center(child: Text(localizations.noBooksFound))
                      : ListView.separated(
                        itemCount: _results!.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final result = _results![index];
                          return ListTile(
                            leading:
                                result.coverUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                      imageUrl: result.coverUrl,
                                      width: 40,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (_, _) =>
                                              Container(color: Colors.grey),
                                      errorWidget:
                                          (_, _, _) => const Icon(Icons.book),
                                    )
                                    : const Icon(Icons.book),
                            title: Text(result.title),
                            subtitle: Text(
                              "${result.authors}\n${result.sourceId} • ${result.pubdate}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            onTap: () => _showMergeDialog(result),
                          );
                        },
                      ),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Metadata to Import"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              _selection.keys.map((key) {
                String value = '';
                switch (key) {
                  case 'title':
                    value = widget.result.title;
                    break;
                  case 'authors':
                    value = widget.result.authors;
                    break;
                  case 'publisher':
                    value = widget.result.publisher;
                    break;
                  case 'rating':
                    value = widget.result.rating.toString();
                    break;
                  case 'pubdate':
                    value = widget.result.pubdate;
                    break;
                  case 'description':
                    value = "Description text...";
                    break;
                  case 'tags':
                    value = widget.result.tags.join(', ');
                    break;
                  case 'series':
                    value =
                        "${widget.result.series} #${widget.result.seriesIndex}";
                    break;
                  case 'languages':
                    value = widget.result.languages.join(', ');
                    break;
                  case 'cover':
                    value = "Cover Image";
                    break;
                }

                if (value.isEmpty || value == "0.0" || value == " #") {
                  return const SizedBox.shrink();
                }

                return CheckboxListTile(
                  title: Text(key[0].toUpperCase() + key.substring(1)),
                  subtitle: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: _selection[key],
                  onChanged: (val) => setState(() => _selection[key] = val!),
                  dense: true,
                );
              }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selection),
          child: const Text("Apply"),
        ),
      ],
    );
  }
}
