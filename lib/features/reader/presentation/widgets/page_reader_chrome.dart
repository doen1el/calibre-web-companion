import 'package:calibre_web_companion/features/reader/data/bookmark_store.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PageReaderChrome extends StatefulWidget {
  final String title;
  final int page;
  final int pageCount;
  final bool visible;
  final ValueChanged<int> onSeek;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleChrome;
  final List<Widget> actions;
  final bool reverseTapZones;
  final BookmarkStore? bookmarkStore;
  final Widget child;

  const PageReaderChrome({
    super.key,
    required this.title,
    required this.page,
    required this.pageCount,
    required this.visible,
    required this.onSeek,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleChrome,
    required this.child,
    this.actions = const [],
    this.reverseTapZones = false,
    this.bookmarkStore,
  });

  @override
  State<PageReaderChrome> createState() => _PageReaderChromeState();
}

class _PageReaderChromeState extends State<PageReaderChrome> {
  List<ReaderBookmark> _bookmarks = const [];

  @override
  void initState() {
    super.initState();
    final store = widget.bookmarkStore;
    if (store != null) {
      _bookmarks = store.active;
      store.sync().then((bookmarks) {
        if (mounted) setState(() => _bookmarks = bookmarks);
      });
    }
  }

  ReaderBookmark? get _bookmarkOnPage =>
      _bookmarks.where((b) => b.page == widget.page).firstOrNull;

  Future<void> _toggleBookmark() async {
    final store = widget.bookmarkStore;
    if (store == null || widget.pageCount == 0) return;
    final localizations = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final existing = _bookmarkOnPage;
    final bookmarks =
        existing != null
            ? await store.remove(existing.id)
            : await store.add(
              ReaderBookmark.create(
                page: widget.page,
                percentage:
                    widget.pageCount <= 1
                        ? 100
                        : widget.page / (widget.pageCount - 1) * 100,
                label: '',
              ),
            );
    if (!mounted) return;
    setState(() => _bookmarks = bookmarks);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            existing != null
                ? localizations.readerBookmarkRemoved
                : localizations.readerBookmarkAdded,
          ),
        ),
      );
  }

  Future<void> _showBookmarks() async {
    final store = widget.bookmarkStore;
    if (store == null) return;
    final page = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (context) => _BookmarkSheet(
            initial: _bookmarks,
            onRemove: (id) async {
              final bookmarks = await store.remove(id);
              if (mounted) setState(() => _bookmarks = bookmarks);
              return bookmarks;
            },
          ),
    );
    if (page != null) widget.onSeek(page);
  }

  void _onTapUp(BuildContext context, TapUpDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    final dx = details.globalPosition.dx;
    if (dx < width / 3) {
      widget.reverseTapZones ? widget.onNext() : widget.onPrevious();
    } else if (dx > width * 2 / 3) {
      widget.reverseTapZones ? widget.onPrevious() : widget.onNext();
    } else {
      widget.onToggleChrome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = theme.colorScheme.surface.withValues(alpha: .94);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _onTapUp(context, details),
              child: widget.child,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            top: widget.visible ? 0 : -120,
            left: 0,
            right: 0,
            child: Material(
              color: barColor,
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const BackButton(),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    ...widget.actions,
                    if (widget.bookmarkStore != null) ...[
                      IconButton(
                        tooltip: AppLocalizations.of(context)!.readerBookmarks,
                        icon: const Icon(Icons.bookmarks_outlined),
                        onPressed: _showBookmarks,
                      ),
                      IconButton(
                        tooltip:
                            _bookmarkOnPage != null
                                ? AppLocalizations.of(
                                  context,
                                )!.readerRemoveBookmark
                                : AppLocalizations.of(
                                  context,
                                )!.readerAddBookmark,
                        icon: Icon(
                          _bookmarkOnPage != null
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color:
                              _bookmarkOnPage != null
                                  ? theme.colorScheme.primary
                                  : null,
                        ),
                        onPressed: _toggleBookmark,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            bottom: widget.visible ? 0 : -140,
            left: 0,
            right: 0,
            child: Material(
              color: barColor,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            widget.pageCount > 1
                                ? Directionality(
                                  textDirection:
                                      widget.reverseTapZones
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                  child: Slider(
                                    value:
                                        widget.page
                                            .clamp(0, widget.pageCount - 1)
                                            .toDouble(),
                                    max: (widget.pageCount - 1).toDouble(),
                                    divisions: widget.pageCount - 1,
                                    label: '${widget.page + 1}',
                                    onChanged:
                                        (value) => widget.onSeek(value.round()),
                                  ),
                                )
                                : const SizedBox(height: 48),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.pageCount > 0
                            ? '${widget.page + 1} / ${widget.pageCount}'
                            : '',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkSheet extends StatefulWidget {
  final List<ReaderBookmark> initial;
  final Future<List<ReaderBookmark>> Function(String id) onRemove;

  const _BookmarkSheet({required this.initial, required this.onRemove});

  @override
  State<_BookmarkSheet> createState() => _BookmarkSheetState();
}

class _BookmarkSheetState extends State<_BookmarkSheet> {
  late List<ReaderBookmark> _bookmarks = widget.initial;

  Future<void> _remove(ReaderBookmark bookmark) async {
    setState(
      () => _bookmarks = _bookmarks.where((b) => b.id != bookmark.id).toList(),
    );
    final updated = await widget.onRemove(bookmark.id);
    if (mounted) setState(() => _bookmarks = updated);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                localizations.readerBookmarks,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (_bookmarks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  localizations.readerNoBookmarks,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, i) {
                    final bookmark = _bookmarks[i];
                    final page = bookmark.page ?? 0;
                    return Dismissible(
                      key: ValueKey(bookmark.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: theme.colorScheme.error,
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.onError,
                        ),
                      ),
                      onDismissed: (_) => _remove(bookmark),
                      child: ListTile(
                        leading: Icon(
                          Icons.bookmark,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(localizations.readerBookmarkPage(page + 1)),
                        subtitle: Text('${bookmark.percentage.round()}%'),
                        trailing: IconButton(
                          tooltip: localizations.readerRemoveBookmark,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _remove(bookmark),
                        ),
                        onTap: () => Navigator.of(context).pop(page),
                      ),
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
