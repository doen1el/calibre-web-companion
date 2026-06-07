import 'package:equatable/equatable.dart';

import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';

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
  final bool isOpds;
  final bool isLoadingMore;
  final bool hasMoreBooks;
  final int? nextOffset;

  const ShelfDetailsState({
    this.status = ShelfDetailsStatus.initial,
    this.currentShelfDetail,
    this.errorMessage,
    this.actionDetailsStatus = ShelfDetailsActionStatus.initial,
    this.actionMessage,
    this.bookDetails,
    this.loadingBookId,
    this.isOpds = false,
    this.isLoadingMore = false,
    this.hasMoreBooks = false,
    this.nextOffset,
  });

  ShelfDetailsState copyWith({
    ShelfDetailsStatus? status,
    ShelfDetailsModel? currentShelfDetail,
    String? errorMessage,
    ShelfDetailsActionStatus? actionDetailsStatus,
    String? actionMessage,
    BookViewModel? bookDetails,
    String? loadingBookId,
    bool? isOpds,
    bool? isLoadingMore,
    bool? hasMoreBooks,
    int? nextOffset,
  }) {
    return ShelfDetailsState(
      status: status ?? this.status,
      currentShelfDetail: currentShelfDetail ?? this.currentShelfDetail,
      errorMessage: errorMessage,
      actionDetailsStatus: actionDetailsStatus ?? this.actionDetailsStatus,
      actionMessage: actionMessage,
      bookDetails: bookDetails ?? this.bookDetails,
      loadingBookId: loadingBookId ?? this.loadingBookId,
      isOpds: isOpds ?? this.isOpds,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreBooks: hasMoreBooks ?? this.hasMoreBooks,
      nextOffset: nextOffset ?? this.nextOffset,
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
    isOpds,
    isLoadingMore,
    hasMoreBooks,
    nextOffset,
  ];
}
