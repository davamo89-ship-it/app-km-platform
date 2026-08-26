import '../../../../core/config/app_rules.dart';
import '../../../../models/strava_activity.dart';
import '../validation_rule.dart';

class SportRule extends ValidationRule {
  const SportRule();

  @override
  Future<ValidationResult> validate(
    ValidationContext context,
  ) async {
    final sportType = context.activity.sportType;

    if (sportType == SportType.unknown) {
      return const ValidationResult(
        isValid: false,
        reason: 'El tipo de deporte no es reconocido por App KM.',
        confidence: AppRules.defaultConfidence,
      );
    }

    final sportName = sportType.name;

    if (!AppRules.allowedSports.contains(sportName)) {
      return ValidationResult(
        isValid: false,
        reason:
            'El deporte "$sportName" no está permitido en el MVP de App KM.',
        confidence: AppRules.defaultConfidence,
      );
    }

    return ValidationResult(
      isValid: true,
      reason: 'El deporte "$sportName" está permitido.',
      confidence: AppRules.defaultConfidence,
    );
  }
}