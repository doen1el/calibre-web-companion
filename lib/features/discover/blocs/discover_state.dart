import 'package:equatable/equatable.dart';

enum DiscoverStatus { initial, navigating }

class DiscoverState extends Equatable {
  final DiscoverStatus status;
  final bool isOpds;

  const DiscoverState({
    this.status = DiscoverStatus.initial,
    this.isOpds = false,
  });

  DiscoverState copyWith({
    DiscoverStatus? status,
    bool? isOpds,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      isOpds: isOpds ?? this.isOpds,
    );
  }

  @override
  List<Object?> get props => [status, isOpds];
}
