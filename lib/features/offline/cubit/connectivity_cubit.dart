import 'dart:async';

import 'package:calibre_web_companion/core/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ConnectivityStatus { unknown, online, offline }

class ConnectivityCubit extends Cubit<ConnectivityStatus>
    with WidgetsBindingObserver {
  final ConnectivityService service;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _checking = false;

  ConnectivityCubit({required this.service})
    : super(ConnectivityStatus.unknown) {
    WidgetsBinding.instance.addObserver(this);
    _subscription = service.onChange.listen((_) => recheck());

    recheck();
  }

  bool get isOffline => state == ConnectivityStatus.offline;

  void reportSuccess() {
    if (state != ConnectivityStatus.online) {
      emit(ConnectivityStatus.online);
    }
  }

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        this.state != ConnectivityStatus.online) {
      recheck();
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    return super.close();
  }
}
