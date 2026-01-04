import 'package:equatable/equatable.dart';

enum DiscoverType {
  bookmarked,
  unreadbooks,
  readbooks,
  hot,
  newlyAdded,
  rated,
  discover,
  surprise,
}

enum CategoryType {
  category,
  language,
  publisher,
  author,
  ratings,
  formats,
  series,
  libraries,
}

abstract class DiscoverEvent extends Equatable {
  const DiscoverEvent();

  @override
  List<Object?> get props => [];
}

class NavigateToBookList extends DiscoverEvent {
  final String title;
  final CategoryType? categoryType;
  final DiscoverType? discoverType;
  final String? fullPath;

  const NavigateToBookList({
    required this.title,
    this.categoryType,
    this.discoverType,
    this.fullPath,
  });

  @override
  List<Object?> get props => [title, categoryType, discoverType, fullPath];
}

class NavigateToRecommendations extends DiscoverEvent {
  const NavigateToRecommendations();
}

class CheckServerType extends DiscoverEvent {}
