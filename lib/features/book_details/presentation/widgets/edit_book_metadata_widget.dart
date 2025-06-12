import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';

class EditBookMetadataWidget extends StatefulWidget {
  final BookDetailsModel book;
  final bool isLoading;

  const EditBookMetadataWidget({
    super.key,
    required this.book,
    required this.isLoading,
  });

  @override
  State<EditBookMetadataWidget> createState() => _EditBookMetadataWidgetState();
}

class _EditBookMetadataWidgetState extends State<EditBookMetadataWidget> {
  late TextEditingController _titleController;
  late TextEditingController _authorsController;
  late TextEditingController _commentsController;
  late TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(EditBookMetadataWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      _initControllers();
    }
  }

  void _initControllers() {
    _titleController = TextEditingController(text: widget.book.title);
    _authorsController = TextEditingController(text: widget.book.authors);
    _commentsController = TextEditingController(text: widget.book.comments);
    _tagsController = TextEditingController(text: widget.book.tags.join(', '));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _commentsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return IconButton(
      icon: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: const Icon(Icons.edit),
      ),
      onPressed:
          widget.isLoading
              ? null
              : () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => _buildMetadataDialog(context),
                );

                if (result == true && context.mounted) {
                  context.showSnackBar(
                    localizations.metadataUpdateSuccessfully,
                    isError: false,
                  );
                }
              },
      tooltip: localizations.editBookMetadata,
    );
  }

  Widget _buildMetadataDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider.value(
      value: context.read<BookDetailsBloc>(),
      child: BlocConsumer<BookDetailsBloc, BookDetailsState>(
        listenWhen:
            (previous, current) =>
                previous.metadataUpdateState != current.metadataUpdateState,
        listener: (context, state) {
          if (state.metadataUpdateState == MetadataUpdateState.success) {
            Navigator.of(context).pop(true);
          } else if (state.metadataUpdateState == MetadataUpdateState.error) {
            context.showSnackBar(
              state.errorMessage ?? localizations.updateFailed,
              isError: true,
            );
          }
        },
        buildWhen:
            (previous, current) =>
                previous.metadataUpdateState != current.metadataUpdateState,
        builder: (context, state) {
          final isLoading =
              state.metadataUpdateState == MetadataUpdateState.loading;

          return AlertDialog(
            title: Text(localizations.editBookMetadata),
            content: SingleChildScrollView(
              child: _buildMetadataForm(context, isLoading, localizations),
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.of(context).pop(false),
                child: Text(localizations.cancel),
              ),
              ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : () {
                          context.read<BookDetailsBloc>().add(
                            UpdateBookMetadata(
                              bookId: widget.book.id.toString(),
                              title: _titleController.text,
                              authors: _authorsController.text,
                              comments: _commentsController.text,
                              tags: _tagsController.text,
                            ),
                          );
                        },
                child:
                    isLoading
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
    bool isLoading,
    AppLocalizations localizations,
  ) {
    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(labelText: localizations.title),
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _authorsController,
            decoration: InputDecoration(labelText: localizations.authors),
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _commentsController,
            decoration: InputDecoration(labelText: localizations.description),
            minLines: 3,
            maxLines: 5,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: localizations.categories,
              helperText: localizations.separateWithCommas,
            ),
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
