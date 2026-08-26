import '../../../../core/config/app_rules.dart';
import '../validation_rule.dart';

class DailyLimitRule extends ValidationRule {
  const DailyLimitRule();

  @override
  Future<ValidationResult> validate(
    ValidationContext context,
  ) async {
    final currentSport = context.activity.sportType;

    final activitiesToday = context.todayActivities.where(
      (activity) => activity.sportType == currentSport,
    );

    if (activitiesToday.length >=
        AppRules.maxActivitiesPerSportPerDay) {
      return ValidationResult(
        isValid: false,
        reason:
            'Ya existe una actividad registrada para este deporte el día de hoy.',
        confidence: AppRules.defaultConfidence,
      );
    }

    return const ValidationResult(
      isValid: true,
      reason:
          'No existe otra actividad registrada para este deporte hoy.',
      confidence: AppRules.defaultConfidence,
    );
  }
}