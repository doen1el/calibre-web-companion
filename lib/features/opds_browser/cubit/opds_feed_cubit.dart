import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/opds_browser/data/datasources/opds_browser_datasource.dart';
import 'package:calibre_web_companion/features/opds_browser/data/models/opds_feed.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

enum OpdsFeedStatus { loading, loaded, error }

class OpdsFeedState extends Equatable {
  final OpdsFeedStatus status;
  final String title;
  final List<OpdsNavigationEntry> navigation;
  final List<BookViewModel> books;
  final String? nextUrl;
  final bool isLoadingMore;
  final String? errorMessage;
  final OpdsFeed? feed;

  const OpdsFeedState({
    this.status = OpdsFeedStatus.loading,
    this.title = '',
    this.navigation = const [],
    this.books = const [],
    this.nextUrl,
    this.isLoadingMore = false,
    this.errorMessage,
    this.feed,
  });

  bool get hasMore => nextUrl != null;

  @override
  List<Object?> get props => [
    status,
    title,
    navigation,
    books,
    nextUrl,
    isLoadingMore,
    errorMessage,
    feed?.url,
  ];
}

class OpdsFeedCubit extends Cubit<OpdsFeedState> {
  final OpdsBrowserDatasource datasource;
  final String url;
  final Logger logger;

  /// Search source handed down from the page this one was opened from, for
  /// feeds (like search results) that don't advertise a search themselves.
  final OpdsFeed? searchFeed;

  OpdsFeedCubit({
    required this.datasource,
    required this.url,
    required this.logger,
    this.searchFeed,
  }) : super(const OpdsFeedState());

  OpdsFeed? get searchSource =>
      state.feed?.searchHref != null ? state.feed : searchFeed;

  Future<void> load() async {
    emit(const OpdsFeedState());
    try {
      final feed = await datasource.fetchFeed(url);
      emit(
        OpdsFeedState(
          status: OpdsFeedStatus.loaded,
          title: feed.title,
          navigation: feed.navigation,
          books: feed.books,
          nextUrl: feed.nextUrl,
          feed: feed,
        ),
      );
    } catch (e) {
      logger.e('Error loading OPDS feed $url: $e');
      emit(OpdsFeedState(status: OpdsFeedStatus.error, errorMessage: '$e'));
    }
  }

  Future<void> loadMore() async {
    final next = state.nextUrl;
    if (next == null || state.isLoadingMore) return;

    emit(_copy(isLoadingMore: true));
    try {
      final page = await datasource.fetchFeed(next);
      // Some servers repeat entries across pages.
      final seen = state.books.map((b) => b.uuid).toSet();
      emit(
        _copy(
          books: [
            ...state.books,
            ...page.books.where((b) => b.uuid.isEmpty || seen.add(b.uuid)),
          ],
          navigation: [...state.navigation, ...page.navigation],
          nextUrl: page.nextUrl,
          clearNext: page.nextUrl == null || page.nextUrl == next,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      logger.e('Error loading next OPDS page $next: $e');
      emit(_copy(isLoadingMore: false, clearNext: true));
    }
  }

  Future<String?> buildSearchUrl(String query) async {
    final source = searchSource;
    if (source == null) return null;
    return datasource.buildSearchUrl(source, query);
  }

  Future<List<BookViewModel>> suggest(String query) async {
    final searchUrl = await buildSearchUrl(query);
    if (searchUrl == null) return const [];
    return (await datasource.fetchFeed(searchUrl)).books;
  }

  OpdsFeedState _copy({
    List<OpdsNavigationEntry>? navigation,
    List<BookViewModel>? books,
    String? nextUrl,
    bool clearNext = false,
    bool? isLoadingMore,
  }) {
    return OpdsFeedState(
      status: state.status,
      title: state.title,
      navigation: navigation ?? state.navigation,
      books: books ?? state.books,
      nextUrl: clearNext ? null : (nextUrl ?? state.nextUrl),
      isLoadingMore: isLoadingMore ?? state.isLoadingMore,
      errorMessage: state.errorMessage,
      feed: state.feed,
    );
  }
}
