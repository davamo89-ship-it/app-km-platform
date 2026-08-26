import '../models/strava_activity.dart';
import '../models/validated_activity.dart';

abstract class ActivityRepository {
  const ActivityRepository();

  /// Guarda el resultado completo del procesamiento de una actividad.
  Future<void> saveValidatedActivity(ValidatedActivity activity);

  /// Busca una actividad previamente procesada por su ID de Strava.
  Future<ValidatedActivity?> findByStravaId({
    required String userId,
    required String stravaId,
  });

  /// Obtiene todas las actividades ya procesadas del usuario.
  Future<List<ValidatedActivity>> getProcessedActivities({
    required String userId,
  });

  /// Obtiene las actividades registradas durante una fecha determinada.
  Future<List<StravaActivity>> getActivitiesByDate({
    required String userId,
    required DateTime date,
  });

  /// Obtiene las actividades registradas hoy.
  Future<List<StravaActivity>> getTodayActivities({required String userId});

  /// Determina si una actividad ya fue procesada anteriormente.
  Future<bool> existsByStravaId({
    required String userId,
    required String stravaId,
  });
}
