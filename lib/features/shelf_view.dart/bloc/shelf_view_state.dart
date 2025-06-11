import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/shelf_view.dart/data/models/shelf_view_model.dart';

enum ShelfViewStatus { initial, loading, loaded, error }

enum CreateShelfStatus { initial, loading, success, error }

class ShelfViewState extends Equatable {
  final ShelfViewStatus status;
  final CreateShelfStatus createShelfStatus;
  final List<ShelfViewModel> shelves;
  final String? errorMessage;

  const ShelfViewState({
    this.status = ShelfViewStatus.initial,
    this.createShelfStatus = CreateShelfStatus.initial,
    this.shelves = const [],
    this.errorMessage,
  });

  ShelfViewState copyWith({
    ShelfViewStatus? status,
    CreateShelfStatus? createShelfStatus,
    List<ShelfViewModel>? shelves,
    String? errorMessage,
    String? actionMessage,
  }) {
    return ShelfViewState(
      status: status ?? this.status,
      createShelfStatus: createShelfStatus ?? this.createShelfStatus,
      shelves: shelves ?? this.shelves,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, shelves, errorMessage, createShelfStatus];
}
