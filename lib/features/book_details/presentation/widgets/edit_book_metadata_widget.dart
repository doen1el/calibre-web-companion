import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';
import 'package:calibre_web_companion/features/book_details/data/models/metadata_models.dart';
import 'package:calibre_web_companion/features/book_details/presentation/widgets/metadata_search_dialog.dart';

import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/shared/widgets/coming_soon_widget.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/image_cache_manager.dart';

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

  String? _newCoverUrl;

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
        listener: (context, state) async {
          if (state.metadataUpdateState == MetadataUpdateState.success) {
            final apiService = ApiService();
            final baseUrl = apiService.getBaseUrl();
            final coverUrl = '$baseUrl/opds/cover/${widget.book.id}';

            imageCache.clear();
            imageCache.clearLiveImages();

            await CachedNetworkImage.evictFromCache(coverUrl);

            try {
              await CustomCacheManager().removeFile(coverUrl);
            } catch (e) {
              debugPrint('Custom cache clear error: $e');
            }

            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
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
            title: Row(
              children: [
                Text(localizations.editBookMetadata),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.cloud_download),
                  tooltip: "Fetch Metadata",
                  // TODO: Fix metadata fetch feature
                  // onPressed: isLoading ? null : _openMetadataSearch,
                  onPressed:
                      () => showComingSoonDialog(
                        context,
                        "The metadata search feature is coming soon!",
                      ),
                ),
              ],
            ),
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
                              coverUrl: _newCoverUrl,
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

  Future<void> _openMetadataSearch() async {
    final resultData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => MetadataSearchDialog(
            initialQuery: "${_titleController.text} ${_authorsController.text}",
          ),
    );

    if (resultData != null) {
      final result = resultData['result'] as MetadataSearchResult;
      final selection = resultData['selection'] as Map<String, bool>;

      setState(() {
        if (selection['title'] == true && result.title.isNotEmpty) {
          _titleController.text = result.title;
        }
        if (selection['authors'] == true && result.authors.isNotEmpty) {
          _authorsController.text = result.authors;
        }
        if (selection['publisher'] == true && result.publisher.isNotEmpty) {
          _publisherController.text = result.publisher;
        }
        if (selection['pubdate'] == true && result.pubdate.isNotEmpty) {
          _pubdateController.text = result.pubdate;
        }
        if (selection['description'] == true && result.description.isNotEmpty) {
          _commentsController.text = result.description;
        }
        if (selection['tags'] == true && result.tags.isNotEmpty) {
          _tagsController.text = result.tags.join(', ');
        }
        if (selection['series'] == true && result.series.isNotEmpty) {
          _seriesController.text = result.series;
          _seriesIndexController.text = result.seriesIndex;
        }
        if (selection['rating'] == true && result.rating > 0) {
          _currentRating = result.rating / 2;
        }
        if (selection['languages'] == true && result.languages.isNotEmpty) {
          _languagesController.text = result.languages.join(', ');
        }
        if (selection['cover'] == true && result.coverUrl.isNotEmpty) {
          _newCoverUrl = result.coverUrl;
          _selectedCoverBytes = null;
          _selectedCoverName = null;
        }
      });
    }
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
            child: SizedBox(
              width: 120,
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          _selectedCoverBytes != null
                              ? Image.memory(
                                _selectedCoverBytes!,
                                fit: BoxFit.cover,
                              )
                              : _newCoverUrl != null
                              ? CachedNetworkImage(
                                imageUrl: _newCoverUrl!,
                                fit: BoxFit.cover,
                                placeholder:
                                    (_, _) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                errorWidget:
                                    (_, _, _) => const Icon(Icons.broken_image),
                              )
                              : _buildCoverImage(
                                context,
                                widget.book.id,
                                localizations,
                              ),
                    ),
                  ),
                  Positioned(
                    bottom: -12,
                    right: -12,
                    child: IconButton.filled(
                      onPressed: isLoading ? null : _pickImage,
                      icon: const Icon(Icons.edit),
                      tooltip: localizations.newCover,
                    ),
                  ),
                ],
              ),
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
          const SizedBox(height: 16),

          InputDecorator(
            decoration: InputDecoration(
              labelText: localizations.rating,
              prefixIcon: const Icon(Icons.star),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: StarRating(
              starCount: 5,
              rating: _currentRating,
              allowHalfRating: true,
              color: Colors.amber,
              borderColor: Theme.of(context).colorScheme.outline,
              onRatingChanged:
                  (rating) => setState(() => _currentRating = rating),
            ),
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

        final cookieHeaders = apiService.getAuthHeaders(
          authMethod: AuthMethod.cookie,
        );
        if (cookieHeaders.containsKey('Cookie')) {
          headers['Cookie'] = cookieHeaders['Cookie']!;
        }

        final username = apiService.getUsername();
        final password = apiService.getPassword();
        if (username.isNotEmpty && password.isNotEmpty) {
          headers['Authorization'] =
              'Basic ${base64.encode(utf8.encode('$username:$password'))}';
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          final headersJson = prefs.getString('custom_login_headers') ?? '[]';
          final List<dynamic> decodedList = jsonDecode(headersJson);

          for (final dynamic item in decodedList) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              String? key = map['key']?.toString();
              String? value = map['value']?.toString();

              if (key == null && map.isNotEmpty) {
                key = map.keys.first;
                value = map.values.first;
              }

              if (key != null && value != null) {
                if (value.contains('\${USERNAME}') && username.isNotEmpty) {
                  value = value.replaceAll('\${USERNAME}', username);
                }
                headers[key] = value;
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }

        headers['Accept'] =
            'image/avif;q=0,image/webp;q=0,image/jpeg,image/png,*/*;q=0.5';
        headers['Cache-Control'] = 'no-transform';
        return headers;
      }(),
      builder: (context, snapshot) {
        final headers = snapshot.data ?? const <String, String>{};
        return CachedNetworkImage(
          imageUrl: coverUrl,
          fit: BoxFit.cover,
          httpHeaders: headers,
          placeholder:
              (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
          errorWidget:
              (context, url, error) => Image.network(
                coverUrl,
                headers: headers,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stack) => Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image),
                    ),
              ),
        );
      },
    );
  }
}
