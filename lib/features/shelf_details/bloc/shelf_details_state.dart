import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
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
  final BookViewModel? bookDetails;
  final String? loadingBookId;

  const ShelfDetailsState({
    this.status = ShelfDetailsStatus.initial,
    this.currentShelfDetail,
    this.errorMessage,
    this.actionDetailsStatus = ShelfDetailsActionStatus.initial,
    this.actionMessage,
    this.bookDetails,
    this.loadingBookId,
  });

  ShelfDetailsState copyWith({
    ShelfDetailsStatus? status,
    ShelfDetailsModel? currentShelfDetail,
    String? errorMessage,
    ShelfDetailsActionStatus? actionDetailsStatus,
    String? actionMessage,
    BookViewModel? bookDetails,
    String? loadingBookId,
  }) {
    return ShelfDetailsState(
      status: status ?? this.status,
      currentShelfDetail: currentShelfDetail ?? this.currentShelfDetail,
      errorMessage: errorMessage,
      actionDetailsStatus: actionDetailsStatus ?? this.actionDetailsStatus,
      actionMessage: actionMessage,
      bookDetails: bookDetails ?? this.bookDetails,
      loadingBookId: loadingBookId ?? this.loadingBookId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentShelfDetail,
    errorMessage,
    actionDetailsStatus,
    actionMessage,
    bookDetails,
    loadingBookId,
  ];
}
