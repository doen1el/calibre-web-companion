import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_bloc.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_event.dart';
import 'package:calibre_web_companion/features/discover_details/bloc/discover_details_state.dart';
import 'package:calibre_web_companion/features/discover_details/data/datasources/discover_details_remote_datasource.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_details_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/repositories/discover_details_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements DiscoverDetailsRepository {
  final Map<String, DiscoverFeedModel> bookPages;
  final Map<String, CategoryFeed> categoryPages;
  final List<String> requestedPaths = [];

  _FakeRepository({this.bookPages = const {}, this.categoryPages = const {}});

  @override
  DiscoverDetailsRemoteDatasource get dataSource => throw UnimplementedError();

  @override
  Future<DiscoverFeedModel> loadBooksFromPath(String fullPath) async {
    requestedPaths.add(fullPath);
    final page = bookPages[fullPath];
    if (page == null) throw Exception('404 for $fullPath');
    return page;
  }

  @override
  Future<CategoryFeed> loadCategoriesFromPath(String fullPath) async {
    requestedPaths.add(fullPath);
    final page = categoryPages[fullPath];
    if (page == null) throw Exception('404 for $fullPath');
    return page;
  }

  @override
  Future<DiscoverFeedModel> loadBooks(
    DiscoverType type, {
    String? subPath,
  }) async => throw UnimplementedError();

  @override
  Future<CategoryFeed> loadCategories(
    CategoryType type, {
    String? subPath,
  }) async => categoryPages['first'] ?? const CategoryFeed(categories: []);
}

DiscoverDetailsModel book(String id) =>
    DiscoverDetailsModel(id: id, uuid: 'uuid-$id', title: id, authors: 'A');

Future<DiscoverDetailsState> loaded(DiscoverDetailsBloc bloc) =>
    bloc.stream.firstWhere((s) => s.status == DiscoverDetailsStatus.loaded);

Future<DiscoverDetailsState> settled(DiscoverDetailsBloc bloc) =>
    bloc.stream.firstWhere((s) => !s.isLoadingMore);

void main() {
  test('load more appends the next page and carries its next link', () async {
    final repository = _FakeRepository(
      bookPages: {
        '/opds/series/1': DiscoverFeedModel(
          books: [book('1'), book('2')],
          nextPageUrl: '/opds/series/1?offset=2',
        ),
        '/opds/series/1?offset=2': DiscoverFeedModel(
          books: [book('3')],
          nextPageUrl: '/opds/series/1?offset=4',
        ),
      },
    );
    final bloc = DiscoverDetailsBloc(repository: repository);

    bloc.add(const LoadBooksFromPath('/opds/series/1'));
    final first = await loaded(bloc);
    expect(first.bookFeed!.books, hasLength(2));
    expect(first.hasMoreBooks, isTrue);

    bloc.add(const LoadMoreDiscoverBooks());
    final second = await settled(bloc);

    expect(second.bookFeed!.books.map((b) => b.id), ['1', '2', '3']);
    expect(second.bookFeed!.nextPageUrl, '/opds/series/1?offset=4');
    expect(second.status, DiscoverDetailsStatus.loaded);

    await bloc.close();
  });

  test('load more drops books that are already in the feed', () async {
    final repository = _FakeRepository(
      bookPages: {
        '/opds/new': DiscoverFeedModel(
          books: [book('1'), book('2')],
          nextPageUrl: '/opds/new?offset=2',
        ),
        '/opds/new?offset=2': DiscoverFeedModel(books: [book('2'), book('3')]),
      },
    );
    final bloc = DiscoverDetailsBloc(repository: repository);

    bloc.add(const LoadBooksFromPath('/opds/new'));
    await loaded(bloc);

    bloc.add(const LoadMoreDiscoverBooks());
    final state = await settled(bloc);

    expect(state.bookFeed!.books.map((b) => b.id), ['1', '2', '3']);
    expect(state.hasMoreBooks, isFalse);

    await bloc.close();
  });

  test(
    'a next link pointing at the page just loaded ends pagination',
    () async {
      final repository = _FakeRepository(
        bookPages: {
          '/opds/new': DiscoverFeedModel(
            books: [book('1')],
            nextPageUrl: '/opds/new?offset=1',
          ),
          '/opds/new?offset=1': DiscoverFeedModel(
            books: [book('2')],
            nextPageUrl: '/opds/new?offset=1',
          ),
        },
      );
      final bloc = DiscoverDetailsBloc(repository: repository);

      bloc.add(const LoadBooksFromPath('/opds/new'));
      await loaded(bloc);

      bloc.add(const LoadMoreDiscoverBooks());
      final state = await settled(bloc);

      expect(state.bookFeed!.books, hasLength(2));
      expect(state.hasMoreBooks, isFalse);

      await bloc.close();
    },
  );

  test('load more without a next link does not hit the repository', () async {
    final repository = _FakeRepository(
      bookPages: {
        '/opds/new': DiscoverFeedModel(books: [book('1')]),
      },
    );
    final bloc = DiscoverDetailsBloc(repository: repository);

    bloc.add(const LoadBooksFromPath('/opds/new'));
    await loaded(bloc);

    bloc.add(const LoadMoreDiscoverBooks());
    await Future<void>.delayed(Duration.zero);

    expect(repository.requestedPaths, ['/opds/new']);

    await bloc.close();
  });

  test('a failing next page keeps the books already shown', () async {
    final repository = _FakeRepository(
      bookPages: {
        '/opds/new': DiscoverFeedModel(
          books: [book('1')],
          nextPageUrl: '/opds/new?offset=1',
        ),
      },
    );
    final bloc = DiscoverDetailsBloc(repository: repository);

    bloc.add(const LoadBooksFromPath('/opds/new'));
    await loaded(bloc);

    bloc.add(const LoadMoreDiscoverBooks());
    final state = await settled(bloc);

    expect(state.bookFeed!.books, hasLength(1));
    expect(state.status, DiscoverDetailsStatus.loaded);

    await bloc.close();
  });

  test('categories paginate the same way as books', () async {
    final repository = _FakeRepository(
      categoryPages: {
        'first': const CategoryFeed(
          categories: [CategoryModel(id: '/opds/series/1', title: 'A Series')],
          nextPageUrl: '/opds/series/letter/A?offset=1',
        ),
        '/opds/series/letter/A?offset=1': const CategoryFeed(
          categories: [CategoryModel(id: '/opds/series/2', title: 'B Series')],
        ),
      },
    );
    final bloc = DiscoverDetailsBloc(repository: repository);

    bloc.add(const LoadCategories(CategoryType.series, subPath: 'letter/A'));
    await loaded(bloc);

    bloc.add(const LoadMoreDiscoverCategories());
    final state = await settled(bloc);

    expect(state.categoryFeed!.categories.map((c) => c.title), [
      'A Series',
      'B Series',
    ]);
    expect(state.hasMoreCategories, isFalse);

    await bloc.close();
  });
}
