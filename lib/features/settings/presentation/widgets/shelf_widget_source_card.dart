import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:calibre_web_companion/core/services/widget_service.dart';
import 'package:calibre_web_companion/core/services/widget_shelf_loader.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/repositories/shelf_view_repository.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

class ShelfWidgetSourceCard extends StatefulWidget {
  const ShelfWidgetSourceCard({super.key});

  @override
  State<ShelfWidgetSourceCard> createState() => _ShelfWidgetSourceCardState();
}

class _ShelfWidgetSourceCardState extends State<ShelfWidgetSourceCard> {
  final WidgetService _widgetService = GetIt.instance<WidgetService>();
  final ShelfViewRepository _shelfRepository =
      GetIt.instance<ShelfViewRepository>();

  late WidgetShelfSource _source = _widgetService.shelfSource;
  late String _shelfId = _widgetService.shelfId;

  Map<String, String>? _shelves;
  bool _loadingShelves = false;
  String? _shelvesError;

  @override
  void initState() {
    super.initState();
    if (_source.needsShelfId) _loadShelves(_source);
  }

  Future<void> _loadShelves(WidgetShelfSource source) async {
    if (!source.needsShelfId) return;

    setState(() {
      _loadingShelves = true;
      _shelvesError = null;
      _shelves = null;
    });

    try {
      final Map<String, String> shelves;
      if (source == WidgetShelfSource.magicShelf) {
        final result = await _shelfRepository.loadMagicShelves();
        shelves = {
          for (final shelf in result.shelves)
            shelf.id:
                shelf.icon == null ? shelf.name : '${shelf.icon} ${shelf.name}',
        };
      } else {
        final result = await _shelfRepository.loadShelves();
        shelves = {for (final shelf in result.shelves) shelf.id: shelf.title};
      }

      if (!mounted) return;
      setState(() {
        _shelves = shelves;
        _loadingShelves = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingShelves = false;
        _shelvesError = e.toString();
      });
    }
  }

  Future<void> _selectSource(WidgetShelfSource source) async {
    if (source == _source) return;

    setState(() {
      _source = source;
      _shelfId = '';
    });

    if (source.needsShelfId) {
      await _loadShelves(source);
      return;
    }

    await _widgetService.setShelfConfig(
      source: source,
      label: _sourceLabel(source, AppLocalizations.of(context)!),
    );
  }

  Future<void> _selectShelf(String id, String name) async {
    setState(() => _shelfId = id);
    await _widgetService.setShelfConfig(source: _source, id: id, label: name);
  }

  String _sourceLabel(WidgetShelfSource source, AppLocalizations l10n) {
    switch (source) {
      case WidgetShelfSource.bookList:
        return l10n.widgetShelfSourceRecent;
      case WidgetShelfSource.shelf:
        return l10n.widgetShelfSourceShelf;
      case WidgetShelfSource.magicShelf:
        return l10n.widgetShelfSourceMagicShelf;
      case WidgetShelfSource.offline:
        return l10n.widgetShelfSourceOffline;
    }
  }

  IconData _sourceIcon(WidgetShelfSource source) {
    switch (source) {
      case WidgetShelfSource.bookList:
        return Icons.new_releases_rounded;
      case WidgetShelfSource.shelf:
        return Icons.collections_bookmark_rounded;
      case WidgetShelfSource.magicShelf:
        return Icons.auto_awesome_rounded;
      case WidgetShelfSource.offline:
        return Icons.download_done_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.widgetShelfSourceDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final source in WidgetShelfSource.values)
              InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () => _selectSource(source),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _sourceIcon(source),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _sourceLabel(source, localizations),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Icon(
                        source == _source
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color:
                            source == _source
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            if (_source.needsShelfId) ...[
              const Divider(height: 24),
              _buildShelfPicker(theme, localizations),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShelfPicker(ThemeData theme, AppLocalizations localizations) {
    if (_loadingShelves) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_shelvesError != null) {
      return Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations.widgetShelfLoadError,
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () => _loadShelves(_source),
            child: Text(localizations.retry),
          ),
        ],
      );
    }

    final shelves = _shelves ?? const <String, String>{};
    if (shelves.isEmpty) {
      return Text(
        localizations.widgetShelfNoneFound,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.widgetShelfPick,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in shelves.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: entry.key == _shelfId,
                onSelected: (_) => _selectShelf(entry.key, entry.value),
              ),
          ],
        ),
      ],
    );
  }
}
