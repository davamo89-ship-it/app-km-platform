class UpcomingPointExpiration {
  const UpcomingPointExpiration({
    required this.remainingPoints,
    required this.expiresAtUtc,
    required this.daysRemaining,
    required this.shouldNotify,
  });

  final int remainingPoints;
  final DateTime expiresAtUtc;
  final int daysRemaining;
  final bool shouldNotify;

  factory UpcomingPointExpiration.fromJson(
    Map<String, dynamic> json,
  ) {
    return UpcomingPointExpiration(
      remainingPoints:
          (json['remainingPoints'] as num?)?.toInt() ?? 0,
      expiresAtUtc:
          DateTime.parse(json['expiresAtUtc'] as String),
      daysRemaining:
          (json['daysRemaining'] as num?)?.toInt() ?? 0,
      shouldNotify: json['shouldNotify'] as bool? ?? false,
    );
  }
}