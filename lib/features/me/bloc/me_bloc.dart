import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/me/bloc/me_event.dart';
import 'package:calibre_web_companion/features/me/bloc/me_state.dart';

import 'package:calibre_web_companion/features/me/data/repositories/me_repositorie.dart';

class MeBloc extends Bloc<MeEvent, MeState> {
  final MeRepository repository;

  MeBloc({required this.repository}) : super(const MeState()) {
    on<LoadStats>(_onLoadStats);
    on<LogOut>(_onLogOut);
  }

  Future<void> _onLoadStats(LoadStats event, Emitter<MeState> emit) async {
    emit(state.copyWith(status: MeStatus.loading));

    try {
      final stats = await repository.getStats();

      emit(
        state.copyWith(
          status: MeStatus.loaded,
          stats: stats,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: MeStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLogOut(LogOut event, Emitter<MeState> emit) async {
    emit(state.copyWith(logoutStatus: LogoutStatus.loading));

    try {
      await repository.logOut();

      emit(state.copyWith(logoutStatus: LogoutStatus.success));
    } catch (e) {
      emit(state.copyWith(status: MeStatus.error, errorMessage: e.toString()));
    }
  }
}
