import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:calibre_web_companion/features/discover_details/data/repositories/discover_details_repository.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_model.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart'; // Für CategoryType Enum

enum FilterType { author, series, category, language, publisher }

class FilterSelectionPage extends StatefulWidget {
  final String title;
  final FilterType type;
  final List<String> initialSelection;

  const FilterSelectionPage({
    super.key,
    required this.title,
    required this.type,
    required this.initialSelection,
  });

  @override
  State<FilterSelectionPage> createState() => _FilterSelectionPageState();
}

class _FilterSelectionPageState extends State<FilterSelectionPage> {
  late List<String> selectedItems;
  List<CategoryModel> items = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    selectedItems = List.from(widget.initialSelection);
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = GetIt.I<DiscoverDetailsRepository>();
    try {
      CategoryFeed feed;

      switch (widget.type) {
        case FilterType.author:
          feed = await repo.loadCategories(
            CategoryType.author,
            subPath: "letter/00",
          );
          break;
        case FilterType.series:
          feed = await _loadCustomFeed(repo, "/opds/series/letter/00");
          break;
        case FilterType.category:
          feed = await repo.loadCategories(
            CategoryType.category,
            subPath: "letter/00",
          );
          break;
        case FilterType.language:
          feed = await _loadCustomFeed(repo, "/opds/language");
          break;
        case FilterType.publisher:
          feed = await _loadCustomFeed(repo, "/opds/publisher");
          break;
      }

      setState(() {
        items = feed.categories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<CategoryFeed> _loadCustomFeed(
    DiscoverDetailsRepository repo,
    String path,
  ) async {
    return await repo.dataSource.loadCategoriesgeneric(path);
  }

  void _toggleSelectAll() {
    setState(() {
      if (selectedItems.length == items.length) {
        selectedItems.clear();
      } else {
        selectedItems = items.map((e) => e.title).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final allSelected =
        items.isNotEmpty && selectedItems.length == items.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("${localizations.select} ${widget.title}"),
        actions: [
          if (!isLoading && errorMessage == null)
            IconButton(
              tooltip:
                  allSelected
                      ? localizations.deselectAll
                      : localizations.selectAll,
              icon: Icon(
                allSelected ? Icons.deselect_outlined : Icons.select_all,
              ),
              onPressed: _toggleSelectAll,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, selectedItems),
          ),
        ],
      ),
      body:
          isLoading
              ? Skeletonizer(
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder:
                      (_, _) => ListTile(title: Text(localizations.loading)),
                ),
              )
              : errorMessage != null
              ? Center(child: Text("${localizations.error}: $errorMessage"))
              : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedItems.contains(item.title);
                  return CheckboxListTile(
                    title: Text(item.title),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedItems.add(item.title);
                        } else {
                          selectedItems.remove(item.title);
                        }
                      });
                    },
                  );
                },
              ),
    );
  }
}
