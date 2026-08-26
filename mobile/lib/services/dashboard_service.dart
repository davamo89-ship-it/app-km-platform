import '../models/dashboard_summary.dart';
import '../models/validated_activity.dart';
import '../repositories/activity_repository.dart';
import '../repositories/point_transaction_repository.dart';

class DashboardService {
  const DashboardService({
    required ActivityRepository activityRepository,
    required PointTransactionRepository pointTransactionRepository,
    this.monthlyGoalKilometers = 350,
  }) : _activityRepository = activityRepository,
       _pointTransactionRepository = pointTransactionRepository;

  final ActivityRepository _activityRepository;
  final PointTransactionRepository _pointTransactionRepository;
  final double monthlyGoalKilometers;

  Future<DashboardSummary> loadSummary({required String userId}) async {
    final activities = await _activityRepository.getProcessedActivities(
      userId: userId,
    );

    final approvedActivities =
        activities.where((item) => item.isApproved).toList()..sort(
          (first, second) => second.activity.startDateLocal.compareTo(
            first.activity.startDateLocal,
          ),
        );

    final currentPoints = await _pointTransactionRepository.getCurrentBalance(
      userId: userId,
    );

    final totalKilometers = approvedActivities.fold<double>(
      0,
      (total, item) => total + item.activity.distanceKm,
    );

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    final monthlyKilometers = approvedActivities
        .where((item) => !item.activity.startDateLocal.isBefore(monthStart))
        .fold<double>(0, (total, item) => total + item.activity.distanceKm);

    return DashboardSummary(
      currentPoints: currentPoints,
      totalKilometers: totalKilometers,
      approvedActivities: approvedActivities.length,
      currentStreakDays: _calculateCurrentStreak(approvedActivities),
      monthlyGoalKilometers: monthlyGoalKilometers,
      monthlyKilometers: monthlyKilometers,
      latestActivity: approvedActivities.isEmpty
          ? null
          : approvedActivities.first,
      lastUpdatedAt: DateTime.now(),
    );
  }

  int _calculateCurrentStreak(List<ValidatedActivity> activities) {
    if (activities.isEmpty) {
      return 0;
    }

    final activityDays =
        activities
            .map(
              (item) => DateTime(
                item.activity.startDateLocal.year,
                item.activity.startDateLocal.month,
                item.activity.startDateLocal.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((first, second) => second.compareTo(first));

    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (activityDays.first != today && activityDays.first != yesterday) {
      return 0;
    }

    var streak = 1;
    var expectedDay = activityDays.first.subtract(const Duration(days: 1));

    for (final day in activityDays.skip(1)) {
      if (day == expectedDay) {
        streak++;
        expectedDay = expectedDay.subtract(const Duration(days: 1));
        continue;
      }

      if (day.isBefore(expectedDay)) {
        break;
      }
    }

    return streak;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
