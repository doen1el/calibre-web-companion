import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:intl/intl.dart';

import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';

class EditBookMetadataWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return IconButton(
      icon: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: const Icon(Icons.edit),
      ),
      onPressed:
          isLoading
              ? null
              : () async {
                final bloc = context.read<BookDetailsBloc>();

                final result = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => BlocProvider.value(
                        value: bloc,
                        child: _EditBookMetadataDialog(
                          book: book,
                          bookViewModel: bookViewModel,
                        ),
                      ),
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
}

class _EditBookMetadataDialog extends StatefulWidget {
  final BookDetailsModel book;
  final BookViewModel bookViewModel;

  const _EditBookMetadataDialog({
    required this.book,
    required this.bookViewModel,
  });

  @override
  State<_EditBookMetadataDialog> createState() =>
      _EditBookMetadataDialogState();
}

class _EditBookMetadataDialogState extends State<_EditBookMetadataDialog> {
  late TextEditingController _titleController;
  late TextEditingController _authorsController;
  late TextEditingController _commentsController;
  late TextEditingController _tagsController;
  late TextEditingController _seriesController;
  late TextEditingController _seriesIndexController;
  late TextEditingController _pubdateController;
  late TextEditingController _publisherController;
  late TextEditingController _languagesController;

  double _currentRating = 0.0;
  bool _isInitialized = false;

  Uint8List? _selectedCoverBytes;
  String? _selectedCoverName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final localizations = AppLocalizations.of(context)!;
      _initControllers(localizations);
      _isInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void _initControllers(AppLocalizations localizations) {
    _titleController = TextEditingController(text: widget.book.title);
    _authorsController = TextEditingController(text: widget.book.authors);
    _commentsController = TextEditingController(text: widget.book.comments);
    _tagsController = TextEditingController(text: widget.book.tags.join(', '));

    _seriesController = TextEditingController(text: widget.book.series);
    _seriesIndexController = TextEditingController(
      text: widget.book.seriesIndex.toString(),
    );

    String formattedDate = '';
    if (widget.book.pubdate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(widget.book.pubdate);
        formattedDate = DateFormat('yyyy-MM-dd').format(parsed);
      } catch (e) {
        formattedDate = widget.book.pubdate;
      }
    }
    _pubdateController = TextEditingController(text: formattedDate);

    _publisherController = TextEditingController(text: widget.book.publishers);

    final langMap = _getLanguageMap(localizations);
    final rawLangs =
        widget.book.languages.split(',').map((e) => e.trim()).toList();
    final displayLangs = rawLangs
        .map((code) {
          return langMap[code.toLowerCase()] ?? code;
        })
        .join(', ');

    _languagesController = TextEditingController(text: displayLangs);

    _currentRating = widget.book.rating / 2;
  }

  Map<String, String> _getLanguageMap(AppLocalizations localizations) {
    return {
      'eng': localizations.english,
      'deu': localizations.german,
      'fra': localizations.french,
      'spa': localizations.spanish,
      'ita': localizations.italian,
      'jpn': localizations.japanese,
      'rus': localizations.russian,
      'por': localizations.portuguese,
      'chi': localizations.chineese,
      'nld': localizations.dutch,
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _commentsController.dispose();
    _tagsController.dispose();
    _seriesController.dispose();
    _seriesIndexController.dispose();
    _pubdateController.dispose();
    _publisherController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ),
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
                              series: _seriesController.text,
                              seriesIndex: _seriesIndexController.text,
                              pubdate: _pubdateController.text,
                              publisher: _publisherController.text,
                              languages: _languagesController.text,
                              rating: _currentRating,
                              coverImageBytes: _selectedCoverBytes,
                              coverFileName: _selectedCoverName ?? 'cover.jpg',
                              bookDetails: widget.book,
                            ),
                          );
                        },
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          localizations.save,
                          style: TextStyle(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
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
          Center(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 140,
                    height: 200,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child:
                        _selectedCoverBytes != null
                            ? Image.memory(
                              _selectedCoverBytes!,
                              fit: BoxFit.cover,
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
                    radius: 18,
                    child: IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 18,
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
                      radius: 18,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: 18,
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

          _buildStyledTextField(
            controller: _titleController,
            label: localizations.title,
            icon: Icons.title,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),

          _buildStyledTextField(
            controller: _authorsController,
            label: localizations.authors,
            icon: Icons.person,
            enabled: !isLoading,
            helperText: localizations.separateWithAnd,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildStyledTextField(
                  controller: _seriesController,
                  label: localizations.series,
                  icon: Icons.collections_bookmark,
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildStyledTextField(
                  controller: _seriesIndexController,
                  label: '#',
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildStyledTextField(
            controller: _publisherController,
            label: localizations.publisher,
            icon: Icons.business,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStyledTextField(
                  controller: _pubdateController,
                  label: localizations.published,
                  hint: 'YYYY-MM-DD',
                  icon: Icons.calendar_today,
                  enabled: !isLoading,
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.tryParse(_pubdateController.text) ??
                          DateTime.now(),
                      firstDate: DateTime(1800),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      _pubdateController.text = formattedDate;
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStyledTextField(
                  controller: _languagesController,
                  label: localizations.language,
                  icon: Icons.language,
                  enabled: !isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildStyledTextField(
            controller: _tagsController,
            label: localizations.tags,
            icon: Icons.label,
            helperText: localizations.separateWithCommas,
            enabled: !isLoading,
          ),
          const SizedBox(height: 24),

          Text(
            localizations.rating,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          StarRating(
            starCount: 5,
            rating: _currentRating,
            allowHalfRating: true,
            color: Colors.amber,
            borderColor: Theme.of(context).colorScheme.outline,
            onRatingChanged:
                (rating) => setState(() => _currentRating = rating),
          ),

          const SizedBox(height: 24),

          _buildStyledTextField(
            controller: _commentsController,
            label: localizations.description,
            icon: Icons.description,
            minLines: 4,
            maxLines: 8,
            enabled: !isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    String? helperText,
    bool enabled = true,
    bool readOnly = false,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      enabled: enabled,
      readOnly: readOnly,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onTap: onTap,
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

    if (confirmed == true) {
      _clearSelectedCover();
      setState(() {});
    }
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
    ApiService apiService = ApiService();
    final baseUrl = apiService.getBaseUrl();
    final username = apiService.getUsername();
    final password = apiService.getPassword();

    final authHeader =
        'Basic ${base64.encode(utf8.encode('$username:$password'))}';
    final coverUrl = '$baseUrl/opds/cover/$bookId';

    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      httpHeaders: {'Authorization': authHeader},
      placeholder:
          (context, url) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: CircularProgressIndicator()),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image),
          ),
    );
  }
}
