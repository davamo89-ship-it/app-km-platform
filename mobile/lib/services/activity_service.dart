import '../models/activity_processing_result.dart';
import '../models/point_transaction.dart';
import '../models/strava_activity.dart';
import 'points_service.dart';
import 'validation_service.dart';

class ActivityService {
  ActivityService({
    ValidationService? validationService,
    PointsService? pointsService,
    String Function()? transactionIdGenerator,
  }) : _validationService = validationService ?? ValidationService(),
       _pointsService = pointsService ?? const PointsService(),
       _transactionIdGenerator =
           transactionIdGenerator ?? _defaultTransactionId;

  final ValidationService _validationService;
  final PointsService _pointsService;
  final String Function() _transactionIdGenerator;

  Future<ActivityProcessingResult> processActivity({
    required StravaActivity activity,
    required String userId,
    List<StravaActivity> todayActivities = const [],
    List<StravaActivity> processedActivities = const [],
  }) async {
    final validationResult = await _validationService.validate(
      activity: activity,
      userId: userId,
      todayActivities: todayActivities,
      processedActivities: processedActivities,
    );

    if (!validationResult.canGeneratePoints) {
      return ActivityProcessingResult(validatedActivity: validationResult);
    }

    final activityWithPoints = _pointsService.assignPoints(validationResult);

    if (activityWithPoints.pointsAwarded <= 0) {
      return ActivityProcessingResult(validatedActivity: activityWithPoints);
    }

    final transaction = PointTransaction.fromActivity(
      id: _transactionIdGenerator(),
      userId: userId,
      validatedActivity: activityWithPoints,
    );

    return ActivityProcessingResult(
      validatedActivity: activityWithPoints,
      pointTransaction: transaction,
    );
  }

  Future<List<ActivityProcessingResult>> processActivities({
    required List<StravaActivity> activities,
    required String userId,
    List<StravaActivity> todayActivities = const [],
    List<StravaActivity> processedActivities = const [],
  }) async {
    final results = <ActivityProcessingResult>[];

    final currentTodayActivities = List<StravaActivity>.from(todayActivities);

    final currentProcessedActivities = List<StravaActivity>.from(
      processedActivities,
    );

    for (final activity in activities) {
      final result = await processActivity(
        activity: activity,
        userId: userId,
        todayActivities: currentTodayActivities,
        processedActivities: currentProcessedActivities,
      );

      results.add(result);

      currentProcessedActivities.add(activity);

      if (result.isApproved) {
        currentTodayActivities.add(activity);
      }
    }

    return results;
  }

  static String _defaultTransactionId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return 'point_transaction_$timestamp';
  }
}
