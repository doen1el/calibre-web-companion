import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/models/shelf_model.dart';
import 'package:calibre_web_companion/view_models/shelf_view_model.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddToShelf extends StatefulWidget {
  final BookItem book;
  final bool isLoading;
  const AddToShelf({super.key, required this.book, required this.isLoading});

  @override
  AddToShelfState createState() => AddToShelfState();
}

class AddToShelfState extends State<AddToShelf> {
  var logger = Logger();
  bool _isLoading = true;
  List<ShelfModel> _containingShelves = [];
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isLoading) {
      _loadShelfsAndCheckContaining();
    }
  }

  @override
  void didUpdateWidget(AddToShelf oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isLoading && !widget.isLoading && !_hasChecked) {
      _loadShelfsAndCheckContaining();
    }

    if (oldWidget.book.id != widget.book.id) {
      _loadShelfsAndCheckContaining();
    }
  }

  /// Loads the shelves and checks if the book is already in any of them.
  Future<void> _loadShelfsAndCheckContaining() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      logger.i(
        'Loading shelfs for book: ${widget.book.id} (${widget.book.title})',
      );

      final viewModel = context.read<ShelfViewModel>();
      await viewModel.loadShelfs();

      logger.d('Finding shelves containing book ${widget.book.id}');
      final containingShelves = await viewModel.findShelvesContainingBook(
        widget.book.id,
      );

      logger.i('Found ${containingShelves.length} shelves containing the book');

      if (mounted) {
        setState(() {
          _containingShelves = containingShelves;
          _isLoading = false;
          _hasChecked = true;
        });
      }
    } catch (e, stack) {
      logger.e('Error loading shelves: $e');
      logger.d('Stack trace: $stack');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChecked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ShelfViewModel>();
    AppLocalizations localizations = AppLocalizations.of(context)!;

    Widget icon;
    if (_isLoading) {
      icon = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      );
    } else if (_containingShelves.isNotEmpty) {
      icon = Badge(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        label: Text(
          _containingShelves.length.toString(),
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        ),
        child: const Icon(Icons.playlist_add_check_rounded),
      );
    } else {
      icon = const Icon(Icons.playlist_add_rounded);
    }

    return IconButton(
      onPressed:
          widget.isLoading
              ? null
              : () => _showShelfDialog(context, localizations, viewModel),
      icon: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,

        child: icon,
      ),
      tooltip:
          _containingShelves.isNotEmpty
              ? localizations.manageBookShelves
              : localizations.addToShelf,
    );
  }

  /// Shows a dialog with a list of shelves to add/remove the book from.
  ///
  /// Parameters:
  ///
  /// - `context`: The [BuildContext] of the widget.
  /// - `localizations`: The [AppLocalizations] instance.
  /// - `viewModel`: The [ShelfViewModel] instance.
  void _showShelfDialog(
    BuildContext context,
    AppLocalizations localizations,
    ShelfViewModel viewModel,
  ) {
    bool isDialogLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                _containingShelves.isNotEmpty
                    ? localizations.manageBookShelves
                    : localizations.selectShelf,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_containingShelves.isNotEmpty) ...[
                      Text(
                        localizations.bookInShelfs(_containingShelves.length),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    if (isDialogLoading || viewModel.isLoading)
                      const SizedBox(
                        height: 168,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (viewModel.shelves.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              size: 48,
                              color: Theme.of(
                                context,
                                // ignore: deprecated_member_use
                              ).colorScheme.secondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizations.noShelvesFound,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: viewModel.shelves.length,
                          itemBuilder: (context, index) {
                            final shelf = viewModel.shelves[index];
                            final isInShelf = _containingShelves.any(
                              (s) => s.id == shelf.id,
                            );

                            return ListTile(
                              title: Text(shelf.title),
                              leading: Icon(
                                isInShelf
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color:
                                    isInShelf
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                              ),
                              enabled: !isDialogLoading,
                              onTap: () async {
                                setDialogState(() {
                                  isDialogLoading = true;
                                });

                                await _handleShelfAction(
                                  context,
                                  viewModel,
                                  shelf,
                                  isInShelf,
                                  onComplete: () {
                                    setDialogState(() {
                                      isDialogLoading = false;
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.close),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Handles adding or removing a book from a shelf with proper state updates
  ///
  /// Parameters:
  ///
  /// - `context`: The [BuildContext] of the widget.
  /// - `viewModel`: The [ShelfViewModel] instance.
  /// - `shelf`: The [ShelfModel] to add/remove the book from.
  /// - `isInShelf`: Whether the book is already in the shelf.
  /// - `onComplete`: A callback to call when the action is completed.
  Future<void> _handleShelfAction(
    BuildContext context,
    ShelfViewModel viewModel,
    ShelfModel shelf,
    bool isInShelf, {
    required VoidCallback onComplete,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    bool success;

    setState(() => _isLoading = true);

    try {
      if (isInShelf) {
        success = await viewModel.removeFromShelf(shelf.id, widget.book.id);
        if (success) {
          setState(() {
            _containingShelves.removeWhere((s) => s.id == shelf.id);
          });

          _showSnackBar(
            // ignore: use_build_context_synchronously
            context,
            localizations.bookRemovedFromShelf(shelf.title),
            isError: false,
          );
        } else {
          _showSnackBar(
            // ignore: use_build_context_synchronously
            context,
            localizations.failedToRemoveFromShelf,
            isError: true,
          );
        }
      } else {
        success = await viewModel.addToShelf(shelf.id, widget.book.id);
        if (success) {
          setState(() {
            _containingShelves.add(shelf);
          });

          _showSnackBar(
            // ignore: use_build_context_synchronously
            context,
            localizations.bookAddedToShelf(shelf.title),
            isError: false,
          );
        } else {
          _showSnackBar(
            // ignore: use_build_context_synchronously
            context,
            localizations.failedToAddToShelf,
            isError: true,
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);

      onComplete();
    }
  }

  /// Shows a snackbar with a message.
  ///
  /// Parameters:
  ///
  /// - `context`: The [BuildContext] of the widget.
  /// - `message`: The message to show.
  /// - `isError`: Whether the message is an error message.
  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
