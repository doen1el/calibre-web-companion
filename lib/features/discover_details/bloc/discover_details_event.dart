import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/category_model.dart';
import 'package:calibre_web_companion/features/discover_details/data/models/discover_details_model.dart';

abstract class DiscoverDetailsEvent extends Equatable {
  const DiscoverDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBooks extends DiscoverDetailsEvent {
  final DiscoverType type;
  final String? subPath;

  const LoadBooks(this.type, {this.subPath});

  @override
  List<Object?> get props => [type, subPath];
}

class LoadCategories extends DiscoverDetailsEvent {
  final CategoryType type;
  final String? subPath;

  const LoadCategories(this.type, {this.subPath});

  @override
  List<Object?> get props => [type, subPath];
}

class LoadBooksFromPath extends DiscoverDetailsEvent {
  final String fullPath;

  const LoadBooksFromPath(this.fullPath);

  @override
  List<Object?> get props => [fullPath];
}

class NavigateToBook extends DiscoverDetailsEvent {
  final DiscoverDetailsModel book;

  const NavigateToBook(this.book);

  @override
  List<Object?> get props => [book];
}

class NavigateToCategory extends DiscoverDetailsEvent {
  final CategoryModel category;
  final CategoryType? currentCategoryType;

  const NavigateToCategory(this.category, {this.currentCategoryType});

  @override
  List<Object?> get props => [category, currentCategoryType];
}
