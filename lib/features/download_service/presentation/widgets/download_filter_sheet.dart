import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_filter_model.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_event.dart'; // ADD: for SaveFilter event

class DownloadFilterSheet extends StatefulWidget {
  final DownloadFilterModel currentFilter;
  final Function(DownloadFilterModel) onApply;

  const DownloadFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<DownloadFilterSheet> createState() => _DownloadFilterSheetState();
}

class _DownloadFilterSheetState extends State<DownloadFilterSheet> {
  late TextEditingController _isbnController;
  late TextEditingController _authorController;
  late TextEditingController _titleController;

  late List<String> _selectedLanguages;
  late List<String> _selectedFormats;
  String? _selectedContent;

  @override
  void initState() {
    super.initState();
    _isbnController = TextEditingController(text: widget.currentFilter.isbn);
    _authorController = TextEditingController(
      text: widget.currentFilter.author,
    );
    _titleController = TextEditingController(text: widget.currentFilter.title);

    _selectedLanguages = List.from(widget.currentFilter.languages);
    _selectedFormats = List.from(widget.currentFilter.formats);
    _selectedContent = widget.currentFilter.content;
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _authorController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final config = context.read<DownloadServiceBloc>().state.config;

    final availableFormats =
        config.supportedFormats.isNotEmpty
            ? config.supportedFormats
            : DownloadFilterModel.allFormats;

    final availableLanguages =
        config.languages.isNotEmpty
            ? config.languages
            : [
              {'code': 'en', 'language': 'English'},
            ];

    final Map<String, String> contentTypes = {
      'book_fiction': localizations.bookFiction,
      'book_nonfiction': localizations.bookNonFiction,
      'magazine': localizations.magazine,
      'comic': localizations.comic,
      'audiobook': localizations.audiobook,
    };

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.searchFilters,
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  onPressed: _resetFilters,
                  child: Text(
                    localizations.reset,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            // Text Fields
            _buildTextField('ISBN', _isbnController),
            const SizedBox(height: 10),
            _buildTextField(localizations.author, _authorController),
            const SizedBox(height: 10),
            _buildTextField(localizations.title, _titleController),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _selectedContent,
              decoration: InputDecoration(
                labelText: localizations.contentType,
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(localizations.any)),
                ...contentTypes.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (val) => setState(() => _selectedContent = val),
            ),

            const SizedBox(height: 20),

            InkWell(
              onTap:
                  () => _showLanguagePicker(
                    context,
                    availableLanguages,
                    localizations,
                  ),
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: localizations.languages,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child:
                    _selectedLanguages.isEmpty
                        ? Text(
                          localizations.any,
                          style: Theme.of(context).textTheme.bodyLarge,
                        )
                        : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              _selectedLanguages.map((code) {
                                final name =
                                    availableLanguages.firstWhere(
                                      (l) => l['code'] == code,
                                      orElse:
                                          () => {
                                            'code': code,
                                            'language': code.toUpperCase(),
                                          },
                                    )['language']!;
                                return Chip(
                                  label: Text(name),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                        ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              localizations.formats,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ...availableFormats.map((fmt) {
                  final isSelected = _selectedFormats.contains(fmt);
                  return FilterChip(
                    label: Text(fmt.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFormats.add(fmt);
                        } else {
                          _selectedFormats.remove(fmt);
                        }
                      });
                    },
                  );
                }),
                ..._selectedFormats
                    .where((fmt) => !availableFormats.contains(fmt))
                    .map((fmt) {
                      return FilterChip(
                        label: Text(fmt.toUpperCase()),
                        selected: true,
                        onSelected: (selected) {
                          setState(() {
                            if (!selected) {
                              _selectedFormats.remove(fmt);
                            }
                          });
                        },
                      );
                    }),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ),
                onPressed: () {
                  final filter = DownloadFilterModel(
                    isbn: _isbnController.text.trim(),
                    author: _authorController.text.trim(),
                    title: _titleController.text.trim(),
                    content: _selectedContent,
                    languages: List.unmodifiable(_selectedLanguages),
                    formats: List.unmodifiable(_selectedFormats),
                  );

                  context.read<DownloadServiceBloc>().add(SaveFilter(filter));

                  widget.onApply(filter);
                  Navigator.pop(context);
                },
                child: Text(
                  localizations.applyFilters,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    List<Map<String, String>> availableLanguages,
    AppLocalizations localizations,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => _LanguagePickerSheet(
            availableLanguages: availableLanguages,
            selectedLanguages: _selectedLanguages,
            title: localizations.languages,
            searchHint: localizations.search,
            onToggle: (code, selected) {
              setState(() {
                if (selected) {
                  if (!_selectedLanguages.contains(code)) {
                    _selectedLanguages.add(code);
                  }
                } else {
                  _selectedLanguages.remove(code);
                }
              });
            },
          ),
    );
  }

  void _resetFilters() {
    final config = context.read<DownloadServiceBloc>().state.config;

    setState(() {
      _isbnController.clear();
      _authorController.clear();
      _titleController.clear();
      _selectedContent = null;

      _selectedLanguages =
          config.defaultLanguage.isNotEmpty
              ? List.from(config.defaultLanguage)
              : <String>[];

      _selectedFormats =
          config.supportedFormats.isNotEmpty
              ? List.from(config.supportedFormats)
              : List.from(DownloadFilterModel.allFormats);
    });
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  final List<Map<String, String>> availableLanguages;
  final List<String> selectedLanguages;
  final String title;
  final String searchHint;
  final void Function(String code, bool selected) onToggle;

  const _LanguagePickerSheet({
    required this.availableLanguages,
    required this.selectedLanguages,
    required this.title,
    required this.searchHint,
    required this.onToggle,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final filtered =
        widget.availableLanguages.where((lang) {
          return lang['language']!.toLowerCase().contains(query) ||
              lang['code']!.toLowerCase().contains(query);
        }).toList();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final lang = filtered[index];
                  final code = lang['code']!;
                  final isSelected = widget.selectedLanguages.contains(code);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(lang['language']!),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) {
                      widget.onToggle(code, checked == true);
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
