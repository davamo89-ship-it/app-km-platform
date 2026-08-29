class AthleteDashboard {
  const AthleteDashboard({
    required this.athleteId,
    required this.displayName,
    required this.profileImageUrl,
    required this.pointsBalance,
    required this.stravaConnected,
    required this.stravaStatus,
    required this.lastActivity,
    required this.pointsExpiringSoon,
    required this.totalKilometers,
    required this.approvedActivities,
    required this.currentStreakDays,
    required this.monthlyKilometers,
  });

  final String athleteId;
  final String displayName;
  final String? profileImageUrl;
  final int pointsBalance;
  final bool stravaConnected;
  final String? stravaStatus;
  final DashboardActivity? lastActivity;
  final int pointsExpiringSoon;
  final double totalKilometers;
final int approvedActivities;
final int currentStreakDays;
final double monthlyKilometers;

  factory AthleteDashboard.fromJson(Map<String, dynamic> json) {
    return AthleteDashboard(
      athleteId: json['athleteId'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      pointsBalance: json['pointsBalance'] as int,
      stravaConnected: json['stravaConnected'] as bool,
      stravaStatus: json['stravaStatus'] as String?,
      lastActivity: json['lastActivity'] == null
          ? null
          : DashboardActivity.fromJson(
              json['lastActivity'] as Map<String, dynamic>,
            ),
      pointsExpiringSoon: json['pointsExpiringSoon'] as int,
      totalKilometers:
        (json['totalKilometers'] as num).toDouble(),
      approvedActivities:
            json['approvedActivities'] as int,
      currentStreakDays:
            json['currentStreakDays'] as int,
      monthlyKilometers:
            (json['monthlyKilometers'] as num).toDouble(),
    );
  }
}

class DashboardActivity {
  const DashboardActivity({
    required this.stravaActivityId,
    required this.activityType,
    required this.distanceKilometers,
    required this.points,
    required this.startDateUtc,
  });

  final int stravaActivityId;
  final String activityType;
  final double distanceKilometers;
  final int points;
  final DateTime startDateUtc;

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      stravaActivityId: json['stravaActivityId'] as int,
      activityType: json['activityType'] as String,
      distanceKilometers:
          (json['distanceKilometers'] as num).toDouble(),
      points: json['points'] as int,
      startDateUtc: DateTime.parse(
        json['startDateUtc'] as String,
      ),
    );
  }
}