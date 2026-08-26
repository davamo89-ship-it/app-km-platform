import '../models/strava_activity.dart';
import '../models/validated_activity.dart';
import 'activity_repository.dart';

class InMemoryActivityRepository extends ActivityRepository {
  final List<ValidatedActivity> _activities = [];

  @override
  Future<void> saveValidatedActivity(ValidatedActivity activity) async {
    final existingIndex = _activities.indexWhere(
      (item) => item.activity.stravaId == activity.activity.stravaId,
    );

    if (existingIndex >= 0) {
      _activities[existingIndex] = activity;
      return;
    }

    _activities.add(activity);
  }

  @override
  Future<ValidatedActivity?> findByStravaId({
    required String userId,
    required String stravaId,
  }) async {
    for (final activity in _activities) {
      if (activity.activity.stravaId == stravaId) {
        return activity;
      }
    }

    return null;
  }

  @override
  Future<List<ValidatedActivity>> getProcessedActivities({
    required String userId,
  }) async {
    return List.unmodifiable(_activities);
  }

  @override
  Future<List<StravaActivity>> getActivitiesByDate({
    required String userId,
    required DateTime date,
  }) async {
    return _activities
        .where((item) => _isSameDate(item.activity.startDateLocal, date))
        .map((item) => item.activity)
        .toList(growable: false);
  }

  @override
  Future<List<StravaActivity>> getTodayActivities({
    required String userId,
  }) async {
    return getActivitiesByDate(userId: userId, date: DateTime.now());
  }

  @override
  Future<bool> existsByStravaId({
    required String userId,
    required String stravaId,
  }) async {
    return _activities.any((item) => item.activity.stravaId == stravaId);
  }

  void clear() {
    _activities.clear();
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
