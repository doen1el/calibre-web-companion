import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/services/app_transition.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/offline/cubit/connectivity_cubit.dart';
import 'package:calibre_web_companion/features/opds_browser/cubit/opds_feed_cubit.dart';
import 'package:calibre_web_companion/features/opds_browser/data/datasources/opds_browser_datasource.dart';
import 'package:calibre_web_companion/features/opds_browser/data/models/opds_feed.dart';
import 'package:calibre_web_companion/features/opds_browser/presentation/widgets/opds_search_dialog.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/book_card_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_list_tile_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_view_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

OpdsFeedCubit createOpdsFeedCubit({String? url, OpdsFeed? searchFeed}) {
  final datasource = OpdsBrowserDatasource(
    apiService: ApiService(),
    preferences: GetIt.instance<SharedPreferences>(),
  );
  return OpdsFeedCubit(
    datasource: datasource,
    url: url ?? datasource.rootUrl,
    logger: Logger(),
    searchFeed: searchFeed,
  );
}

/// Browses a generic OPDS catalog: navigation entries open sub-feeds, book
/// entries open the details page. Without [url] it shows the configured feed.
class OpdsFeedPage extends StatelessWidget {
  final String? url;
  final String? title;

  /// Set when this page shows search results; replaces the title with a
  /// search bar like the Calibre-Web book list has.
  final String? searchQuery;
  final OpdsFeed? searchFeed;

  const OpdsFeedPage({
    super.key,
    this.url,
    this.title,
    this.searchQuery,
    this.searchFeed,
  });

  bool get _isRoot => url == null;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider(
      create:
          (_) => createOpdsFeedCubit(url: url, searchFeed: searchFeed)..load(),
      child: BlocConsumer<OpdsFeedCubit, OpdsFeedState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (!_isRoot) return;
          if (state.status == OpdsFeedStatus.loaded) {
            context.read<ConnectivityCubit>().reportSuccess();
          } else if (state.status == OpdsFeedStatus.error) {
            context.read<ConnectivityCubit>().reportFailure();
          }
        },
        builder: (context, state) {
          final pageTitle =
              _isRoot
                  ? localizations.books
                  : (title?.isNotEmpty == true ? title! : state.title);
          final query = searchQuery;
          final canSearch = context.read<OpdsFeedCubit>().searchSource != null;
          return Scaffold(
            appBar: AppBar(
              titleSpacing: query != null ? 8 : null,
              title:
                  query != null
                      ? _buildActiveSearchBar(context, query, localizations)
                      : Text(pageTitle, overflow: TextOverflow.ellipsis),
              actions: [
                if (state.books.isNotEmpty) const BookViewModeSelector(),
                if (query == null && canSearch)
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    tooltip: localizations.search,
                    onPressed: () => showOpdsSearchDialog(context),
                  ),
              ],
            ),
            body: const OpdsFeedView(),
          );
        },
      ),
    );
  }

  Widget _buildActiveSearchBar(
    BuildContext context,
    String query,
    AppLocalizations localizations,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            () => showOpdsSearchDialog(
              context,
              initialQuery: query,
              replaceCurrent: true,
            ),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: scheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: scheme.onSecondaryContainer,
                tooltip: localizations.clearSearch,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The feed contents of the nearest [OpdsFeedCubit], with an optional
/// [header] scrolled above them.
class OpdsFeedView extends StatefulWidget {
  final Widget? header;

  const OpdsFeedView({super.key, this.header});

  @override
  State<OpdsFeedView> createState() => _OpdsFeedViewState();
}

class _OpdsFeedViewState extends State<OpdsFeedView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      context.read<OpdsFeedCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final state = context.watch<OpdsFeedCubit>().state;
    final viewState = context.select(
      (BookViewBloc bloc) => (bloc.state.isListView, bloc.state.columnCount),
    );

    final Widget content;
    if (state.status == OpdsFeedStatus.loading) {
      content = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state.status == OpdsFeedStatus.error) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: _buildMessage(
          context,
          Icons.error_outline_rounded,
          localizations.errorLoadingData,
          showRetry: true,
        ),
      );
    } else if (state.navigation.isEmpty && state.books.isEmpty) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: _buildMessage(
          context,
          Icons.menu_book_outlined,
          localizations.noBooksFound,
        ),
      );
    } else {
      content = SliverMainAxisGroup(
        slivers: [
          SliverList.builder(
            itemCount: state.navigation.length,
            itemBuilder:
                (context, index) =>
                    _buildNavigationTile(context, state.navigation[index]),
          ),
          if (state.navigation.isNotEmpty && state.books.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (viewState.$1)
            SliverList.builder(
              itemCount: state.books.length,
              itemBuilder:
                  (context, index) => BookListTile(
                    book: state.books[index],
                    onTap: () => _openBook(context, state.books[index]),
                  ),
            )
          else
            SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: viewState.$2,
                childAspectRatio: viewState.$2 <= 2 ? 0.7 : 0.9,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: state.books.length,
              itemBuilder: (context, index) {
                final book = state.books[index];
                return BookCard(
                  bookId: book.id.toString(),
                  title: book.title,
                  authors: book.authors,
                  coverUrl: book.coverUrl,
                  topLeftBadge: book.seriesBadge,
                  onTap: () => _openBook(context, book),
                );
              },
            ),
          if (state.hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<OpdsFeedCubit>().load(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          SliverPadding(padding: const EdgeInsets.all(16.0), sliver: content),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(BuildContext context, OpdsNavigationEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        // Same height with or without a subtitle.
        minTileHeight: 72,
        leading: Icon(Icons.folder_rounded, color: colorScheme.primary),
        title: Text(entry.title),
        subtitle:
            entry.subtitle.isNotEmpty && entry.subtitle != entry.title
                ? Text(
                  entry.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                : null,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap:
            () => Navigator.of(context).push(
              AppTransitions.createSlideRoute(
                OpdsFeedPage(url: entry.url, title: entry.title),
              ),
            ),
      ),
    );
  }

  void _openBook(BuildContext context, BookViewModel book) {
    Navigator.of(context).push(
      AppTransitions.createSlideRoute(
        BookDetailsPage(bookViewModel: book, bookUuid: book.uuid),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context,
    IconData icon,
    String text, {
    bool showRetry = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          text,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (showRetry) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppLocalizations.of(context)!.retry),
            onPressed: () => context.read<OpdsFeedCubit>().load(),
          ),
        ],
      ],
    );
  }
}

Future<void> showOpdsSearchDialog(
  BuildContext context, {
  String? initialQuery,
  bool replaceCurrent = false,
}) async {
  final cubit = context.read<OpdsFeedCubit>();
  final result = await showDialog<Object>(
    context: context,
    builder:
        (_) => OpdsSearchDialog(
          initialQuery: initialQuery,
          suggest: cubit.suggest,
        ),
  );
  if (result == null || !context.mounted) return;

  final navigator = Navigator.of(context);
  if (result is BookViewModel) {
    await navigator.push(
      AppTransitions.createSlideRoute(
        BookDetailsPage(bookViewModel: result, bookUuid: result.uuid),
      ),
    );
    return;
  }

  final query = result as String;
  final searchUrl = await cubit.buildSearchUrl(query);
  if (searchUrl == null || !context.mounted) return;

  final route = AppTransitions.createSlideRoute(
    OpdsFeedPage(
      url: searchUrl,
      searchQuery: query,
      searchFeed: cubit.searchSource,
    ),
  );
  if (replaceCurrent) {
    await navigator.pushReplacement(route);
  } else {
    await navigator.push(route);
  }
}
