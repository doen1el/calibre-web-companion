class RedirectException implements Exception {
  final String location;
  RedirectException(this.location);

  @override
  String toString() => 'RedirectException: Redirect to $location';
}
