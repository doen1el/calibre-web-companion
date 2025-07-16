import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/discover_details/data/models/category_model.dart';

class CategoryFeed extends Equatable {
  final List<CategoryModel> categories;
  final String? nextPageUrl;

  const CategoryFeed({required this.categories, this.nextPageUrl});

  @override
  List<Object?> get props => [categories, nextPageUrl];
}
