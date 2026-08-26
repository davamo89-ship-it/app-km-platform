import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/validated_activity.dart';
import 'activity_detail.dart';
import 'activity_icon.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.activity,
    required this.isLoading,
  });

  final ValidatedActivity? activity;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final recentActivity = activity;

    if (recentActivity == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.directions_run_outlined,
              size: 38,
              color: Colors.black38,
            ),
            SizedBox(height: 10),
            Text(
              'Todavía no hay actividades sincronizadas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Registra una actividad en Strava y vuelve a sincronizar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    final stravaActivity = recentActivity.activity;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          ActivityIcon(sportType: stravaActivity.sportType),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stravaActivity.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDate(stravaActivity.startDateLocal),
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ActivityDetail(
                      icon: Icons.route_outlined,
                      text:
                          '${stravaActivity.distanceKm.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 14),
                    ActivityDetail(
                      icon: Icons.schedule_outlined,
                      text: '${stravaActivity.movingMinutes.round()} min',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${recentActivity.pointsAwarded}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'puntos',
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final now = DateTime.now();
    final date = DateTime(value.year, value.month, value.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final dayLabel = date == today
        ? 'Hoy'
        : date == yesterday
        ? 'Ayer'
        : '${value.day.toString().padLeft(2, '0')}/'
              '${value.month.toString().padLeft(2, '0')}/'
              '${value.year}';

    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'a. m.' : 'p. m.';

    return '$dayLabel • $hour:$minute $period';
  }
}
