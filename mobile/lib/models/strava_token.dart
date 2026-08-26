class StravaToken {
  const StravaToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.tokenType,
  });

  final String accessToken;

  final String refreshToken;

  /// Fecha de expiración expresada como Unix timestamp
  /// en segundos.
  final int expiresAt;

  final String tokenType;

  factory StravaToken.fromJson(Map<String, dynamic> json) {
    return StravaToken(
      accessToken: _readRequiredString(json, 'access_token'),
      refreshToken: _readRequiredString(json, 'refresh_token'),
      expiresAt: _readRequiredInt(json, 'expires_at'),
      tokenType: json['token_type']?.toString() ?? 'Bearer',
    );
  }

  DateTime get expirationDate =>
      DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true);

  bool get isExpired => isExpiredAt(DateTime.now().toUtc());

  bool isExpiredAt(
    DateTime dateTime, {
    Duration safetyMargin = const Duration(minutes: 5),
  }) {
    final refreshTime = expirationDate.subtract(safetyMargin);

    return !dateTime.toUtc().isBefore(refreshTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt,
      'token_type': tokenType,
    };
  }

  StravaToken copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresAt,
    String? tokenType,
  }) {
    return StravaToken(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenType: tokenType ?? this.tokenType,
    );
  }

  static String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key]?.toString();

    if (value == null || value.trim().isEmpty) {
      throw FormatException('El campo "$key" no existe o está vacío.');
    }

    return value;
  }

  static int _readRequiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is int) {
      return value;
    }

    final parsed = int.tryParse(value?.toString() ?? '');

    if (parsed == null) {
      throw FormatException('El campo "$key" no contiene un número válido.');
    }

    return parsed;
  }
}
