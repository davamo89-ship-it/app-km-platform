import '../../../../core/config/app_rules.dart';
import '../validation_rule.dart';

class ManualActivityRule extends ValidationRule {
  const ManualActivityRule();

  @override
  Future<ValidationResult> validate(
    ValidationContext context,
  ) async {
    if (context.activity.isManual) {
      return const ValidationResult(
        isValid: false,
        reason:
            'La actividad fue registrada manualmente en Strava.',
        confidence: AppRules.defaultConfidence,
      );
    }

    return const ValidationResult(
      isValid: true,
      reason:
          'La actividad fue registrada automáticamente por Strava.',
      confidence: AppRules.defaultConfidence,
    );
  }
}