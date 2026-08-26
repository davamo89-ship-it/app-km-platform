import '../../../../core/config/app_rules.dart';
import '../../../../models/strava_activity.dart';
import '../validation_rule.dart';

class SpeedRule extends ValidationRule {
  const SpeedRule();

  @override
  Future<ValidationResult> validate(
    ValidationContext context,
  ) async {
    final activity = context.activity;
    final averageSpeedKmH = activity.averageSpeedKmH;

    switch (activity.sportType) {
      case SportType.running:
        return _validateSpeed(
          averageSpeedKmH: averageSpeedKmH,
          maximumSpeedKmH: AppRules.maxRunningSpeed,
          sportName: 'correr',
        );

      case SportType.walking:
        return _validateSpeed(
          averageSpeedKmH: averageSpeedKmH,
          maximumSpeedKmH: AppRules.maxWalkingSpeed,
          sportName: 'caminar',
        );

      case SportType.cycling:
        return _validateSpeed(
          averageSpeedKmH: averageSpeedKmH,
          maximumSpeedKmH: AppRules.maxCyclingSpeed,
          sportName: 'ciclismo',
        );

      case SportType.swimming:
        return _validateSpeed(
          averageSpeedKmH: averageSpeedKmH,
          maximumSpeedKmH: AppRules.maxSwimmingSpeed,
          sportName: 'natación',
        );

      case SportType.gym:
        return const ValidationResult(
          isValid: true,
          reason:
              'La validación de velocidad no aplica para actividades de gimnasio.',
          confidence: AppRules.defaultConfidence,
        );

      case SportType.unknown:
        return const ValidationResult(
          isValid: false,
          reason:
              'No es posible validar la velocidad de un deporte desconocido.',
          confidence: AppRules.rejectedConfidence,
        );
    }
  }

  ValidationResult _validateSpeed({
    required double averageSpeedKmH,
    required double maximumSpeedKmH,
    required String sportName,
  }) {
    if (averageSpeedKmH <= 0) {
      return ValidationResult(
        isValid: false,
        reason:
            'La actividad de $sportName no tiene una velocidad promedio válida.',
        confidence: AppRules.rejectedConfidence,
      );
    }

    if (averageSpeedKmH > maximumSpeedKmH) {
      return ValidationResult(
        isValid: false,
        reason:
            'La velocidad promedio de $averageSpeedKmH km/h supera el máximo permitido de '
            '$maximumSpeedKmH km/h para $sportName.',
        confidence: AppRules.pendingConfidence,
      );
    }

    return ValidationResult(
      isValid: true,
      reason:
          'La velocidad promedio de la actividad de $sportName está dentro del límite permitido.',
      confidence: AppRules.defaultConfidence,
    );
  }
}