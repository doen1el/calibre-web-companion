import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:calibre_web_companion/shared/widgets/app_skeletonizer.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/main.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_state.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/magic_shelf_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/repositories/shelf_view_repository.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_bloc.dart';
import 'package:calibre_web_companion/features/shelf_details/presentation/pages/shelf_details_page.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

class AddToShelfWidget extends StatefulWidget {
  final BookDetailsModel book;
  final bool isLoading;

  const AddToShelfWidget({
    super.key,
    required this.book,
    required this.isLoading,
  });

  @override
  State<AddToShelfWidget> createState() => _AddToShelfWidgetState();
}

class _AddToShelfWidgetState extends State<AddToShelfWidget> {
  final _repo = getIt<ShelfViewRepository>();
  List<ShelfViewModel> _containingShelves = [];
  List<MagicShelfModel> _magicShelves = const [];
  bool _hasChecked = false;
  bool _magicLoading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isLoading) {
      _loadShelvesAndCheckContaining();
    }
  }

  @override
  void didUpdateWidget(AddToShelfWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isLoading && !widget.isLoading && !_hasChecked) {
      _loadShelvesAndCheckContaining();
    }

    if (oldWidget.book.id != widget.book.id) {
      _loadShelvesAndCheckContaining();
    }
  }

  void _loadShelvesAndCheckContaining() {
    if (!mounted) return;

    if (widget.book.uuid.isEmpty) {
      return;
    }

    final shelfBloc = context.read<ShelfViewBloc>();
    if (shelfBloc.state.shelves.isEmpty &&
        shelfBloc.state.status != ShelfViewStatus.loading) {
      shelfBloc.add(const LoadShelves());
    }

    shelfBloc.add(FindShelvesContainingBook(widget.book.uuid.toString()));

    _magicLoading = true;
    _repo
        .findMagicShelvesContainingBook(widget.book.uuid.toString())
        .then((shelves) {
          if (mounted) {
            setState(() {
              _magicShelves = shelves;
              _magicLoading = false;
            });
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _magicLoading = false);
        });

    setState(() {
      _hasChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocConsumer<ShelfViewBloc, ShelfViewState>(
      listenWhen:
          (previous, current) =>
              previous.bookInShelves != current.bookInShelves ||
              previous.checkBookInShelfStatus != current.checkBookInShelfStatus,
      listener: (context, state) {
        setState(() {
          _containingShelves = state.bookInShelves;
        });
      },
      builder: (context, state) {
        final totalContaining =
            _containingShelves.length + _magicShelves.length;
        Widget icon;
        if (state.checkBookInShelfStatus == CheckBookInShelfStatus.loading ||
            _magicLoading) {
          icon = const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (totalContaining > 0) {
          icon = Badge(
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            label: Text(
              totalContaining.toString(),
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
          icon: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: icon,
          ),
          onPressed:
              widget.isLoading
                  ? null
                  : () => _showShelfDialog(context, localizations),
          tooltip:
              _containingShelves.isNotEmpty
                  ? localizations.manageBookShelves
                  : localizations.addToShelf,
        );
      },
    );
  }

  void _showShelfDialog(BuildContext context, AppLocalizations localizations) {
    bool isDialogLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<ShelfViewBloc>(),
          child: BlocBuilder<ShelfViewBloc, ShelfViewState>(
            builder: (context, shelfState) {
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  final totalContaining =
                      _containingShelves.length + _magicShelves.length;
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
                          if (totalContaining > 0) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                localizations.bookInShelfs(totalContaining),
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                          ],

                          if (isDialogLoading ||
                              shelfState.status == ShelfViewStatus.loading)
                            SizedBox(
                              height: 168,
                              child: AppSkeletonizer(
                                enabled: true,
                                effect: ShimmerEffect(
                                  baseColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: .2),
                                  highlightColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: .4),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: 4,
                                  itemBuilder:
                                      (context, index) => ListTile(
                                        title: Text(
                                          'Skeleton Shelf ${index + 1}',
                                        ),
                                        leading: const Icon(
                                          Icons.circle_outlined,
                                        ),
                                      ),
                                ),
                              ),
                            )
                          else if (shelfState.shelves.isEmpty &&
                              _magicShelves.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.bookmark_border,
                                    size: 48,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: .5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    localizations.noShelvesFound,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            )
                          else
                            Flexible(
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  ...List.generate(shelfState.shelves.length, (
                                    index,
                                  ) {
                                    final shelf = shelfState.shelves[index];
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
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                                : null,
                                      ),
                                      enabled: !isDialogLoading,
                                      onTap: () async {
                                        setDialogState(() {
                                          isDialogLoading = true;
                                        });

                                        await _handleShelfAction(
                                          context,
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
                                  }),
                                  if (_magicShelves.isNotEmpty &&
                                      shelfState.shelves.isNotEmpty)
                                    const Divider(),
                                  ..._magicShelves.map(
                                    (shelf) => ListTile(
                                      leading:
                                          shelf.icon != null
                                              ? Text(
                                                shelf.icon!,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                ),
                                              )
                                              : Icon(
                                                Icons.auto_awesome_rounded,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                              ),
                                      title: Text(shelf.name),
                                      trailing: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      onTap:
                                          () => _openMagicShelf(
                                            dialogContext,
                                            shelf,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    actions: [
                      AppDialogButton(
                        onPressed: () => Navigator.pop(context),
                        label: localizations.close,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _openMagicShelf(BuildContext dialogContext, MagicShelfModel shelf) {
    final shelfViewBloc = context.read<ShelfViewBloc>();
    Navigator.of(dialogContext).pop();
    Navigator.of(context).push(
      AppTransitions.createSlideRoute(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: shelfViewBloc),
            BlocProvider(create: (_) => getIt<ShelfDetailsBloc>()),
          ],
          child: ShelfDetailsPage(
            shelfId: shelf.id,
            shelfTitle: shelf.name,
            isPublic: shelf.isPublic,
            isMagic: true,
            icon: shelf.icon,
          ),
        ),
      ),
    );
  }

  Future<void> _handleShelfAction(
    BuildContext context,
    ShelfViewModel shelf,
    bool isInShelf, {
    required VoidCallback onComplete,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final shelfBloc = context.read<ShelfViewBloc>();
    final bookId = widget.book.id.toString();

    try {
      if (isInShelf) {
        shelfBloc.add(RemoveBookFromShelf(bookId: bookId, shelfId: shelf.id));

        setState(() {
          _containingShelves.removeWhere((s) => s.id == shelf.id);
        });

        context.showSnackBar(
          localizations.bookRemovedFromShelf(shelf.title),
          isError: false,
        );
      } else {
        shelfBloc.add(AddBookToShelf(bookId: bookId, shelfId: shelf.id));

        setState(() {
          _containingShelves.add(shelf);
        });

        context.showSnackBar(
          localizations.bookAddedToShelf(shelf.title),
          isError: false,
        );
      }
    } catch (e) {
      context.showSnackBar(
        isInShelf
            ? localizations.failedToRemoveFromShelf
            : localizations.failedToAddToShelf,
        isError: true,
      );
    } finally {
      onComplete();
    }
  }
}
