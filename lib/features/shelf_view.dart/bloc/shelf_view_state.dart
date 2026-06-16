import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/models/magic_shelf_model.dart';

enum ShelfViewStatus { initial, loading, loaded, error }

enum CreateShelfStatus { initial, loading, success, error }

enum CheckBookInShelfStatus { initial, loading, success, error }

enum MagicShelfActionStatus { initial, loading, success, error }

class ShelfViewState extends Equatable {
  final ShelfViewStatus status;
  final CreateShelfStatus createShelfStatus;
  final List<ShelfViewModel> shelves;
  final String? errorMessage;
  final List<ShelfViewModel> bookInShelves;
  final CheckBookInShelfStatus checkBookInShelfStatus;
  final bool isOpds;
  final bool supportsMagicShelves;
  final List<MagicShelfModel> magicShelves;
  final MagicShelfActionStatus magicActionStatus;
  final String? magicActionMessage;

  const ShelfViewState({
    this.status = ShelfViewStatus.initial,
    this.createShelfStatus = CreateShelfStatus.initial,
    this.shelves = const [],
    this.errorMessage,
    this.bookInShelves = const [],
    this.checkBookInShelfStatus = CheckBookInShelfStatus.initial,
    this.isOpds = false, // NEU
    this.supportsMagicShelves = false,
    this.magicShelves = const [],
    this.magicActionStatus = MagicShelfActionStatus.initial,
    this.magicActionMessage,
  });

  ShelfViewState copyWith({
    ShelfViewStatus? status,
    CreateShelfStatus? createShelfStatus,
    List<ShelfViewModel>? shelves,
    String? errorMessage,
    String? actionMessage,
    List<ShelfViewModel>? bookInShelves,
    CheckBookInShelfStatus? checkBookInShelfStatus,
    bool? isOpds, // NEU
    bool? supportsMagicShelves,
    List<MagicShelfModel>? magicShelves,
    MagicShelfActionStatus? magicActionStatus,
    String? magicActionMessage,
  }) {
    return ShelfViewState(
      status: status ?? this.status,
      createShelfStatus: createShelfStatus ?? this.createShelfStatus,
      shelves: shelves ?? this.shelves,
      errorMessage: errorMessage,
      bookInShelves: bookInShelves ?? this.bookInShelves,
      checkBookInShelfStatus:
          checkBookInShelfStatus ?? this.checkBookInShelfStatus,
      isOpds: isOpds ?? this.isOpds,
      supportsMagicShelves: supportsMagicShelves ?? this.supportsMagicShelves,
      magicShelves: magicShelves ?? this.magicShelves,
      magicActionStatus: magicActionStatus ?? this.magicActionStatus,
      magicActionMessage: magicActionMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    shelves,
    errorMessage,
    createShelfStatus,
    bookInShelves,
    checkBookInShelfStatus,
    isOpds,
    supportsMagicShelves,
    magicShelves,
    magicActionStatus,
    magicActionMessage,
  ];
}
