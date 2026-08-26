import 'validated_activity.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.currentPoints,
    required this.totalKilometers,
    required this.approvedActivities,
    required this.currentStreakDays,
    required this.monthlyGoalKilometers,
    required this.monthlyKilometers,
    required this.latestActivity,
    required this.lastUpdatedAt,
  });

  final int currentPoints;
  final double totalKilometers;
  final int approvedActivities;
  final int currentStreakDays;
  final double monthlyGoalKilometers;
  final double monthlyKilometers;
  final ValidatedActivity? latestActivity;
  final DateTime lastUpdatedAt;

  bool get hasActivities => latestActivity != null;

  factory DashboardSummary.empty({double monthlyGoalKilometers = 350}) {
    return DashboardSummary(
      currentPoints: 0,
      totalKilometers: 0,
      approvedActivities: 0,
      currentStreakDays: 0,
      monthlyGoalKilometers: monthlyGoalKilometers,
      monthlyKilometers: 0,
      latestActivity: null,
      lastUpdatedAt: DateTime.now(),
    );
  }
}
