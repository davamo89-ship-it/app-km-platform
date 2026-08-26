class StravaAuthException implements Exception {
  const StravaAuthException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() {
    if (code == null) {
      return 'StravaAuthException: $message';
    }

    return 'StravaAuthException($code): $message';
  }
}
