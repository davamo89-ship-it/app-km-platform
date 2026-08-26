import 'package:flutter_test/flutter_test.dart';

import 'package:app_km_prototipo1/models/strava_activity.dart';
import 'package:app_km_prototipo1/services/strava/strava_activity_mapper.dart';

void main() {
  group('StravaActivityMapper', () {
    test('convierte una carrera de Strava correctamente', () {
      final json = <String, dynamic>{
        'id': 123456789,
        'name': 'Carrera matutina',
        'sport_type': 'Run',
        'distance': 5000.0,
        'moving_time': 1800,
        'elapsed_time': 1900,
        'average_speed': 2.7778,
        'max_speed': 4.5,
        'start_date': '2026-07-18T12:00:00Z',
        'start_date_local': '2026-07-18T06:00:00',
        'timezone': '(GMT-06:00) America/Costa_Rica',
        'manual': false,
        'flagged': false,
        'start_latlng': [10.3, -84.4],
        'end_latlng': [10.4, -84.5],
        'total_elevation_gain': 45.5,
        'average_heartrate': 145.2,
        'max_heartrate': 178.0,
        'device_name': 'Garmin',
      };

      final activity = StravaActivityMapper.fromJson(json);

      expect(activity.stravaId, '123456789');
      expect(activity.name, 'Carrera matutina');
      expect(activity.sportType, SportType.running);
      expect(activity.distanceMeters, 5000);
      expect(activity.distanceKm, 5);
      expect(activity.movingTimeSeconds, 1800);
      expect(activity.movingMinutes, 30);
      expect(activity.isManual, isFalse);
      expect(activity.isFlagged, isFalse);
      expect(activity.hasGps, isTrue);
      expect(activity.elevationGain, 45.5);
      expect(activity.averageHeartRate, 145.2);
      expect(activity.maxHeartRate, 178);
      expect(activity.deviceName, 'Garmin');
    });

    test('convierte WeightTraining en gimnasio', () {
      final activity = StravaActivityMapper.fromJson({
        'id': 'gym-001',
        'name': 'Pesas',
        'sport_type': 'WeightTraining',
        'distance': 0,
        'moving_time': 3600,
        'elapsed_time': 3900,
        'average_speed': 0,
        'max_speed': 0,
        'start_date': '2026-07-18T12:00:00Z',
        'start_date_local': '2026-07-18T06:00:00',
        'timezone': '(GMT-06:00) America/Costa_Rica',
        'manual': false,
        'flagged': false,
      });

      expect(activity.sportType, SportType.gym);
      expect(activity.movingMinutes, 60);
      expect(activity.hasGps, isFalse);
    });

    test('clasifica un deporte no soportado como unknown', () {
      final activity = StravaActivityMapper.fromJson({
        'id': 'sport-unknown',
        'name': 'Actividad de prueba',
        'sport_type': 'Kayaking',
        'distance': 3000,
        'moving_time': 1200,
        'elapsed_time': 1300,
        'average_speed': 2.5,
        'max_speed': 4,
        'start_date': '2026-07-18T12:00:00Z',
        'start_date_local': '2026-07-18T06:00:00',
        'timezone': '(GMT-06:00) America/Costa_Rica',
        'manual': false,
        'flagged': false,
      });

      expect(activity.sportType, SportType.unknown);
    });

    test('lanza FormatException cuando falta el ID', () {
      expect(
        () => StravaActivityMapper.fromJson({
          'name': 'Actividad sin ID',
          'sport_type': 'Run',
          'start_date': '2026-07-18T12:00:00Z',
          'start_date_local': '2026-07-18T06:00:00',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
