import 'dart:async';

class SessionReauthService {
  static final SessionReauthService _instance =
      SessionReauthService._internal();
  factory SessionReauthService() => _instance;
  SessionReauthService._internal();

  Future<bool> Function()? _handler;
  Future<bool>? _inFlight;

  void registerHandler(Future<bool> Function()? handler) {
    _handler = handler;
  }

  Future<bool> requestReauth() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final handler = _handler;
    if (handler == null) return Future.value(false);

    final future = handler();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }
}
