import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/strava_activity.dart';

class ActivityIcon extends StatelessWidget {
  const ActivityIcon({super.key, required this.sportType});

  final SportType sportType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(_iconForSport(sportType), color: AppColors.primary),
    );
  }

  IconData _iconForSport(SportType value) {
    switch (value) {
      case SportType.running:
        return Icons.directions_run_rounded;
      case SportType.walking:
        return Icons.directions_walk_rounded;
      case SportType.cycling:
        return Icons.directions_bike_rounded;
      case SportType.swimming:
        return Icons.pool_rounded;
      case SportType.gym:
        return Icons.fitness_center_rounded;
      case SportType.unknown:
        return Icons.sports_rounded;
    }
  }
}
