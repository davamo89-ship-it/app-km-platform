import '../models/strava_activity.dart';
import '../models/validated_activity.dart';
import 'validation/rules/activity_date_rule.dart';
import 'validation/rules/daily_limit_rule.dart';
import 'validation/rules/distance_rule.dart';
import 'validation/rules/duplicate_rule.dart';
import 'validation/rules/manual_activity_rule.dart';
import 'validation/rules/speed_rule.dart';
import 'validation/rules/sport_rule.dart';
import 'validation/validation_rule.dart';

class ValidationService {
  ValidationService({
    List<ValidationRule>? rules,
    DateTime Function()? nowProvider,
  }) : _rules = List.unmodifiable(
          rules ??
              [
                ActivityDateRule(
                  nowProvider: nowProvider,
                ),
                ManualActivityRule(),
                SportRule(),
                DuplicateRule(),
                DistanceRule(),
                SpeedRule(),
                DailyLimitRule(),
              ],
        );

  final List<ValidationRule> _rules;

  Future<ValidatedActivity> validate({
    required StravaActivity activity,
    required String userId,
    List<StravaActivity> todayActivities = const [],
    List<StravaActivity> processedActivities = const [],
  }) async {
    final context = ValidationContext(
      activity: activity,
      userId: userId,
      todayActivities: todayActivities,
      processedActivities: processedActivities,
    );

    for (final rule in _rules) {
      final result = await rule.validate(context);

      if (!result.isValid) {
        if (_requiresManualReview(result)) {
          return ValidatedActivity.pending(
            activity: activity,
            reason: result.reason,
            confidence: result.confidence,
          );
        }

        return ValidatedActivity.rejected(
          activity: activity,
          reason: result.reason,
          confidence: result.confidence,
        );
      }
    }

    return ValidatedActivity.approved(
      activity: activity,
    );
  }

  bool _requiresManualReview(
    ValidationResult result,
  ) {
    return result.confidence < 100 &&
        result.confidence > 0;
  }
}