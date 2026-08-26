import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';
import 'statistic_card.dart';

class StatisticsGrid extends StatelessWidget {
  const StatisticsGrid({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.formatKilometers,
  });

  final DashboardSummary summary;
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
                value: formatKilometers(summary.totalKilometers),
                unit: 'km',
                label: 'Kilómetros',
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticCard(
                icon: Icons.local_fire_department_outlined,
                value: summary.currentStreakDays.toString(),
                unit: summary.currentStreakDays == 1 ? 'día' : 'días',
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
                value: formatKilometers(summary.monthlyKilometers),
                unit: '/ ${formatKilometers(summary.monthlyGoalKilometers)} km',
                label: 'Meta mensual',
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticCard(
                icon: Icons.directions_run_outlined,
                value: summary.approvedActivities.toString(),
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
