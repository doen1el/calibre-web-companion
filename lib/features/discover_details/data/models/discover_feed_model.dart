import 'package:calibre_web_companion/features/discover_details/data/models/discover_details_model.dart';
import 'package:equatable/equatable.dart';

class DiscoverFeedModel extends Equatable {
  final List<DiscoverDetailsModel> books;
  final String? nextPageUrl;

  const DiscoverFeedModel({required this.books, this.nextPageUrl});

  @override
  List<Object?> get props => [books, nextPageUrl];
}
