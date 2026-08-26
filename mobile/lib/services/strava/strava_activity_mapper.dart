import '../../models/strava_activity.dart';

class StravaActivityMapper {
  const StravaActivityMapper._();

  static StravaActivity fromJson(Map<String, dynamic> json) {
    final startDate = _readDateTime(json, 'start_date');

    final startDateLocal = _readDateTime(json, 'start_date_local');

    return StravaActivity(
      stravaId: _readRequiredString(json, 'id'),
      name: _readRequiredString(json, 'name'),
      sportType: _mapSportType(
        json['sport_type']?.toString() ?? json['type']?.toString(),
      ),
      distanceMeters: _readDouble(json, 'distance'),
      movingTimeSeconds: _readInt(json, 'moving_time'),
      elapsedTimeSeconds: _readInt(json, 'elapsed_time'),
      averageSpeed: _readDouble(json, 'average_speed'),
      maxSpeed: _readDouble(json, 'max_speed'),
      startDate: startDate,
      startDateLocal: startDateLocal,
      timezone: json['timezone']?.toString() ?? '',
      isManual: _readBool(json, 'manual'),
      isFlagged: _readBool(json, 'flagged'),
      hasGps: _hasGpsData(json),
      elevationGain: _readNullableDouble(json, 'total_elevation_gain'),
      averageHeartRate: _readNullableDouble(json, 'average_heartrate'),
      maxHeartRate: _readNullableDouble(json, 'max_heartrate'),
      deviceName: json['device_name']?.toString(),
    );
  }

  static SportType _mapSportType(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'run':
      case 'trailrun':
      case 'virtualrun':
        return SportType.running;

      case 'walk':
      case 'hike':
        return SportType.walking;

      case 'ride':
      case 'mountainbikeride':
      case 'gravelride':
      case 'virtualride':
      case 'ebikeride':
      case 'emountainbikeride':
        return SportType.cycling;

      case 'swim':
        return SportType.swimming;

      case 'weighttraining':
      case 'workout':
      case 'crossfit':
        return SportType.gym;

      default:
        return SportType.unknown;
    }
  }

  static bool _hasGpsData(Map<String, dynamic> json) {
    final startCoordinates = json['start_latlng'];
    final endCoordinates = json['end_latlng'];

    return _containsCoordinates(startCoordinates) ||
        _containsCoordinates(endCoordinates);
  }

  static bool _containsCoordinates(dynamic value) {
    return value is List &&
        value.length >= 2 &&
        value[0] != null &&
        value[1] != null;
  }

  static String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key]?.toString();

    if (value == null || value.trim().isEmpty) {
      throw FormatException('El campo obligatorio "$key" no es válido.');
    }

    return value;
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _readNullableDouble(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static bool _readBool(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final value = json[key]?.toString();

    if (value == null || value.isEmpty) {
      throw FormatException('El campo de fecha "$key" no existe.');
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      throw FormatException('El campo "$key" no contiene una fecha válida.');
    }

    return parsed;
  }
}
