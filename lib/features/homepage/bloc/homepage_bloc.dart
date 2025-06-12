import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/homepage/bloc/homepage_event.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_state.dart';

class HomePageBloc extends Bloc<HomePageEvent, HomePageState> {
  HomePageBloc() : super(const HomePageState()) {
    on<ChangeNavIndex>(_onChangeNavIndex);
  }

  void _onChangeNavIndex(ChangeNavIndex event, Emitter<HomePageState> emit) {
    emit(state.copyWith(currentNavIndex: event.index));
  }
}
