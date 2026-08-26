import '../models/activity_processing_result.dart';
import '../models/strava_activity.dart';
import '../repositories/activity_repository.dart';
import '../repositories/point_transaction_repository.dart';
import 'activity_service.dart';

class ActivityProcessingService {
  ActivityProcessingService({
    required ActivityRepository activityRepository,
    required PointTransactionRepository pointTransactionRepository,
    ActivityService? activityService,
  }) : _activityRepository = activityRepository,
       _pointTransactionRepository = pointTransactionRepository,
       _activityService = activityService ?? ActivityService();

  final ActivityRepository _activityRepository;

  final PointTransactionRepository _pointTransactionRepository;

  final ActivityService _activityService;

  Future<ActivityProcessingResult> processAndSave({
    required StravaActivity activity,
    required String userId,
  }) async {
    final processedActivities = await _activityRepository
        .getProcessedActivities(userId: userId);

    final todayActivities = await _activityRepository.getTodayActivities(
      userId: userId,
    );

    final processedStravaActivities = processedActivities
        .map((item) => item.activity)
        .toList(growable: false);

    final result = await _activityService.processActivity(
      activity: activity,
      userId: userId,
      todayActivities: todayActivities,
      processedActivities: processedStravaActivities,
    );

    await _activityRepository.saveValidatedActivity(result.validatedActivity);

    final transaction = result.pointTransaction;

    if (transaction != null) {
      await _pointTransactionRepository.saveTransaction(transaction);
    }

    return result;
  }

  Future<List<ActivityProcessingResult>> processAndSaveAll({
    required List<StravaActivity> activities,
    required String userId,
  }) async {
    final results = <ActivityProcessingResult>[];

    for (final activity in activities) {
      final result = await processAndSave(activity: activity, userId: userId);

      results.add(result);
    }

    return List.unmodifiable(results);
  }

  Future<int> getCurrentBalance({required String userId}) {
    return _pointTransactionRepository.getCurrentBalance(userId: userId);
  }
}
