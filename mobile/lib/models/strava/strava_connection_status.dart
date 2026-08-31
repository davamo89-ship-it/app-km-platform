class StravaConnectionStatus {
  const StravaConnectionStatus({
    required this.connected,
    required this.stravaAthleteId,
    required this.status,
    required this.connectedAtUtc,
    required this.accessTokenExpiresAtUtc,
  });

  final bool connected;
  final int? stravaAthleteId;
  final String? status;
  final DateTime? connectedAtUtc;
  final DateTime? accessTokenExpiresAtUtc;

  factory StravaConnectionStatus.fromJson(Map<String, dynamic> json) {
    return StravaConnectionStatus(
      connected: json['connected'] as bool,
      stravaAthleteId: (json['stravaAthleteId'] as num?)?.toInt(),
      status: json['status'] as String?,
      connectedAtUtc: json['connectedAtUtc'] == null
          ? null
          : DateTime.parse(json['connectedAtUtc'] as String),
      accessTokenExpiresAtUtc: json['accessTokenExpiresAtUtc'] == null
          ? null
          : DateTime.parse(json['accessTokenExpiresAtUtc'] as String),
    );
  }
}
