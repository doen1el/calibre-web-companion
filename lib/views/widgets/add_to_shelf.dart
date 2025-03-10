import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/models/shelf_model.dart';
import 'package:calibre_web_companion/view_models/shelf_view_model.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
    // Local loading state for the dialog
    bool isLoading = viewModel.isLoading;

    showDialog(
      context: context,
      builder: (context) {
        // Create a local listener to update the dialog when viewModel changes
        return StatefulBuilder(
          builder: (context, setState) {
            // Add listener for viewModel changes
            viewModel.addListener(() {
              // Update local loading state when viewModel changes
              if (mounted) {
                setState(() {
                  isLoading = viewModel.isLoading;
                });
              }
            });

            return AlertDialog(
              title: Text(localizations.selectShelf),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        height: 170,
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
                            return RadioListTile<ShelfModel>(
                              title: Text(shelf.title),
                              value: shelf,
                              groupValue: selectedShelf,
                              onChanged:
                                  isLoading
                                      ? null // Disable selection during loading
                                      : (ShelfModel? value) {
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
                // Cancel button (always enabled)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.cancel),
                ),

                // Only show these buttons when a shelf is selected and not loading
                if (!isLoading && selectedShelf != null) ...[
                  // Remove from shelf
                  TextButton(
                    onPressed: () async {
                      // Show loading first
                      setState(() {
                        isLoading = true;
                      });

                      bool success = await viewModel.removeFromShelf(
                        book.id,
                        selectedShelf!.id,
                      );

                      if (success) {
                        Navigator.pop(context);
                        Fluttertoast.showToast(
                          msg: localizations.bookRemovedFromShelf(
                            selectedShelf!.title,
                          ),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      } else {
                        // Reset loading if operation fails
                        setState(() {
                          isLoading = false;
                        });
                        Fluttertoast.showToast(
                          msg: localizations.failedToRemoveFromShelf,
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: Text(localizations.removeFromShelf),
                  ),

                  // Add to shelf button
                  TextButton(
                    onPressed: () async {
                      // Show loading first
                      setState(() {
                        isLoading = true;
                      });

                      bool success = await viewModel.addToShelf(
                        book.id,
                        selectedShelf!.id,
                      );

                      if (success) {
                        Navigator.pop(context);
                        Fluttertoast.showToast(
                          msg: localizations.bookAddedToShelf(
                            selectedShelf!.title,
                          ),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      } else {
                        // Reset loading if operation fails
                        setState(() {
                          isLoading = false;
                        });
                        Fluttertoast.showToast(
                          msg: localizations.failedToAddToShelf,
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(localizations.addToShelf),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
