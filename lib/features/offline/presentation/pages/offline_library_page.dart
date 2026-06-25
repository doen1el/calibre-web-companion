import 'dart:io';

import 'package:cosmos_epub/cosmos_epub.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/services/download_manager.dart';
import 'package:calibre_web_companion/features/book_details/data/repositories/book_details_repository.dart';
import 'package:calibre_web_companion/features/offline/data/models/offline_book_model.dart';
import 'package:calibre_web_companion/features/offline/data/repositories/offline_library_repository.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

class OfflineLibraryPage extends StatefulWidget {
  const OfflineLibraryPage({super.key});

  @override
  State<OfflineLibraryPage> createState() => _OfflineLibraryPageState();
}

class _OfflineLibraryPageState extends State<OfflineLibraryPage> {
  List<OfflineBookModel> _books = const [];
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final downloads = GetIt.instance<DownloadManager>().allDownloads;
    final repo = GetIt.instance<OfflineLibraryRepository>();

    final books =
        downloads.entries.map((entry) {
          final meta = repo.getBook(entry.key);
          if (meta != null && meta.filePath.isNotEmpty) return meta;
          return _fallbackModel(entry.key, entry.value);
        }).toList();

    books.sort((a, b) {
      if (b.savedAt != a.savedAt) return b.savedAt.compareTo(a.savedAt);
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    setState(() => _books = books);
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
      final bytes = await GetIt.instance<BookDetailsRepository>()
          .readLocalEpubBytes(book.filePath);
      if (!mounted) return;

      final looksLikeZip =
          bytes != null &&
          bytes.length >= 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4B;
      if (!looksLikeZip) {
        context.showSnackBar(
          localizations.errorOpeningBookInInternalReader,
          isError: true,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildCover(context, book)),
            Padding(
              padding: const EdgeInsets.all(8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, OfflineBookModel book) {
    final theme = Theme.of(context);
    final placeholder = Container(
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
