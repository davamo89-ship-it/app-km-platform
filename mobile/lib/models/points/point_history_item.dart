class PointHistoryItem {
  const PointHistoryItem({
    required this.type,
    required this.points,
    required this.createdAtUtc,
    this.expiresAtUtc,
    this.athleteActivityId,
    this.stravaActivityId,
    this.activityType,
    this.distanceKilometers,
  });

  final String type;
  final int points;
  final DateTime createdAtUtc;
  final DateTime? expiresAtUtc;
  final String? athleteActivityId;
  final int? stravaActivityId;
  final String? activityType;
  final double? distanceKilometers;

  factory PointHistoryItem.fromJson(Map<String, dynamic> json) {
    return PointHistoryItem(
      type: json['type'] as String? ?? 'Unknown',
      points: (json['points'] as num?)?.toInt() ?? 0,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      expiresAtUtc: json['expiresAtUtc'] == null
          ? null
          : DateTime.parse(json['expiresAtUtc'] as String),
      athleteActivityId: json['athleteActivityId'] as String?,
      stravaActivityId: (json['stravaActivityId'] as num?)?.toInt(),
      activityType: json['activityType'] as String?,
      distanceKilometers:
          (json['distanceKilometers'] as num?)?.toDouble(),
    );
  }
}
