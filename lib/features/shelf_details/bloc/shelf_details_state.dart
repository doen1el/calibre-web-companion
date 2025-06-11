import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';

enum ShelfDetailsStatus { initial, loading, loaded, error }

enum ShelfDetailsActionStatus { initial, loading, success, error }

class ShelfDetailsState extends Equatable {
  final ShelfDetailsStatus status;
  final ShelfDetailsModel? currentShelfDetail;
  final String? errorMessage;
  final ShelfDetailsActionStatus actionDetailsStatus;
  final String? actionMessage;

  const ShelfDetailsState({
    this.status = ShelfDetailsStatus.initial,
    this.currentShelfDetail,
    this.errorMessage,
    this.actionDetailsStatus = ShelfDetailsActionStatus.initial,
    this.actionMessage,
  });

  ShelfDetailsState copyWith({
    ShelfDetailsStatus? status,
    ShelfDetailsModel? currentShelfDetail,
    String? errorMessage,
    ShelfDetailsActionStatus? actionDetailsStatus,
    String? actionMessage,
  }) {
    return ShelfDetailsState(
      status: status ?? this.status,
      currentShelfDetail: currentShelfDetail ?? this.currentShelfDetail,
      errorMessage: errorMessage,
      actionDetailsStatus: actionDetailsStatus ?? this.actionDetailsStatus,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentShelfDetail,
    errorMessage,
    actionDetailsStatus,
    actionMessage,
  ];
}
