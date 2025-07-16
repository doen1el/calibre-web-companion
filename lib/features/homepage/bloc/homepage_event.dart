import 'package:equatable/equatable.dart';

abstract class HomePageEvent extends Equatable {
  const HomePageEvent();

  @override
  List<Object?> get props => [];
}

class ChangeNavIndex extends HomePageEvent {
  final int index;

  const ChangeNavIndex(this.index);

  @override
  List<Object?> get props => [index];
}
