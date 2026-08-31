class StravaActivity {
  const StravaActivity({
    required this.id,
    required this.name,
    required this.sportType,
    required this.distanceMeters,
    required this.startDateUtc,
    required this.startDateLocal,
    required this.elapsedTimeSeconds,
    required this.movingTimeSeconds,
  });

  final int id;
  final String name;
  final String sportType;
  final double distanceMeters;
  final DateTime startDateUtc;
  final DateTime startDateLocal;
  final int elapsedTimeSeconds;
  final int movingTimeSeconds;

  double get distanceKilometers => distanceMeters / 1000;

  factory StravaActivity.fromJson(Map<String, dynamic> json) {
    return StravaActivity(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sportType: json['sportType'] as String,
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      startDateUtc: DateTime.parse(json['startDateUtc'] as String),
      startDateLocal: DateTime.parse(json['startDateLocal'] as String),
      elapsedTimeSeconds: (json['elapsedTimeSeconds'] as num).toInt(),
      movingTimeSeconds: (json['movingTimeSeconds'] as num).toInt(),
    );
  }
}
