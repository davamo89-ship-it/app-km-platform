import '../../../../core/config/app_rules.dart';
import '../../../../models/strava_activity.dart';
import '../validation_rule.dart';

class DistanceRule extends ValidationRule {
  const DistanceRule();

  @override
  Future<ValidationResult> validate(
    ValidationContext context,
  ) async {
    final activity = context.activity;

    switch (activity.sportType) {
      case SportType.running:
        return _validateDistance(
          distanceKm: activity.distanceKm,
          minimumKm: AppRules.minRunningKm,
          maximumKm: AppRules.maxRunningKm,
          sportName: 'correr',
        );

      case SportType.walking:
        return _validateDistance(
          distanceKm: activity.distanceKm,
          minimumKm: AppRules.minWalkingKm,
          maximumKm: AppRules.maxWalkingKm,
          sportName: 'caminar',
        );

      case SportType.cycling:
        return _validateDistance(
          distanceKm: activity.distanceKm,
          minimumKm: AppRules.minCyclingKm,
          maximumKm: AppRules.maxCyclingKm,
          sportName: 'ciclismo',
        );

      case SportType.swimming:
        return _validateDistance(
          distanceKm: activity.distanceKm,
          minimumKm: AppRules.minSwimmingKm,
          maximumKm: AppRules.maxSwimmingKm,
          sportName: 'natación',
        );

      case SportType.gym:
        return _validateGymDuration(
          minutes: activity.movingMinutes,
        );

      case SportType.unknown:
        return const ValidationResult(
          isValid: false,
          reason:
              'No es posible validar la distancia de un deporte desconocido.',
          confidence: AppRules.rejectedConfidence,
        );
    }
  }

  ValidationResult _validateDistance({
    required double distanceKm,
    required double minimumKm,
    required double maximumKm,
    required String sportName,
  }) {
    if (distanceKm < minimumKm) {
      return ValidationResult(
        isValid: false,
        reason:
            'La actividad de $sportName no alcanza la distancia mínima de '
            '$minimumKm km.',
        confidence: AppRules.defaultConfidence,
      );
    }

    if (distanceKm > maximumKm) {
      return ValidationResult(
        isValid: false,
        reason:
            'La actividad de $sportName supera el límite máximo de '
            '$maximumKm km.',
        confidence: AppRules.defaultConfidence,
      );
    }

    return ValidationResult(
      isValid: true,
      reason:
          'La distancia de la actividad de $sportName está dentro de los límites permitidos.',
      confidence: AppRules.defaultConfidence,
    );
  }

  ValidationResult _validateGymDuration({
    required double minutes,
  }) {
    if (minutes < AppRules.minGymMinutes) {
      return const ValidationResult(
        isValid: false,
        reason:
            'La actividad de gimnasio no alcanza la duración mínima de '
            '${AppRules.minGymMinutes} minutos.',
        confidence: AppRules.defaultConfidence,
      );
    }

    if (minutes > AppRules.maxGymMinutes) {
      return const ValidationResult(
        isValid: false,
        reason:
            'La actividad de gimnasio supera la duración máxima de '
            '${AppRules.maxGymMinutes} minutos.',
        confidence: AppRules.defaultConfidence,
      );
    }

    return const ValidationResult(
      isValid: true,
      reason:
          'La duración de la actividad de gimnasio está dentro de los límites permitidos.',
      confidence: AppRules.defaultConfidence,
    );
  }
}