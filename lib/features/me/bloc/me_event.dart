import 'package:equatable/equatable.dart';

abstract class MeEvent extends Equatable {
  const MeEvent();

  @override
  List<Object?> get props => [];
}

class LoadStats extends MeEvent {
  const LoadStats();
}

class LogOut extends MeEvent {
  const LogOut();
}

class NavigateToSettings extends MeEvent {
  const NavigateToSettings();
}

class NavigateToShelves extends MeEvent {
  const NavigateToShelves();
}

class NavigateToReadBooks extends MeEvent {
  const NavigateToReadBooks();
}

class NavigateToUnreadBooks extends MeEvent {
  const NavigateToUnreadBooks();
}
