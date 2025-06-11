import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/discover_details/data/models/category_feed_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_feed_model.dart';

enum DiscoverDetailsStatus { initial, loading, loaded, error }

class DiscoverDetailsState extends Equatable {
  final DiscoverDetailsStatus status;
  final DiscoverFeedModel? bookFeed;
  final CategoryFeed? categoryFeed;
  final String? errorMessage;
  final bool isShowingBooks;
  final bool isShowingCategories;

  const DiscoverDetailsState({
    this.status = DiscoverDetailsStatus.initial,
    this.bookFeed,
    this.categoryFeed,
    this.errorMessage,
    this.isShowingBooks = false,
    this.isShowingCategories = false,
  });

  DiscoverDetailsState copyWith({
    DiscoverDetailsStatus? status,
    DiscoverFeedModel? bookFeed,
    CategoryFeed? categoryFeed,
    String? errorMessage,
    bool? isShowingBooks,
    bool? isShowingCategories,
  }) {
    return DiscoverDetailsState(
      status: status ?? this.status,
      bookFeed: bookFeed ?? this.bookFeed,
      categoryFeed: categoryFeed ?? this.categoryFeed,
      errorMessage: errorMessage,
      isShowingBooks: isShowingBooks ?? this.isShowingBooks,
      isShowingCategories: isShowingCategories ?? this.isShowingCategories,
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
  ];
}
