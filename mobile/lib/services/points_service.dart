import '../core/config/app_rules.dart';
import '../models/strava_activity.dart';
import '../models/validated_activity.dart';

class PointsService {
  const PointsService();

  ValidatedActivity assignPoints(
    ValidatedActivity validatedActivity,
  ) {
    if (!validatedActivity.canGeneratePoints) {
      return validatedActivity.copyWith(
        pointsAwarded: 0,
      );
    }

    final points = _calculatePoints(
      validatedActivity.activity,
    );

    return validatedActivity.copyWith(
      pointsAwarded: points,
    );
  }

  int calculatePoints(
    ValidatedActivity validatedActivity,
  ) {
    if (!validatedActivity.canGeneratePoints) {
      return 0;
    }

    return _calculatePoints(
      validatedActivity.activity,
    );
  }

  int _calculatePoints(
    StravaActivity activity,
  ) {
    switch (activity.sportType) {
      case SportType.running:
        return _calculateDistancePoints(
          distanceKm: activity.distanceKm,
          pointsPerKm: AppRules.runningPointsPerKm,
        );

      case SportType.walking:
        return _calculateDistancePoints(
          distanceKm: activity.distanceKm,
          pointsPerKm: AppRules.walkingPointsPerKm,
        );

      case SportType.cycling:
        return _calculateDistancePoints(
          distanceKm: activity.distanceKm,
          pointsPerKm: AppRules.cyclingPointsPerKm,
        );

      case SportType.swimming:
        return _calculateDistancePoints(
          distanceKm: activity.distanceKm,
          pointsPerKm: AppRules.swimmingPointsPerKm,
        );

      case SportType.gym:
        return _calculateGymPoints(
          movingMinutes: activity.movingMinutes,
        );

      case SportType.unknown:
        return 0;
    }
  }

  int _calculateDistancePoints({
    required double distanceKm,
    required int pointsPerKm,
  }) {
    final points = distanceKm * pointsPerKm;

    return points.floor();
  }

  int _calculateGymPoints({
    required double movingMinutes,
  }) {
    final points =
        movingMinutes * AppRules.gymPointsPerMinute;

    return points.floor();
  }
}