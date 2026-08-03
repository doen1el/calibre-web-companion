import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/bnf_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/google_books_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/hardcover_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/isbn_metadata_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/isbndb_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/providers/open_library_provider.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_metadata_source.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_source_settings.dart';
import 'package:calibre_web_companion/features/scan_book/data/models/isbn_utils.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class IsbnRemoteDataSource {
  final http.Client client;
  final Logger logger;
  final List<IsbnMetadataProvider>? providerOverride;

  IsbnRemoteDataSource({
    http.Client? client,
    Logger? logger,
    this.providerOverride,
  }) : client = client ?? http.Client(),
       logger = logger ?? Logger();

  Future<IsbnBook?> lookupByIsbn(String isbn) async {
    final normalized = normalizeIsbn(isbn);
    if (!isValidIsbnLength(normalized)) {
      logger.w('Invalid ISBN length: $normalized');
      return null;
    }

    var providers = providerOverride ?? await _buildProviders();
    if (providers.isEmpty) {
      logger.w('No ISBN metadata source enabled — falling back to OpenLibrary');
      providers = [OpenLibraryProvider(client: client, logger: logger)];
    }

    logger.i(
      'Looking up $normalized via '
      '${providers.map((p) => p.source.label).join(', ')}',
    );

    final results = await Future.wait(
      providers.map((provider) => _lookupSafely(provider, normalized)),
    );

    final failures = results.where((r) => r.error != null).length;
    if (failures == results.length) {
      throw Exception('ISBN lookup failed: ${results.first.error}');
    }

    final books = results.map((r) => r.book).whereType<IsbnBook>().toList();

    IsbnBook? merged;
    for (final book in [
      ...books.where((b) => !b.approximate),
      ...books.where((b) => b.approximate),
    ]) {
      merged = merged == null ? book : merged.mergeWith(book);
    }

    if (merged == null) {
      logger.i('No catalogue knows ISBN $normalized');
      return null;
    }

    if (merged.coverUrl == null || merged.coverUrl!.isEmpty) {
      merged = merged.copyWith(coverUrl: await _openLibraryCover(normalized));
    }

    logger.i(
      'Resolved $normalized from '
      '${merged.sources.map((s) => s.label).join(' + ')}',
    );
    return merged;
  }

  Future<_ProviderResult> _lookupSafely(
    IsbnMetadataProvider provider,
    String isbn,
  ) async {
    try {
      final book = await provider.lookup(isbn);
      if (book == null) {
        logger.d('${provider.source.label}: no match for $isbn');
      }
      return _ProviderResult(book: book);
    } catch (e) {
      logger.w('${provider.source.label} lookup failed: $e');
      return _ProviderResult(error: e);
    }
  }

  Future<List<IsbnMetadataProvider>> _buildProviders() async {
    final settings = await IsbnSourceSettings.load();
    return settings.activeSources
        .map(
          (source) => switch (source) {
            IsbnMetadataSource.openLibrary => OpenLibraryProvider(
              client: client,
              logger: logger,
            ),
            IsbnMetadataSource.googleBooks => GoogleBooksProvider(
              apiKey: settings.credentialFor(source),
              client: client,
              logger: logger,
            ),
            IsbnMetadataSource.bnf => BnfProvider(
              client: client,
              logger: logger,
            ),
            IsbnMetadataSource.hardcover => HardcoverProvider(
              token: settings.credentialFor(source),
              client: client,
              logger: logger,
            ),
            IsbnMetadataSource.isbnDb => IsbnDbProvider(
              apiKey: settings.credentialFor(source),
              client: client,
              logger: logger,
            ),
          },
        )
        .toList();
  }

  Future<String?> _openLibraryCover(String isbn) async {
    final url = 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';
    try {
      final response = await client
          .head(Uri.parse('$url?default=false'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) return url;
    } catch (e) {
      logger.d('Cover probe failed for $isbn: $e');
    }
    return null;
  }
}

class _ProviderResult {
  final IsbnBook? book;
  final Object? error;

  const _ProviderResult({this.book, this.error});
}
