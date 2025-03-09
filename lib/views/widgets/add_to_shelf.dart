import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/models/shelf_model.dart';
import 'package:calibre_web_companion/view_models/shelf_view_model.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddToShelf extends StatefulWidget {
  final BookItem book;
  const AddToShelf({super.key, required this.book});

  @override
  AddToShelfState createState() => AddToShelfState();
}

class AddToShelfState extends State<AddToShelf> {
  var logger = Logger();

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<ShelfViewModel>();
    viewModel.loadShelfs();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ShelfViewModel>();
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return IconButton(
      onPressed:
          () =>
              _showShelfDialog(context, localizations, viewModel, widget.book),
      icon: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: const Icon(Icons.playlist_add_rounded),
      ),
      tooltip: localizations.addToShelf,
    );
  }

  /// Shows a dialog to select a shelf and perform actions
  void _showShelfDialog(
    BuildContext context,
    AppLocalizations localizations,
    ShelfViewModel viewModel,
    BookItem book,
  ) {
    // Track the selected shelf
    ShelfModel? selectedShelf;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(localizations.selectShelf),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (viewModel.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (viewModel.shelves.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.bookmark_border,
                                  size: 48,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.5),
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
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: viewModel.shelves.length,
                              itemBuilder: (context, index) {
                                final shelf = viewModel.shelves[index];
                                return RadioListTile<ShelfModel>(
                                  title: Text(shelf.title),
                                  value: shelf,
                                  groupValue: selectedShelf,
                                  onChanged: (ShelfModel? value) {
                                    setState(() {
                                      selectedShelf = value;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    // Cancel button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations.cancel),
                    ),

                    // Remove from shelf button
                    TextButton(
                      onPressed: () async {
                        bool success = await viewModel.removeFromShelf(
                          book.id,
                          selectedShelf!.id,
                        );
                        if (success) {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.bookRemovedFromShelf(
                                  selectedShelf!.title,
                                ),
                              ),
                            ),
                          );
                        } else {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.failedToRemoveFromShelf,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(localizations.removeFromShelf),
                    ),
                    // Only show these buttons when a shelf is selected and not loading
                    if (!viewModel.isLoading && selectedShelf != null) ...[
                      // Add to shelf button
                      TextButton(
                        onPressed: () async {
                          bool success = await viewModel.addToShelf(
                            book.id,
                            selectedShelf!.id,
                          );
                          if (success) {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizations.bookAddedToShelf(
                                    selectedShelf!.title,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(localizations.failedToAddToShelf),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: Text(localizations.addToShelf),
                      ),
                    ],
                  ],
                ),
          ),
    );
  }
}
