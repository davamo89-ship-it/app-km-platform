import '../../../models/strava_activity.dart';

class ValidationContext {
  const ValidationContext({
    required this.activity,
    required this.userId,
    this.todayActivities = const [],
    this.processedActivities = const [],
  });

  /// Actividad que se está validando
  final StravaActivity activity;

  /// Usuario propietario
  final String userId;

  /// Actividades del mismo día
  final List<StravaActivity> todayActivities;

  /// Actividades ya procesadas anteriormente
  final List<StravaActivity> processedActivities;
}

class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.reason,
    this.confidence = 100,
  });

  final bool isValid;
  final String reason;
  final int confidence;
}

abstract class ValidationRule {
  const ValidationRule();

  Future<ValidationResult> validate(
    ValidationContext context,
  );
}