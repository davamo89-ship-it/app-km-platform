import 'package:flutter/material.dart';

import '../../../models/athletes/athlete_dashboard.dart';
import 'statistic_card.dart';

class StatisticsGrid extends StatelessWidget {
  const StatisticsGrid({
    super.key,
    required this.dashboard,
    required this.isLoading,
    required this.formatKilometers,
  });

  final AthleteDashboard dashboard;
  final bool isLoading;
  final String Function(double value) formatKilometers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatisticCard(
                icon: Icons.route_outlined,
                value: formatKilometers(dashboard.totalKilometers),
                unit: 'km',
                label: 'Kilómetros',
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticCard(
                icon: Icons.local_fire_department_outlined,
                value: dashboard.currentStreakDays.toString(),
                unit: dashboard.currentStreakDays == 1 ? 'día' : 'días',
                label: 'Racha actual',
                isLoading: isLoading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatisticCard(
                icon: Icons.flag_outlined,
                value: formatKilometers(dashboard.monthlyKilometers),
                unit: 'km',
                label: 'Este mes',
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticCard(
                icon: Icons.directions_run_outlined,
                value: dashboard.approvedActivities.toString(),
                unit: '',
                label: 'Actividades',
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }
}