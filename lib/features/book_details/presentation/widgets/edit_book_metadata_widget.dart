import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/shared/widgets/coming_soon_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';

class EditBookMetadataWidget extends StatefulWidget {
  final BookDetailsModel book;
  final bool isLoading;
  final BookViewModel bookViewModel;

  const EditBookMetadataWidget({
    super.key,
    required this.book,
    required this.isLoading,
    required this.bookViewModel,
  });

  @override
  State<EditBookMetadataWidget> createState() => _EditBookMetadataWidgetState();
}

class _EditBookMetadataWidgetState extends State<EditBookMetadataWidget> {
  late TextEditingController _titleController;
  late TextEditingController _authorsController;
  late TextEditingController _commentsController;
  late TextEditingController _tagsController;

  Uint8List? _selectedCoverBytes;
  String? _selectedCoverName;

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
                showComingSoonDialog(
                  context,
                  "The edit book metadata feature is coming soon!",
                );
                // final result = await showDialog<bool>(
                //   context: context,
                //   builder: (context) => _buildMetadataDialog(context),
                // );

                // if (result == true && context.mounted) {
                //   context.showSnackBar(
                //     localizations.metadataUpdateSuccessfully,
                //     isError: false,
                //   );

                //   Navigator.of(context).pop();

                //   context.read<BookDetailsBloc>().add(
                //     ReloadBookDetails(
                //       widget.bookViewModel,
                //       widget.bookViewModel.uuid,
                //     ),
                //   );
                // }
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
                              coverImageBytes: _selectedCoverBytes,
                              coverFileName: _selectedCoverName ?? 'cover.jpg',
                              bookDetails: widget.book,
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
    final localizations = AppLocalizations.of(context)!;

    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.bookCover,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          Center(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 220,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child:
                        _selectedCoverBytes != null
                            ? Image.memory(
                              _selectedCoverBytes!,
                              fit: BoxFit.contain,
                            )
                            : _buildCoverImage(
                              context,
                              widget.book.id,
                              localizations,
                            ),
                  ),
                ),

                Positioned(
                  right: 8,
                  bottom: 8,
                  child: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    radius: 20,
                    child: IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      onPressed: isLoading ? null : _pickImage,
                      tooltip: localizations.selectCover,
                    ),
                  ),
                ),

                if (_selectedCoverBytes != null)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      radius: 20,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        onPressed: isLoading ? null : _confirmCoverRemoval,
                        tooltip: localizations.removeCover,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
        ],
      ),
    );
  }

  Future<void> _confirmCoverRemoval() async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.removeCover),
            content: Text(localizations.removeCoverConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(localizations.remove),
              ),
            ],
          ),
    );

    // TODO: Handle the case where the user deletes the cover image
    if (confirmed == true) {
      _clearSelectedCover();

      setState(() {});
    }
  }

  // TODO: Implement a placeholder widget for when no cover is available
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .5),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.noCover,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedCoverBytes = bytes;
          _selectedCoverName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
      }
    }
  }

  void _clearSelectedCover() {
    setState(() {
      _selectedCoverBytes = null;
      _selectedCoverName = null;
    });
  }

  Widget _buildCoverImage(
    BuildContext context,
    int bookId,
    AppLocalizations localizations,
  ) {
    final apiService = ApiService();
    final baseUrl = apiService.getBaseUrl();
    final coverUrl = '$baseUrl/opds/cover/$bookId';

    return FutureBuilder<Map<String, String>>(
      future: () async {
        final headers = <String, String>{};
        final cookie = await apiService.getCookieHeader();
        if (cookie != null && cookie.trim().isNotEmpty) {
          headers['Cookie'] = cookie;
        }
        final custom = await apiService.getProcessedCustomHeaders();
        headers.addAll(custom);
        final username = apiService.getUsername();
        final password = apiService.getPassword();
        if (username.isNotEmpty && password.isNotEmpty) {
          headers['Authorization'] =
              'Basic ${base64.encode(utf8.encode('$username:$password'))}';
        }
        headers['Accept'] = 'image/avif;q=0,image/webp;q=0,image/jpeg,image/png,*/*;q=0.5';
        headers['Cache-Control'] = 'no-transform';
        return headers;
      }(),
      builder: (context, snapshot) {
        final headers = snapshot.data ?? const <String, String>{};
        return CachedNetworkImage(
          imageUrl: coverUrl,
          height: 150,
          fit: BoxFit.contain,
          httpHeaders: headers,
          placeholder: (context, url) => Container(
            height: 150,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Image.network(
            coverUrl,
            headers: headers,
            fit: BoxFit.contain,
            height: 150,
            errorBuilder: (context, error, stack) => Container(
              height: 150,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }
}
