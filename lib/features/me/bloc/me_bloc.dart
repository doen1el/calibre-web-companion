import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/core/services/widget_service.dart';
import 'package:calibre_web_companion/features/me/bloc/me_event.dart';
import 'package:calibre_web_companion/features/me/bloc/me_state.dart';

import 'package:calibre_web_companion/features/me/data/repositories/me_repository.dart';

class MeBloc extends Bloc<MeEvent, MeState> {
  final MeRepository repository;
  final WidgetService widgetService;

  MeBloc({required this.repository, required this.widgetService})
    : super(const MeState()) {
    on<LoadStats>(_onLoadStats);
    on<LogOut>(_onLogOut);
  }

  Future<void> _onLoadStats(LoadStats event, Emitter<MeState> emit) async {
    emit(state.copyWith(status: MeStatus.loading));

    try {
      final isOpds = repository.getIsOpds();
      final showStats = repository.getShowStats();
      final stats = await repository.getStats();

      emit(
        state.copyWith(
          status: MeStatus.loaded,
          stats: stats,
          errorMessage: null,
          isOpds: isOpds,
          showStats: showStats,
        ),
      );

      if (showStats) {
        await widgetService.pushStats(
          books: stats.books,
          authors: stats.authors,
          categories: stats.categories,
          series: stats.series,
        );
      }
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
