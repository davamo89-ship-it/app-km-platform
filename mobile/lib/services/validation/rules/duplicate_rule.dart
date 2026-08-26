import '../../../../core/config/app_rules.dart';
import '../validation_rule.dart';

class DuplicateRule extends ValidationRule {
  const DuplicateRule();

  @override
  Future<ValidationResult> validate(
    ValidationContext context,
  ) async {
    final alreadyExists = context.processedActivities.any(
  (activity) => activity.stravaId == context.activity.stravaId,
    );

    if (alreadyExists) {
      return const ValidationResult(
        isValid: false,
        reason:
            'La actividad ya fue procesada anteriormente.',
        confidence: AppRules.rejectedConfidence,
      );
    }

    return const ValidationResult(
      isValid: true,
      reason:
          'La actividad no ha sido procesada previamente.',
      confidence: AppRules.defaultConfidence,
    );
  }
}