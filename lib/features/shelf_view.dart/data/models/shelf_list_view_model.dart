import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';

class ShelfListViewModel extends Equatable {
  final List<ShelfViewModel> shelves;

  const ShelfListViewModel({required this.shelves});

  factory ShelfListViewModel.fromFeedJson(Map<String, dynamic> json) {
    final List<ShelfViewModel> shelves = [];

    try {
      final feed = json['feed'];
      if (feed == null) return const ShelfListViewModel(shelves: []);

      final entryRaw = feed['entry'];

      if (entryRaw is List) {
        for (var shelf in entryRaw) {
          shelves.add(ShelfViewModel.fromJson(shelf));
        }
      } else if (entryRaw is Map) {
        shelves.add(
          ShelfViewModel.fromJson(Map<String, dynamic>.from(entryRaw)),
        );
      }

      return ShelfListViewModel(shelves: shelves);
    } catch (e) {
      return const ShelfListViewModel(shelves: []);
    }
  }

  @override
  List<Object?> get props => [shelves];
}
