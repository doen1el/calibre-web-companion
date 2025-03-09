import 'package:calibre_web_companion/view_models/shelf_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: viewModel.createShelf,
      //   label: Row(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Icon(Icons.add),
      //       const SizedBox(width: 8),
      //       Text("createShelf"),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _buildShelfsList(
    BuildContext context,
    ShelfViewModel viewModel,
    AppLocalizations localizations,
  ) {
    if (viewModel.shelves.isEmpty) {
      return viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height / 2 - 100),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_stories,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "noShelvesFound",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        "createShelfMessage",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
    }

    // Return ListView directly (not inside SingleChildScrollView)
    return ListView.builder(
      // Let the ListView be scrollable on its own
      itemCount: viewModel.shelves.length,
      itemBuilder: (context, index) {
        final shelf = viewModel.shelves[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.list_rounded),
            title: Text(shelf.title),
            trailing: const Icon(Icons.chevron_right),
            // onTap:
            //     () => Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) => ShelfDetailsView(shelfId: shelf.id),
            //       ),
            //     ),
          ),
        );
      },
    );
  }
}
