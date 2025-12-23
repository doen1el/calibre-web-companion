import 'package:flutter/material.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_filter_model.dart';

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

// TODO: Localization
class _DownloadFilterSheetState extends State<DownloadFilterSheet> {
  late TextEditingController _isbnController;
  late TextEditingController _authorController;
  late TextEditingController _titleController;

  late List<String> _selectedLanguages;
  late List<String> _selectedFormats;
  String? _selectedContent;

  final Map<String, String> _contentTypes = {
    'book_fiction': 'Book (Fiction)',
    'book_nonfiction': 'Book (Non-Fiction)',
    'magazine': 'Magazine',
    'comic': 'Comic',
    'audiobook': 'Audiobook',
  };

  final List<String> _availableLanguages = [
    'de',
    'en',
    'fr',
    'es',
    'it',
    'ru',
    'zh',
  ];
  final List<String> _availableFormats = DownloadFilterModel.allFormats;

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
                  'Search Filters',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            // Text Fields
            _buildTextField('ISBN', _isbnController),
            const SizedBox(height: 10),
            _buildTextField('Author', _authorController),
            const SizedBox(height: 10),
            _buildTextField('Title', _titleController),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedContent,
              decoration: const InputDecoration(
                labelText: 'Content Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                ..._contentTypes.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (val) => setState(() => _selectedContent = val),
            ),

            const SizedBox(height: 20),

            Text('Languages', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  _availableLanguages.map((lang) {
                    final isSelected = _selectedLanguages.contains(lang);
                    return FilterChip(
                      label: Text(lang.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedLanguages.add(lang);
                          } else {
                            _selectedLanguages.remove(lang);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),

            const SizedBox(height: 20),

            Text('Formats', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  _availableFormats.map((fmt) {
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
                  }).toList(),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final filter = DownloadFilterModel(
                    isbn: _isbnController.text.trim(),
                    author: _authorController.text.trim(),
                    title: _titleController.text.trim(),
                    content: _selectedContent,
                    languages: _selectedLanguages,
                    formats: _selectedFormats,
                  );
                  widget.onApply(filter);
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
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

  void _resetFilters() {
    setState(() {
      _isbnController.clear();
      _authorController.clear();
      _titleController.clear();
      _selectedContent = null;
      _selectedLanguages = ['de'];
      _selectedFormats = List.from(DownloadFilterModel.allFormats);
    });
  }
}
