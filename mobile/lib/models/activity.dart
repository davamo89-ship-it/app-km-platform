enum ActivityType {
  running,
  walking,
  cycling,
}

enum ActivityStatus {
  approved,
  pending,
  rejected,
}

class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.type,
    required this.distanceKilometers,
    required this.durationMinutes,
    required this.date,
    required this.pointsEarned,
    required this.status,
    required this.source,
  });

  final String id;
  final String title;
  final ActivityType type;
  final double distanceKilometers;
  final int durationMinutes;
  final DateTime date;
  final int pointsEarned;
  final ActivityStatus status;
  final String source;

  Activity copyWith({
    String? id,
    String? title,
    ActivityType? type,
    double? distanceKilometers,
    int? durationMinutes,
    DateTime? date,
    int? pointsEarned,
    ActivityStatus? status,
    String? source,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      distanceKilometers:
          distanceKilometers ?? this.distanceKilometers,
      durationMinutes:
          durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      status: status ?? this.status,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'distanceKilometers': distanceKilometers,
      'durationMinutes': durationMinutes,
      'date': date.toIso8601String(),
      'pointsEarned': pointsEarned,
      'status': status.name,
      'source': source,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as String,
      title: map['title'] as String,
      type: ActivityType.values.firstWhere(
        (type) => type.name == map['type'],
      ),
      distanceKilometers:
          (map['distanceKilometers'] as num).toDouble(),
      durationMinutes: map['durationMinutes'] as int,
      date: DateTime.parse(map['date'] as String),
      pointsEarned: map['pointsEarned'] as int,
      status: ActivityStatus.values.firstWhere(
        (status) => status.name == map['status'],
      ),
      source: map['source'] as String,
    );
  }
}