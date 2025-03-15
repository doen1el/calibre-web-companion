import 'package:calibre_web_companion/utils/snack_bar.dart';
import 'package:calibre_web_companion/view_models/shelf_view_model.dart';
import 'package:calibre_web_companion/views/shelf_details_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ShelfsView extends StatelessWidget {
  const ShelfsView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ShelfViewModel>();
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.shelfs)),
      body: RefreshIndicator(
        onRefresh: viewModel.loadShelfs,
        child: _buildShelfsList(context, viewModel, localizations),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => _showCreateShelfDialog(context, localizations, viewModel),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded),
            const SizedBox(width: 8),
            Text(localizations.createShelf),
          ],
        ),
      ),
    );
  }

  Widget _buildShelfsList(
    BuildContext context,
    ShelfViewModel viewModel,
    AppLocalizations localizations,
  ) {
    if (viewModel.isLoading) {
      return Skeletonizer(
        enabled: viewModel.isLoading,
        effect: ShimmerEffect(
          // ignore: deprecated_member_use
          baseColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          // ignore: deprecated_member_use
          highlightColor: Theme.of(
            context,
            // ignore: deprecated_member_use
          ).colorScheme.primary.withOpacity(0.4),
        ),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.list_rounded),
                title: Text("Shelf Title"),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            );
          },
        ),
      );
    }

    if (viewModel.shelves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_rounded,
              size: 64,
              // ignore: deprecated_member_use
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noShelvesFoundCreateOne,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: viewModel.shelves.length,
      itemBuilder: (context, index) {
        final shelf = viewModel.shelves[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.list_rounded),
            title: Text(shelf.title),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ShelfDetailsView(shelfId: shelf.id),
                  ),
                ),
          ),
        );
      },
    );
  }

  /// Show a dialog to create a new shelf
  ///
  /// Parameters:
  ///
  /// - `context`: The current [BuildContext]
  /// - `localizations`: The [AppLocalizations] instance
  /// - `viewModel`: The [ShelfViewModel] instance
  void _showCreateShelfDialog(
    BuildContext context,
    AppLocalizations localizations,
    ShelfViewModel viewModel,
  ) {
    final controller = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.createShelf),
              content: SizedBox(
                width: double.maxFinite,
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: localizations.shelfName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.list_rounded),
                  ),
                  autofocus: true,
                  enabled: !isCreating,
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isCreating ? null : () => Navigator.of(context).pop(),
                  child: Text(localizations.cancel),
                ),
                ElevatedButton(
                  onPressed:
                      isCreating
                          ? null
                          : () async {
                            if (controller.text.trim().isEmpty) {
                              context.showSnackBar(
                                localizations.shelfNameRequired,
                                isError: true,
                              );

                              return;
                            }

                            setState(() {
                              isCreating = true;
                            });

                            final res = await viewModel.createShelf(
                              controller.text,
                            );

                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();

                            if (res) {
                              context.showSnackBar(
                                localizations.shelfSuccessfullyCreated(
                                  controller.text,
                                ),
                                isError: false,
                              );
                            } else {
                              // ignore: use_build_context_synchronously
                              context.showSnackBar(
                                localizations.errorCreatingShelf(
                                  controller.text,
                                ),
                                isError: true,
                              );
                            }
                          },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCreating)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      if (isCreating) const SizedBox(width: 8),
                      Text(
                        isCreating
                            ? localizations.creating
                            : localizations.create,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
