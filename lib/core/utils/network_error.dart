bool isNetworkError(Object error) => isNetworkErrorMessage(error.toString());

bool isNetworkErrorMessage(String? message) {
  final s = (message ?? '').toLowerCase();
  return s.contains('socketexception') ||
      s.contains('clientexception') ||
      s.contains('failed host lookup') ||
      s.contains('no address associated') ||
      s.contains('network is unreachable') ||
      s.contains('connection refused') ||
      s.contains('connection reset') ||
      s.contains('connection closed') ||
      s.contains('software caused connection abort') ||
      s.contains('handshakeexception') ||
      s.contains('timeoutexception') ||
      s.contains('timed out');
}
