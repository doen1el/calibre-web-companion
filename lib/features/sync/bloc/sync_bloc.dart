import 'package:docman/docman.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:get_it/get_it.dart';

import 'package:calibre_web_companion/features/sync/bloc/sync_event.dart';
import 'package:calibre_web_companion/features/sync/bloc/sync_state.dart';
import 'package:calibre_web_companion/features/sync/data/models/sync_filter.dart';
import 'package:calibre_web_companion/features/book_view/data/repositories/book_view_repository.dart';
import 'package:calibre_web_companion/features/book_details/data/repositories/book_details_repository.dart';
import 'package:calibre_web_companion/core/services/download_manager.dart';
import 'package:calibre_web_companion/features/settings/data/repositories/settings_repository.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/shelf_details/data/repositories/shelf_details_repository.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final Logger logger;
  final BookViewRepository bookViewRepository;
  final BookDetailsRepository bookDetailsRepository;
  final DownloadManager downloadManager;
  final SettingsRepository settingsRepository;
  final ShelfDetailsRepository shelfDetailsRepository;

  bool _isProcessing = false;

  SyncBloc({
    required this.logger,
    required this.bookViewRepository,
    required this.bookDetailsRepository,
    required this.downloadManager,
    required this.settingsRepository,
    required this.shelfDetailsRepository,
  }) : super(const SyncState()) {
    on<CheckForUnsyncedBooks>(_onCheckForUnsyncedBooks);
    on<StartSync>(_onStartSync);
    on<ConfirmSyncFromPreview>(_onConfirmSyncFromPreview);
    on<PauseSync>(_onPauseSync);
    on<ResumeSync>(_onResumeSync);
    on<CancelSync>(_onCancelSync);
    on<ProcessNextSyncItem>(_onProcessNextSyncItem);
  }

  Future<void> _onCheckForUnsyncedBooks(
    CheckForUnsyncedBooks event,
    Emitter<SyncState> emit,
  ) async {}

  Future<void> _onStartSync(StartSync event, Emitter<SyncState> emit) async {
    final settings = await settingsRepository.getSettings();

    if (settings.defaultDownloadPath.isEmpty) {
      emit(
        state.copyWith(
          status: SyncStatus.error,
          errorMessage: "Please configure a download folder in Settings first.",
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SyncStatus.scanning,
        filter: event.filter,
        previewBooks: [],
        queue: [],
        syncedCount: 0,
        totalBooksToCheck: 0,
        errorMessage: null,
      ),
    );

    logger.i(
      'Starting Sync (DryRun: ${event.dryRun}) with filter: ${event.filter}',
    );

    try {
      final books = await _fetchAndFilterBooks(event.filter);

      if (books.isEmpty) {
        emit(
          state.copyWith(
            status: SyncStatus.idle,
            errorMessage: "No books found matching your filters.",
          ),
        );
        return;
      }

      if (event.dryRun) {
        emit(state.copyWith(status: SyncStatus.preview, previewBooks: books));
      } else {
        final queue = books.map((b) => SyncQueueItem(book: b)).toList();

        emit(
          state.copyWith(
            status: SyncStatus.syncing,
            queue: queue,
            totalBooksToCheck: books.length,
            syncedCount: 0,
            currentProgress: 0.0,
          ),
        );

        add(ProcessNextSyncItem());
      }
    } catch (e) {
      logger.e('Error during sync start: $e');
      emit(
        state.copyWith(status: SyncStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onConfirmSyncFromPreview(
    ConfirmSyncFromPreview event,
    Emitter<SyncState> emit,
  ) async {
    if (state.status != SyncStatus.preview || state.previewBooks.isEmpty) {
      return;
    }
    final queue =
        state.previewBooks.map((b) => SyncQueueItem(book: b)).toList();
    emit(
      state.copyWith(
        status: SyncStatus.syncing,
        queue: queue,
        syncedCount: 0,
        totalBooksToCheck: queue.length,
      ),
    );
    add(ProcessNextSyncItem());
  }

  Future<List<BookViewModel>> _fetchAndFilterBooks(SyncFilter filter) async {
    List<BookViewModel> sourceList = [];

    if (filter.shelfId != null && filter.shelfId!.isNotEmpty) {
      logger.d('Fetching books from Shelf ID: ${filter.shelfId}');
      try {
        final shelfDetails = await shelfDetailsRepository.getShelfDetails(
          filter.shelfId!,
        );

        final uuidToIdMap = await _fetchOpdsDownloadIds(filter.shelfId!);

        sourceList =
            shelfDetails.books.map((sb) {
              final idStr = sb.id.toString();
              int parsedId = 0;

              if (uuidToIdMap.containsKey(sb.uuid)) {
                parsedId = uuidToIdMap[sb.uuid]!;
              } else {
                final cleanId = idStr.replaceAll('urn:uuid:', '');
                if (uuidToIdMap.containsKey(cleanId)) {
                  parsedId = uuidToIdMap[cleanId]!;
                }
              }

              if (parsedId == 0) {
                parsedId = _tryParseFallbackId(idStr);
              }

              if (parsedId == 0) {
                logger.d(
                  'Could not resolve download ID for book "${sb.title}" (UUID: ${sb.uuid}). Download might fail.',
                );
              }

              return BookViewModel(
                id: parsedId,
                uuid: sb.uuid,
                title: sb.title,
                authors: sb.authors,
                coverUrl: sb.coverUrl,
                formats: sb.formats,
                tags: sb.tags,
              );
            }).toList();

        logger.d('Loaded ${sourceList.length} books from shelf.');
      } catch (e) {
        logger.e('Failed to load shelf: $e');
        throw Exception("Could not load shelf ${filter.shelfId}");
      }
    } else {
      logger.d('Fetching ALL books from Library (paginated)...');
      sourceList = await _fetchAllBooks();
      logger.d('Loaded total of ${sourceList.length} books from library.');
    }

    logger.i('Applying filters to ${sourceList.length} items.');

    return _applyLocalFilters(sourceList, filter);
  }

  Future<Map<String, int>> _fetchOpdsDownloadIds(String shelfId) async {
    final Map<String, int> map = {};
    try {
      final apiService = GetIt.I<ApiService>();
      final response = await apiService.get(endpoint: "/opds/shelf/$shelfId");

      final entries = response.body.split('<entry>');
      for (var entry in entries) {
        if (!entry.contains('</entry>')) continue;

        final uuidMatch = RegExp(
          r'<id>urn:uuid:([a-fA-F0-9-]+)</id>',
        ).firstMatch(entry);
        final idMatch = RegExp(
          r'href="\/opds\/download\/(\d+)\/',
        ).firstMatch(entry);

        if (uuidMatch != null && idMatch != null) {
          map[uuidMatch.group(1)!] = int.parse(idMatch.group(1)!);
        }
      }
      logger.d("Resolved ${map.length} IDs from OPDS feed.");
    } catch (e) {
      logger.w("Failed to resolve IDs from OPDS feed: $e");
    }
    return map;
  }

  int _tryParseFallbackId(String idStr) {
    if (idStr.contains('-')) return 0;

    if (int.tryParse(idStr) != null) return int.parse(idStr);

    final bookMatch = RegExp(r'book:(\d+)').firstMatch(idStr);
    if (bookMatch != null) return int.parse(bookMatch.group(1)!);

    final opdsMatch = RegExp(r'\/download\/(\d+)\/').firstMatch(idStr);
    if (opdsMatch != null) return int.parse(opdsMatch.group(1)!);

    return 0;
  }

  List<BookViewModel> _applyLocalFilters(
    List<BookViewModel> books,
    SyncFilter filter,
  ) {
    int skippedByStatus = 0;
    int skippedByDownload = 0;
    int skippedByCriteria = 0;

    final filtered =
        books.where((book) {
          if (filter.unreadOnly && book.readStatus) {
            skippedByStatus++;
            return false;
          }

          if (filter.authors.isNotEmpty) {
            bool match = false;
            for (final auth in filter.authors) {
              if (book.authors.toLowerCase().contains(auth.toLowerCase())) {
                match = true;
                break;
              }
            }
            if (!match) {
              skippedByCriteria++;
              return false;
            }
          }

          if (filter.series.isNotEmpty) {
            if (!filter.series.contains(book.series)) {
              skippedByCriteria++;
              return false;
            }
          }

          if (filter.tags.isNotEmpty) {
            final hasTag = book.tags.any((t) => filter.tags.contains(t));
            if (!hasTag) {
              skippedByCriteria++;
              return false;
            }
          }

          if (filter.publishers.isNotEmpty) {
            final hasPub = filter.publishers.any(
              (fp) => book.publishers.toLowerCase().contains(fp.toLowerCase()),
            );
            if (!hasPub) {
              skippedByCriteria++;
              return false;
            }
          }

          if (filter.languages.isNotEmpty) {
            final hasLang = filter.languages.any(
              (l) => book.languages.toLowerCase().contains(l.toLowerCase()),
            );
            if (!hasLang) {
              skippedByCriteria++;
              return false;
            }
          }

          final isDownloaded = downloadManager.isBookDownloaded(book.uuid);
          if (isDownloaded) {
            skippedByDownload++;
            return false;
          }

          return true;
        }).toList();

    logger.i(
      'Filter Result: ${books.length} -> ${filtered.length} (Skipped: Read=$skippedByStatus, Criteria=$skippedByCriteria, Downloaded=$skippedByDownload)',
    );

    return filtered;
  }

  Future<List<BookViewModel>> _fetchAllBooks() async {
    List<BookViewModel> allBooks = [];
    int offset = 0;
    const limit = 50;
    bool hasMore = true;
    int safetyCounter = 0;

    while (hasMore) {
      if (safetyCounter > 500) {
        logger.w('Emergency Break: Fetch loop exceeded 500 iterations.');
        break;
      }
      safetyCounter++;

      logger.d('Fetching books offset $offset, limit $limit...');

      try {
        final chunk = await bookViewRepository.fetchBooks(
          offset: offset,
          limit: limit,
          sortBy: 'timestamp',
          sortOrder: 'desc',
        );

        if (chunk.isEmpty) {
          logger.d('Chunk is empty, stop fetching.');
          hasMore = false;
        } else {
          allBooks.addAll(chunk);
          offset += chunk.length;

          logger.d(
            'Fetched ${chunk.length} books. Total so far: ${allBooks.length}',
          );

          if (chunk.length < limit) {
            hasMore = false;
            logger.d('Received less than limit, end of library reached.');
          }
        }
      } catch (e) {
        logger.e('Error fetching book chunk at offset $offset: $e');

        throw Exception("Sync failed during library scan: $e");
      }
    }
    return allBooks;
  }

  Future<void> _onPauseSync(PauseSync event, Emitter<SyncState> emit) async {
    emit(state.copyWith(status: SyncStatus.paused));
  }

  Future<void> _onResumeSync(ResumeSync event, Emitter<SyncState> emit) async {
    if (state.status == SyncStatus.paused) {
      emit(state.copyWith(status: SyncStatus.syncing));
      add(ProcessNextSyncItem());
    }
  }

  Future<void> _onCancelSync(CancelSync event, Emitter<SyncState> emit) async {
    emit(state.copyWith(status: SyncStatus.canceled, queue: []));
  }

  Future<void> _onProcessNextSyncItem(
    ProcessNextSyncItem event,
    Emitter<SyncState> emit,
  ) async {
    if (state.status != SyncStatus.syncing || _isProcessing) return;

    final index = state.queue.indexWhere((item) => item.status == 'pending');
    if (index == -1) {
      emit(
        state.copyWith(status: SyncStatus.completed, currentBookTitle: null),
      );
      return;
    }

    _isProcessing = true;
    final item = state.queue[index];

    List<SyncQueueItem> newQueue = List.from(state.queue);
    newQueue[index] = item.copyWith(status: 'downloading');
    emit(
      state.copyWith(
        queue: newQueue,
        currentBookTitle: item.book.title,
        currentProgress: 0.0,
      ),
    );

    try {
      final settings = await settingsRepository.getSettings();
      DocumentFile? dir;
      try {
        if (settings.defaultDownloadPath.isNotEmpty) {
          dir = await DocumentFile.fromUri(settings.defaultDownloadPath);
        }
      } catch (e) {
        logger.e('Error accessing download directory: $e');
      }

      if (dir == null) throw Exception("Invalid download directory");

      var bookDetails = await bookDetailsRepository.getBookDetails(
        item.book,
        item.book.uuid,
      );

      if (bookDetails.id == 0 && item.book.id != 0) {
        logger.i(
          "API returned ID 0, restoring ID ${item.book.id} parsed from OPDS link.",
        );
        bookDetails = bookDetails.copyWith(id: item.book.id);
      }

      if (bookDetails.id == 0) {
        throw Exception(
          "Fatal: Server returned ID 0 for book '${item.book.title}' (UUID: ${item.book.uuid}). Cannot construct download URL.",
        );
      }

      String? formatToDownload;

      if (state.filter.selectedFormats.isNotEmpty) {
        for (var f in state.filter.selectedFormats) {
          if (bookDetails.formats.any(
            (bf) => bf.toLowerCase().contains(f.toLowerCase()),
          )) {
            formatToDownload = f;
            break;
          }
        }

        if (formatToDownload == null) {
          logger.i(
            'Skipping "${bookDetails.title}" - Formats ${bookDetails.formats} do not match ${state.filter.selectedFormats}',
          );

          throw Exception("Skipped: No matching format found.");
        }
      } else {
        if (bookDetails.formats.contains('EPUB')) {
          formatToDownload = 'epub';
        } else if (bookDetails.formats.isNotEmpty) {
          formatToDownload = bookDetails.formats.first;
        } else {
          throw Exception("Skipped: No formats available.");
        }
      }

      final path = await bookDetailsRepository.downloadBook(
        bookDetails,
        dir,
        settings.downloadSchema,
        format: formatToDownload,
        progressCallback: (bytes) {},
      );

      await downloadManager.registerDownload(item.book.uuid, path);

      newQueue = List.from(state.queue);
      newQueue[index] = item.copyWith(status: 'done');
      emit(
        state.copyWith(
          queue: newQueue,
          syncedCount: state.syncedCount + 1,
          currentProgress: 1.0,
        ),
      );
    } catch (e) {
      final msg = e.toString();
      final isSkip = msg.contains("Skipped:");

      if (isSkip) {
        logger.d(msg);
      } else {
        logger.e("Sync error for ${item.book.title}: $e");
      }

      newQueue = List.from(state.queue);

      newQueue[index] = item.copyWith(status: 'error');
      emit(state.copyWith(queue: newQueue));
    } finally {
      _isProcessing = false;
      add(ProcessNextSyncItem());
    }
  }
}
