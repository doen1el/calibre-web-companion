import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_list_view_model.dart';
import 'package:calibre_web_companion/features/sync/data/models/sync_filter.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/repositories/shelf_view_repository.dart';
import 'package:calibre_web_companion/features/settings/presentation/pages/filter_selection_page.dart'; // Import Page
import 'package:calibre_web_companion/core/services/api_service.dart';

class SyncFilterBottomSheet extends StatefulWidget {
  final SyncFilter initialFilter;
  const SyncFilterBottomSheet({super.key, required this.initialFilter});

  @override
  State<SyncFilterBottomSheet> createState() => _SyncFilterBottomSheetState();
}

class _SyncFilterBottomSheetState extends State<SyncFilterBottomSheet> {
  late SyncFilter filter;
  ShelfListViewModel shelves = const ShelfListViewModel(shelves: []);
  bool isLoadingShelves = true;

  List<String> availableFormats = ['epub', 'pdf', 'mobi', 'cbz'];
  bool isLoadingFormats = true;

  @override
  void initState() {
    super.initState();
    filter = widget.initialFilter;
    _loadShelves();
    _loadFormats();
  }

  Future<void> _loadFormats() async {
    try {
      final api = GetIt.I<ApiService>();
      final response = await api.get(endpoint: '/opds/formats');

      final entries = response.body.split('<entry>');
      final Set<String> foundFormats = {};

      for (var entry in entries) {
        if (!entry.contains('</entry>')) continue;

        final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(entry);
        if (titleMatch != null) {
          foundFormats.add(titleMatch.group(1)!.toLowerCase().trim());
        }
      }

      if (mounted && foundFormats.isNotEmpty) {
        setState(() {
          availableFormats = foundFormats.toList()..sort();
          isLoadingFormats = false;
        });
      } else {
        if (mounted) setState(() => isLoadingFormats = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingFormats = false);
    }
  }

  Future<void> _loadShelves() async {
    try {
      final repo = GetIt.I<ShelfViewRepository>();
      final result = await repo.loadShelves();
      if (mounted) {
        setState(() {
          shelves = result;
          isLoadingShelves = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingShelves = false);
    }
  }

  void _openSelection(
    String title,
    FilterType type,
    List<String> currentList,
    SyncFilter Function(List<String>) onUpdate,
  ) async {
    if (!mounted) return;

    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder:
            (_) => FilterSelectionPage(
              title: title,
              type: type,
              initialSelection: currentList,
            ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        filter = onUpdate(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                localization.syncConfiguration,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                _buildSectionTitle(localization.formats),
                if (isLoadingFormats)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  )
                else
                  Wrap(
                    spacing: 8,
                    children:
                        availableFormats.map((fmt) {
                          final isSelected = filter.selectedFormats.contains(
                            fmt,
                          );
                          return FilterChip(
                            label: Text(fmt.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              final newFormats = List<String>.from(
                                filter.selectedFormats,
                              );
                              if (selected) {
                                newFormats.add(fmt);
                              } else {
                                newFormats.remove(fmt);
                              }
                              setState(
                                () =>
                                    filter = filter.copyWith(
                                      selectedFormats: newFormats,
                                    ),
                              );
                            },
                          );
                        }).toList(),
                  ),

                const SizedBox(height: 16),

                SwitchListTile(
                  title: Text(localization.syncOnlyUnreadBooks),
                  value: filter.unreadOnly,
                  onChanged:
                      (val) => setState(
                        () => filter = filter.copyWith(unreadOnly: val),
                      ),
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 8),

                _buildSectionTitle(localization.sourceShelf),
                if (isLoadingShelves)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String?>(
                    initialValue: filter.shelfId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(localization.allBooks),
                      ),
                      ...shelves.shelves.map(
                        (s) => DropdownMenuItem(
                          value: s.id.toString(),
                          child: Text(s.title),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        filter = SyncFilter(
                          shelfId: val,
                          selectedFormats: filter.selectedFormats,
                          tags: filter.tags,
                          authors: filter.authors,
                          series: filter.series,
                          languages: filter.languages,
                          publishers: filter.publishers,
                          unreadOnly: filter.unreadOnly,
                        );
                      });
                    },
                  ),

                const SizedBox(height: 16),
                _buildSectionTitle(localization.criteria),

                _buildFilterTile(
                  localization,
                  icon: Icons.person,
                  title: localization.authors,
                  count: filter.authors.length,
                  onTap:
                      () => _openSelection(
                        localization.authors,
                        FilterType.author,
                        filter.authors,
                        (l) => filter.copyWith(authors: l),
                      ),
                ),

                _buildFilterTile(
                  localization,
                  icon: Icons.library_books,
                  title: localization.series,
                  count: filter.series.length,
                  onTap:
                      () => _openSelection(
                        localization.series,
                        FilterType.series,
                        filter.series,
                        (l) => filter.copyWith(series: l),
                      ),
                ),

                _buildFilterTile(
                  localization,
                  icon: Icons.label,
                  title: localization.categories,
                  count: filter.tags.length,
                  onTap:
                      () => _openSelection(
                        localization.categories,
                        FilterType.category,
                        filter.tags,
                        (l) => filter.copyWith(tags: l),
                      ),
                ),

                _buildFilterTile(
                  localization,
                  icon: Icons.language,
                  title: localization.languages,
                  count: filter.languages.length,
                  onTap:
                      () => _openSelection(
                        localization.languages,
                        FilterType.language,
                        filter.languages,
                        (l) => filter.copyWith(languages: l),
                      ),
                ),

                _buildFilterTile(
                  localization,
                  icon: Icons.business,
                  title: localization.publishers,
                  count: filter.publishers.length,
                  onTap:
                      () => _openSelection(
                        localization.publishers,
                        FilterType.publisher,
                        filter.publishers,
                        (l) => filter.copyWith(publishers: l),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localization.cancel),
              ),
              const Spacer(),

              OutlinedButton.icon(
                icon: const Icon(Icons.preview),
                label: Text(localization.preview),
                onPressed: () {
                  Navigator.pop(context, {'filter': filter, 'dryRun': true});
                },
              ),
              const SizedBox(width: 8),

              FilledButton.icon(
                icon: const Icon(Icons.sync),
                label: Text(localization.syncNow),
                onPressed: () {
                  Navigator.pop(context, {'filter': filter, 'dryRun': false});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFilterTile(
    AppLocalizations localization, {
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(title),
        subtitle: Text(
          count > 0 ? "$count ${localization.selected}" : localization.all,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}
