import 'dart:io';

import 'package:calibre_web_companion/core/services/download_manager.dart';
import 'package:calibre_web_companion/core/services/reader_cache_service.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/data/repositories/book_details_repository.dart';
import 'package:calibre_web_companion/features/offline/data/models/offline_book_model.dart';
import 'package:calibre_web_companion/features/offline/data/repositories/offline_library_repository.dart';
import 'package:calibre_web_companion/features/reader/data/internal_reader_formats.dart';
import 'package:calibre_web_companion/features/reader/presentation/page_reader_launcher.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:cosmos_epub/cosmos_epub.dart';
import 'package:docman/docman.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class OfflineLibraryPage extends StatefulWidget {
  const OfflineLibraryPage({super.key});

  @override
  State<OfflineLibraryPage> createState() => _OfflineLibraryPageState();
}

class _OfflineLibraryPageState extends State<OfflineLibraryPage> {
  List<OfflineBookModel> _books = const [];
  Set<String> _cachedOnly = const {};
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final downloads = GetIt.instance<DownloadManager>().allDownloads;
    final cached = await GetIt.instance<ReaderCacheService>().entries();
    final repo = GetIt.instance<OfflineLibraryRepository>();

    final books =
        downloads.entries.map((entry) {
          final meta = repo.getBook(entry.key);
          if (meta != null && meta.filePath.isNotEmpty) {
            return meta.copyWith(filePath: entry.value);
          }
          return _fallbackModel(entry.key, entry.value);
        }).toList();

    // Books only opened in the reader; a real download of the same book wins.
    final cachedOnly = <String>{};
    for (final entry in cached) {
      if (downloads.containsKey(entry.uuid) ||
          cachedOnly.contains(entry.uuid)) {
        continue;
      }
      cachedOnly.add(entry.uuid);
      final meta = repo.getBook(entry.uuid);
      books.add(
        meta != null
            ? meta.copyWith(filePath: entry.path, format: entry.format)
            : _fallbackModel(entry.uuid, entry.path),
      );
    }

    books.sort((a, b) {
      if (b.savedAt != a.savedAt) return b.savedAt.compareTo(a.savedAt);
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    if (!mounted) return;
    setState(() {
      _books = books;
      _cachedOnly = cachedOnly;
    });
  }

  OfflineBookModel _fallbackModel(String uuid, String path) {
    String name;
    try {
      name = Uri.decodeFull(path);
    } catch (_) {
      name = path;
    }
    name = name.split('/').last;
    final dot = name.lastIndexOf('.');
    final format = dot >= 0 ? name.substring(dot + 1).toLowerCase() : 'epub';
    var title = dot >= 0 ? name.substring(0, dot) : name;
    title = title.replaceAll('_', ' ').trim();
    return OfflineBookModel(
      uuid: uuid,
      id: 0,
      title: title.isEmpty ? uuid : title,
      authors: '',
      series: '',
      seriesIndex: 0,
      filePath: path,
      format: format,
      savedAt: 0,
    );
  }

  Future<void> _open(OfflineBookModel book) async {
    if (_opening) return;
    final localizations = AppLocalizations.of(context)!;
    setState(() => _opening = true);
    try {
      final format = book.format.toLowerCase();
      if (!InternalReaderFormats.isSupported(format)) {
        await _openExternally(book, alreadyOpening: true);
        return;
      }

      final bytes = await GetIt.instance<BookDetailsRepository>()
          .readLocalBookBytes(book.filePath, format: format);
      if (!mounted) return;

      if (bytes == null) {
        context.showSnackBar(
          localizations.errorOpeningBookInInternalReader,
          isError: true,
        );
        return;
      }

      if (InternalReaderFormats.isPageBased(format)) {
        await openPageReader(
          context,
          bytes: bytes,
          format: format,
          bookUuid: book.uuid,
          title: book.title,
        );
        return;
      }

      await CosmosEpub.openFileBook(
        context: context,
        bytes: bytes,
        bookId: book.uuid,
        accentColor: Theme.of(context).colorScheme.primary,
      );
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          '${localizations.errorOpeningBookInInternalReader} $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _openExternally(
    OfflineBookModel book, {
    bool alreadyOpening = false,
  }) async {
    if (_opening && !alreadyOpening) return;
    final localizations = AppLocalizations.of(context)!;
    setState(() => _opening = true);
    try {
      final opened = await GetIt.instance<BookDetailsRepository>()
          .openLocalFileExternally(book.filePath, format: book.format);
      if (!opened && mounted) {
        context.showSnackBar(localizations.errorOpeningBook, isError: true);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          '${localizations.errorOpeningBook} $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _remove(OfflineBookModel book) async {
    final localizations = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(localizations.removeFromDevice),
            content: Text(localizations.removeFromDeviceConfirm(book.title)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(localizations.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(localizations.remove),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      if (_cachedOnly.contains(book.uuid)) {
        await GetIt.instance<ReaderCacheService>().remove(book.uuid);
      } else {
        await _deleteFile(book.filePath);
        await GetIt.instance<DownloadManager>().unregisterDownload(book.uuid);
        await GetIt.instance<ReaderCacheService>().remove(book.uuid);
      }
      await GetIt.instance<OfflineLibraryRepository>().remove(book.uuid);
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          '${localizations.errorOpeningBook} $e',
          isError: true,
        );
      }
    }
    await _load();
  }

  Future<void> _deleteFile(String path) async {
    if (Platform.isAndroid &&
        (path.startsWith('content://') || path.startsWith('file://'))) {
      final doc = await DocumentFile.fromUri(path);
      if (doc != null && doc.exists) await doc.delete();
      return;
    }
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_books.isEmpty) {
      return _buildEmptyState(context, localizations);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) => _buildCard(context, _books[index]),
    );
  }

  Widget _buildCard(BuildContext context, OfflineBookModel book) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _opening ? null : () => _open(book),
        onLongPress: _opening ? null : () => _remove(book),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildCover(context, book)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (book.authors.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            book.authors,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    enabled: !_opening,
                    onSelected: (value) {
                      if (value == 'external') _openExternally(book);
                      if (value == 'remove') _remove(book);
                    },
                    itemBuilder:
                        (menuContext) => [
                          PopupMenuItem(
                            value: 'external',
                            child: ListTile(
                              leading: const Icon(Icons.open_in_new_rounded),
                              title: Text(
                                AppLocalizations.of(context)!.openInReader,
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: ListTile(
                              leading: const Icon(Icons.delete_outline_rounded),
                              title: Text(
                                AppLocalizations.of(context)!.removeFromDevice,
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, OfflineBookModel book) {
    final theme = Theme.of(context);
    final placeholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 40,
          color: theme.colorScheme.primary,
        ),
      ),
    );

    final coverPath = book.coverPath;
    if (coverPath == null ||
        coverPath.isEmpty ||
        !File(coverPath).existsSync()) {
      return placeholder;
    }
    return Image.file(
      File(coverPath),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => placeholder,
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: .5),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noDownloadsFound,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: .7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
