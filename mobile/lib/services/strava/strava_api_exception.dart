class StravaApiException implements Exception {
  const StravaApiException({
    required this.message,
    this.statusCode,
    this.endpoint,
    this.responseBody,
  });

  final String message;
  final int? statusCode;
  final String? endpoint;
  final String? responseBody;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isRateLimited => statusCode == 429;

  bool get isServerError {
    return statusCode != null && statusCode! >= 500;
  }

  @override
  String toString() {
    final parts = <String>[
      'StravaApiException: $message',
      if (statusCode != null) 'statusCode: $statusCode',
      if (endpoint != null) 'endpoint: $endpoint',
    ];

    return parts.join(', ');
  }
}
