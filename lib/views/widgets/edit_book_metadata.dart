import 'package:calibre_web_companion/models/opds_item_model.dart';
import 'package:calibre_web_companion/utils/snack_bar.dart';
import 'package:calibre_web_companion/view_models/book_details_view_model.dart';
import 'package:calibre_web_companion/view_models/book_metadata_edit_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditBookMetadata extends StatefulWidget {
  final BookItem book;
  final bool isLoading;
  final BookDetailsViewModel viewModel;

  const EditBookMetadata({
    super.key,
    required this.book,
    required this.isLoading,
    required this.viewModel,
  });

  @override
  State<EditBookMetadata> createState() => _EditBookMetadataState();
}

class _EditBookMetadataState extends State<EditBookMetadata> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return IconButton(
      icon: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(Icons.edit),
      ),
      onPressed:
          widget.isLoading
              ? null
              : () async {
                // Initialise ViewModel
                final viewModel = Provider.of<BookMetadataEditViewModel>(
                  context,
                  listen: false,
                );

                await viewModel.initializeWithBook(widget.book);

                if (!context.mounted) return;

                // Show dialog
                final result = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => _buildMetadataDialog(context, viewModel),
                );

                if (result == true && context.mounted) {
                  await widget.viewModel.reloadBook(bookUuid: widget.book.uuid);
                  // ignore: use_build_context_synchronously
                  context.showSnackBar(
                    localizations.metadataUpdateSuccessfully,
                    isError: false,
                  );
                }
              },
      tooltip: localizations.editBookMetadata,
    );
  }

  Widget _buildMetadataDialog(
    BuildContext context,
    BookMetadataEditViewModel viewModel,
  ) {
    final localizations = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<BookMetadataEditViewModel>(
        builder: (context, model, _) {
          return AlertDialog(
            title: Text(localizations.editBookMetadata),
            content: SingleChildScrollView(
              child: _buildMetadataForm(context, model, localizations),
            ),
            actions: [
              TextButton(
                onPressed:
                    model.isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                child: Text(localizations.cancel),
              ),
              ElevatedButton(
                onPressed:
                    model.isLoading
                        ? null
                        : () async {
                          final success = await model.saveMetadata(
                            widget.book.id,
                          );
                          if (context.mounted) {
                            if (!success) {
                              context.showSnackBar(
                                model.errorMessage ??
                                    localizations.updateFailed,
                                isError: true,
                              );
                            }
                            Navigator.of(context).pop(success);
                          }
                        },
                child:
                    model.isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(localizations.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetadataForm(
    BuildContext context,
    BookMetadataEditViewModel model,
    AppLocalizations localizations,
  ) {
    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: model.titleController,
            decoration: InputDecoration(labelText: localizations.title),
            enabled: !model.isLoading,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: model.authorsController,
            decoration: InputDecoration(labelText: localizations.authors),
            enabled: !model.isLoading,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: model.commentsController,
            decoration: InputDecoration(labelText: localizations.description),
            minLines: 3,
            maxLines: 5,
            enabled: !model.isLoading,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: model.tagsController,
            decoration: InputDecoration(
              labelText: localizations.categories,
              helperText: localizations.separateWithCommas,
            ),
            enabled: !model.isLoading,
          ),
          const SizedBox(height: 16),

          // Row(
          //   children: [
          //     Expanded(
          //       flex: 2,
          //       child: TextFormField(
          //         controller: model.seriesController,
          //         decoration: InputDecoration(labelText: localizations.series),
          //         enabled: !model.isLoading,
          //       ),
          //     ),
          //     const SizedBox(width: 8),
          //     Expanded(
          //       child: TextFormField(
          //         controller: model.seriesIndexController,
          //         decoration: InputDecoration(labelText: localizations.book),
          //         keyboardType: TextInputType.number,
          //         enabled: !model.isLoading,
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 16),

          // TextFormField(
          //   controller: model.ratingController,
          //   decoration: InputDecoration(
          //     labelText: localizations.rating,
          //     helperText: localizations.ratingOneToTen,
          //   ),
          //   keyboardType: TextInputType.number,
          //   enabled: !model.isLoading,
          // ),
          // const SizedBox(height: 16),

          // TextFormField(
          //   controller: model.publisherController,
          //   decoration: InputDecoration(labelText: localizations.publisher),
          //   enabled: !model.isLoading,
          // ),
          // const SizedBox(height: 16),

          // TextFormField(
          //   controller: model.languageController,
          //   decoration: InputDecoration(labelText: localizations.language),
          //   enabled: !model.isLoading,
          // ),
          if (model.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              model.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
