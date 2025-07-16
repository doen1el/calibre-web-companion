import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  DiscoverBloc() : super(const DiscoverState()) {
    on<NavigateToBookList>(_onNavigateToBookList);
    on<NavigateToRecommendations>(_onNavigateToRecommendations);
  }

  void _onNavigateToBookList(
    NavigateToBookList event,
    Emitter<DiscoverState> emit,
  ) {
    emit(state.copyWith(status: DiscoverStatus.navigating));
    emit(state.copyWith(status: DiscoverStatus.initial));
  }

  void _onNavigateToRecommendations(
    NavigateToRecommendations event,
    Emitter<DiscoverState> emit,
  ) {
    emit(state.copyWith(status: DiscoverStatus.navigating));
    emit(state.copyWith(status: DiscoverStatus.initial));
  }
}
