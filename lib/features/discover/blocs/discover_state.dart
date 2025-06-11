import 'package:equatable/equatable.dart';

enum DiscoverStatus { initial, navigating }

class DiscoverState extends Equatable {
  final DiscoverStatus status;

  const DiscoverState({this.status = DiscoverStatus.initial});

  DiscoverState copyWith({DiscoverStatus? status}) {
    return DiscoverState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}
