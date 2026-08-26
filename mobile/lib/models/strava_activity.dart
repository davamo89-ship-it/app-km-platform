enum SportType { running, walking, cycling, swimming, gym, unknown }

extension SportTypeExtension on SportType {
  String get displayName {
    switch (this) {
      case SportType.running:
        return 'correr';

      case SportType.walking:
        return 'caminar';

      case SportType.cycling:
        return 'ciclismo';

      case SportType.swimming:
        return 'natación';

      case SportType.gym:
        return 'gimnasio';

      case SportType.unknown:
        return 'actividad desconocida';
    }
  }
}

class StravaActivity {
  const StravaActivity({
    required this.stravaId,
    required this.name,
    required this.sportType,
    required this.distanceMeters,
    required this.movingTimeSeconds,
    required this.elapsedTimeSeconds,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.startDate,
    required this.startDateLocal,
    required this.timezone,
    required this.isManual,
    required this.isFlagged,
    required this.hasGps,
    this.elevationGain,
    this.averageHeartRate,
    this.maxHeartRate,
    this.deviceName,
  });

  /// ID único de Strava
  final String stravaId;

  /// Nombre de la actividad
  final String name;

  /// Tipo de deporte
  final SportType sportType;

  /// Distancia en metros
  final double distanceMeters;

  /// Tiempo en movimiento
  final int movingTimeSeconds;

  /// Tiempo total
  final int elapsedTimeSeconds;

  /// Velocidad promedio (m/s)
  final double averageSpeed;

  /// Velocidad máxima (m/s)
  final double maxSpeed;

  /// Fecha UTC
  final DateTime startDate;

  /// Fecha local del atleta
  final DateTime startDateLocal;

  /// Zona horaria
  final String timezone;

  /// Creada manualmente
  final bool isManual;

  /// Marcada por Strava
  final bool isFlagged;

  /// Posee información GPS
  final bool hasGps;

  /// Elevación acumulada
  final double? elevationGain;

  /// FC promedio
  final double? averageHeartRate;

  /// FC máxima
  final double? maxHeartRate;

  /// Dispositivo utilizado
  final String? deviceName;

  //-------------------------
  // Getters útiles
  //-------------------------

  double get distanceKm => distanceMeters / 1000;

  double get movingMinutes => movingTimeSeconds / 60;

  double get elapsedMinutes => elapsedTimeSeconds / 60;

  double get averageSpeedKmH => averageSpeed * 3.6;

  double get maxSpeedKmH => maxSpeed * 3.6;
}
