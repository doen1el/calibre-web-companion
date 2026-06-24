import 'package:equatable/equatable.dart';

enum DiscoverStatus { initial, navigating }

class DiscoverState extends Equatable {
  final DiscoverStatus status;
  final bool isOpds;
  final bool hasDiscover;

  const DiscoverState({
    this.status = DiscoverStatus.initial,
    this.isOpds = false,
    this.hasDiscover = true,
  });

  DiscoverState copyWith({
    DiscoverStatus? status,
    bool? isOpds,
    bool? hasDiscover,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      isOpds: isOpds ?? this.isOpds,
      hasDiscover: hasDiscover ?? this.hasDiscover,
    );
  }

  @override
  List<Object?> get props => [status, isOpds, hasDiscover];
}
