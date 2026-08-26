import '../core/config/app_rules.dart';
import 'strava_activity.dart';

enum ValidationStatus {
  approved,
  rejected,
  pendingReview,
}

class ValidatedActivity {
  const ValidatedActivity({
    required this.activity,
    required this.status,
    required this.pointsAwarded,
    required this.validationReason,
    required this.ruleEngineVersion,
    required this.confidenceScore,
    required this.processedAt,
  });

  /// Actividad original recibida desde Strava.
  final StravaActivity activity;

  /// Resultado general del proceso de validación.
  final ValidationStatus status;

  /// Puntos asignados.
  ///
  /// El ValidationService todavía no calcula puntos, por lo que inicialmente
  /// será 0. PointsService será responsable de asignarlos posteriormente.
  final int pointsAwarded;

  /// Explicación del resultado.
  final String validationReason;

  /// Versión de las reglas utilizadas.
  final String ruleEngineVersion;

  /// Nivel de confianza del resultado, entre 0 y 100.
  final int confidenceScore;

  /// Fecha y hora en que se procesó la actividad.
  final DateTime processedAt;

  factory ValidatedActivity.approved({
    required StravaActivity activity,
    String reason = 'La actividad cumple todas las reglas de validación.',
    int confidence = AppRules.defaultConfidence,
    DateTime? processedAt,
  }) {
    return ValidatedActivity(
      activity: activity,
      status: ValidationStatus.approved,
      pointsAwarded: 0,
      validationReason: reason,
      ruleEngineVersion: AppRules.ruleEngineVersion,
      confidenceScore: _normalizeConfidence(confidence),
      processedAt: processedAt ?? DateTime.now(),
    );
  }

  factory ValidatedActivity.rejected({
    required StravaActivity activity,
    required String reason,
    int confidence = AppRules.rejectedConfidence,
    DateTime? processedAt,
  }) {
    return ValidatedActivity(
      activity: activity,
      status: ValidationStatus.rejected,
      pointsAwarded: 0,
      validationReason: reason,
      ruleEngineVersion: AppRules.ruleEngineVersion,
      confidenceScore: _normalizeConfidence(confidence),
      processedAt: processedAt ?? DateTime.now(),
    );
  }

  factory ValidatedActivity.pending({
    required StravaActivity activity,
    required String reason,
    int confidence = AppRules.pendingConfidence,
    DateTime? processedAt,
  }) {
    return ValidatedActivity(
      activity: activity,
      status: ValidationStatus.pendingReview,
      pointsAwarded: 0,
      validationReason: reason,
      ruleEngineVersion: AppRules.ruleEngineVersion,
      confidenceScore: _normalizeConfidence(confidence),
      processedAt: processedAt ?? DateTime.now(),
    );
  }

  bool get isApproved => status == ValidationStatus.approved;

  bool get isRejected => status == ValidationStatus.rejected;

  bool get requiresReview =>
      status == ValidationStatus.pendingReview;

  bool get canGeneratePoints => isApproved;

  ValidatedActivity copyWith({
    StravaActivity? activity,
    ValidationStatus? status,
    int? pointsAwarded,
    String? validationReason,
    String? ruleEngineVersion,
    int? confidenceScore,
    DateTime? processedAt,
  }) {
    return ValidatedActivity(
      activity: activity ?? this.activity,
      status: status ?? this.status,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      validationReason:
          validationReason ?? this.validationReason,
      ruleEngineVersion:
          ruleEngineVersion ?? this.ruleEngineVersion,
      confidenceScore: _normalizeConfidence(
        confidenceScore ?? this.confidenceScore,
      ),
      processedAt: processedAt ?? this.processedAt,
    );
  }

  static int _normalizeConfidence(int confidence) {
    return confidence.clamp(0, 100);
  }
}