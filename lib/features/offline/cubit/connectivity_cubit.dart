import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/core/services/connectivity_service.dart';

enum ConnectivityStatus { unknown, online, offline }

class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  final ConnectivityService service;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _checking = false;

  ConnectivityCubit({required this.service})
    : super(ConnectivityStatus.unknown) {
    _subscription = service.onChange.listen((_) => recheck());
  }

  bool get isOffline => state == ConnectivityStatus.offline;

  Future<void> recheck() async {
    if (_checking) return;
    _checking = true;
    try {
      final reachable = await service.isServerReachable();
      emit(reachable ? ConnectivityStatus.online : ConnectivityStatus.offline);
    } finally {
      _checking = false;
    }
  }

  Future<void> reportFailure() => recheck();

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
