import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/discover_details/data/models/category_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_feed_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

enum DiscoverDetailsStatus { initial, loading, loaded, error }

class DiscoverDetailsState extends Equatable {
  final DiscoverDetailsStatus status;
  final DiscoverFeedModel? bookFeed;
  final CategoryFeed? categoryFeed;
  final String? errorMessage;
  final bool isShowingBooks;
  final bool isShowingCategories;
  final BookViewModel? bookDetails;
  final String? loadingBookId;

  const DiscoverDetailsState({
    this.status = DiscoverDetailsStatus.initial,
    this.bookFeed,
    this.categoryFeed,
    this.errorMessage,
    this.isShowingBooks = false,
    this.isShowingCategories = false,
    this.bookDetails,
    this.loadingBookId,
  });

  DiscoverDetailsState copyWith({
    DiscoverDetailsStatus? status,
    DiscoverFeedModel? bookFeed,
    CategoryFeed? categoryFeed,
    String? errorMessage,
    bool? isShowingBooks,
    bool? isShowingCategories,
    BookViewModel? bookDetails,
    String? loadingBookId,
  }) {
    return DiscoverDetailsState(
      status: status ?? this.status,
      bookFeed: bookFeed ?? this.bookFeed,
      categoryFeed: categoryFeed ?? this.categoryFeed,
      errorMessage: errorMessage,
      isShowingBooks: isShowingBooks ?? this.isShowingBooks,
      isShowingCategories: isShowingCategories ?? this.isShowingCategories,
      bookDetails: bookDetails ?? this.bookDetails,
      loadingBookId: loadingBookId ?? this.loadingBookId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    bookFeed,
    categoryFeed,
    errorMessage,
    isShowingBooks,
    isShowingCategories,
    bookDetails,
    loadingBookId,
  ];
}
