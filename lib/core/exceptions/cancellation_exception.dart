class CancellationException implements Exception {
  final String message;

  const CancellationException(this.message);

  @override
  String toString() => message;
}
