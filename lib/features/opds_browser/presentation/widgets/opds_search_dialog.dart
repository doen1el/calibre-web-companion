import 'dart:async';

import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';
import 'package:calibre_web_companion/shared/widgets/book_cover_widget.dart';
import 'package:flutter/material.dart';

/// Pops with either the query to search for (a [String]) or a suggested
/// [BookViewModel] to open directly.
class OpdsSearchDialog extends StatefulWidget {
  final String? initialQuery;
  final Future<List<BookViewModel>> Function(String query) suggest;

  const OpdsSearchDialog({super.key, required this.suggest, this.initialQuery});

  @override
  State<OpdsSearchDialog> createState() => _OpdsSearchDialogState();
}

class _OpdsSearchDialogState extends State<OpdsSearchDialog> {
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  bool _loading = false;
  String _latestQuery = '';
  List<BookViewModel> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetch(text));
  }

  Future<void> _fetch(String text) async {
    final query = text.trim();
    _latestQuery = query;
    if (query.length < 2) {
      setState(() {
        _loading = false;
        _suggestions = const [];
      });
      return;
    }

    setState(() => _loading = true);
    List<BookViewModel> results;
    try {
      results = await widget.suggest(query);
    } catch (_) {
      results = const [];
    }
    // A slower earlier request must not overwrite newer suggestions.
    if (!mounted || query != _latestQuery) return;

    setState(() {
      _loading = false;
      _suggestions = results.take(8).toList();
    });
  }

  void _submit(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    Navigator.of(context).pop(query);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.searchBook),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
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
                    final book = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 28,
                        height: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: BookCoverWidget(
                            bookId: book.id,
                            coverUrl: book.coverUrl,
                          ),
                        ),
                      ),
                      title: Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        book.authors,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(context).pop(book),
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
