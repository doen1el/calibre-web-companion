import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  final SharedPreferences sharedPreferences;

  DiscoverBloc({required this.sharedPreferences})
    : super(const DiscoverState()) {
    on<NavigateToBookList>(_onNavigateToBookList);
    on<NavigateToRecommendations>(_onNavigateToRecommendations);
    on<CheckServerType>(_onCheckServerType);

    add(CheckServerType());
  }

  void _onCheckServerType(CheckServerType event, Emitter<DiscoverState> emit) {
    final isOpds = sharedPreferences.getString('server_type') == 'opds';
    emit(state.copyWith(isOpds: isOpds));
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
