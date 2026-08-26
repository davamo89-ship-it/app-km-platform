class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.totalPoints,
    required this.totalKilometers,
    required this.totalActivities,
    required this.currentStreak,
    required this.monthlyGoal,
    required this.isStravaConnected,
  });

  final String id;
  final String name;
  final String email;
  final int totalPoints;
  final double totalKilometers;
  final int totalActivities;
  final int currentStreak;
  final double monthlyGoal;
  final bool isStravaConnected;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    int? totalPoints,
    double? totalKilometers,
    int? totalActivities,
    int? currentStreak,
    double? monthlyGoal,
    bool? isStravaConnected,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      totalPoints: totalPoints ?? this.totalPoints,
      totalKilometers:
          totalKilometers ?? this.totalKilometers,
      totalActivities:
          totalActivities ?? this.totalActivities,
      currentStreak: currentStreak ?? this.currentStreak,
      monthlyGoal: monthlyGoal ?? this.monthlyGoal,
      isStravaConnected:
          isStravaConnected ?? this.isStravaConnected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'totalPoints': totalPoints,
      'totalKilometers': totalKilometers,
      'totalActivities': totalActivities,
      'currentStreak': currentStreak,
      'monthlyGoal': monthlyGoal,
      'isStravaConnected': isStravaConnected,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      totalPoints: map['totalPoints'] as int,
      totalKilometers:
          (map['totalKilometers'] as num).toDouble(),
      totalActivities: map['totalActivities'] as int,
      currentStreak: map['currentStreak'] as int,
      monthlyGoal:
          (map['monthlyGoal'] as num).toDouble(),
      isStravaConnected:
          map['isStravaConnected'] as bool,
    );
  }
}