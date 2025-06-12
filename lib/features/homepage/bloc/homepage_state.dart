import 'package:equatable/equatable.dart';

class HomePageState extends Equatable {
  final int currentNavIndex;

  const HomePageState({this.currentNavIndex = 0});

  HomePageState copyWith({int? currentNavIndex}) {
    return HomePageState(
      currentNavIndex: currentNavIndex ?? this.currentNavIndex,
    );
  }

  @override
  List<Object?> get props => [currentNavIndex];
}
