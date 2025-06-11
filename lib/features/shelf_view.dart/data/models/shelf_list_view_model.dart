import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';

class ShelfListViewModel extends Equatable {
  final List<ShelfViewModel> shelves;

  const ShelfListViewModel({required this.shelves});

  factory ShelfListViewModel.fromFeedJson(Map<String, dynamic> json) {
    final List<ShelfViewModel> shelves = [];

    try {
      for (var shelf in json['feed']['entry']) {
        shelves.add(ShelfViewModel.fromJson(shelf));
      }

      return ShelfListViewModel(shelves: shelves);
    } catch (e) {
      return const ShelfListViewModel(shelves: []);
    }
  }

  @override
  List<Object?> get props => [shelves];
}
