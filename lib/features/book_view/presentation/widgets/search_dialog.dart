import 'dart:async';

import 'package:flutter/material.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/core/di/injection_container.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/features/book_view/data/datasources/vocabulary_remote_datasource.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';

class SearchDialog extends StatefulWidget {
  final String? initialQuery;

  const SearchDialog({super.key, this.initialQuery});

  @override
  SearchDialogState createState() => SearchDialogState();
}

class _Suggestion {
  final String value;
  final VocabularyType type;
  const _Suggestion(this.value, this.type);
}

class SearchDialogState extends State<SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final VocabularyRemoteDataSource _vocab = VocabularyRemoteDataSource(
    apiService: getIt<ApiService>(),
  );

  Timer? _debounce;
  bool _loading = false;
  List<_Suggestion> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _fetch(text));
  }

  Future<void> _fetch(String text) async {
    final query = text.trim();
    if (query.length < 2) {
      if (mounted) setState(() => _suggestions = const []);
      return;
    }

    setState(() => _loading = true);
    final results = await Future.wait([
      _vocab.suggest(VocabularyType.authors, query),
      _vocab.suggest(VocabularyType.series, query),
      _vocab.suggest(VocabularyType.tags, query),
    ]);
    if (!mounted) return;

    final merged = <_Suggestion>[
      ...results[0].take(4).map((v) => _Suggestion(v, VocabularyType.authors)),
      ...results[1].take(4).map((v) => _Suggestion(v, VocabularyType.series)),
      ...results[2].take(4).map((v) => _Suggestion(v, VocabularyType.tags)),
    ];

    setState(() {
      _loading = false;
      _suggestions = merged;
    });
  }

  void _submit(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    Navigator.of(context).pop(query);
  }

  IconData _iconFor(VocabularyType type) {
    switch (type) {
      case VocabularyType.authors:
        return Icons.person_rounded;
      case VocabularyType.series:
        return Icons.bookmark_rounded;
      case VocabularyType.tags:
        return Icons.label_rounded;
    }
  }

  String _labelFor(VocabularyType type, AppLocalizations localizations) {
    switch (type) {
      case VocabularyType.authors:
        return localizations.author;
      case VocabularyType.series:
        return localizations.series;
      case VocabularyType.tags:
        return localizations.tags;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.searchBook),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: localizations.enterTitleAuthorOrTags,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _onChanged,
              onSubmitted: _submit,
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            if (_suggestions.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(_iconFor(suggestion.type)),
                      title: Text(
                        suggestion.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_labelFor(suggestion.type, localizations)),
                      onTap: () => _submit(suggestion.value),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        AppDialogButton(
          onPressed: () => _submit(_controller.text),
          label: localizations.search,
        ),
      ],
    );
  }
}
