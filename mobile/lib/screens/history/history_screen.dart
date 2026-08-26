import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum HistoryMovementType {
  all,
  earned,
  pending,
  adjustment,
}

class HistoryMovement {
  const HistoryMovement({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.points,
    required this.distance,
    required this.duration,
    required this.status,
    required this.source,
    required this.icon,
    required this.type,
  });

  final String title;
  final String subtitle;
  final String date;
  final int points;
  final String distance;
  final String duration;
  final String status;
  final String source;
  final IconData icon;
  final HistoryMovementType type;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryMovementType _selectedFilter = HistoryMovementType.all;

  final List<HistoryMovement> _movements = const [
    HistoryMovement(
      title: 'Carrera matutina',
      subtitle: 'Actividad validada',
      date: '17 de julio de 2026',
      points: 84,
      distance: '8.4 km',
      duration: '48 min',
      status: 'Validada',
      source: 'Strava',
      icon: Icons.directions_run_rounded,
      type: HistoryMovementType.earned,
    ),
    HistoryMovement(
      title: 'Ruta Lago Arenal',
      subtitle: 'Actividad validada',
      date: '15 de julio de 2026',
      points: 74,
      distance: '24.7 km',
      duration: '1 h 32 min',
      status: 'Validada',
      source: 'Strava',
      icon: Icons.directions_bike_rounded,
      type: HistoryMovementType.earned,
    ),
    HistoryMovement(
      title: 'Caminata vespertina',
      subtitle: 'Actividad validada',
      date: '13 de julio de 2026',
      points: 34,
      distance: '3.4 km',
      duration: '41 min',
      status: 'Validada',
      source: 'Strava',
      icon: Icons.directions_walk_rounded,
      type: HistoryMovementType.earned,
    ),
    HistoryMovement(
      title: 'Carrera de recuperación',
      subtitle: 'Actividad en revisión',
      date: '11 de julio de 2026',
      points: 0,
      distance: '5.8 km',
      duration: '36 min',
      status: 'Pendiente',
      source: 'Strava',
      icon: Icons.hourglass_top_rounded,
      type: HistoryMovementType.pending,
    ),
    HistoryMovement(
      title: 'Ajuste de puntos',
      subtitle: 'Corrección administrativa',
      date: '8 de julio de 2026',
      points: 50,
      distance: 'No aplica',
      duration: 'No aplica',
      status: 'Aplicado',
      source: 'Administración',
      icon: Icons.tune_rounded,
      type: HistoryMovementType.adjustment,
    ),
    HistoryMovement(
      title: 'Carrera urbana',
      subtitle: 'Actividad validada',
      date: '28 de junio de 2026',
      points: 62,
      distance: '6.2 km',
      duration: '39 min',
      status: 'Validada',
      source: 'Strava',
      icon: Icons.directions_run_rounded,
      type: HistoryMovementType.earned,
    ),
  ];

  List<HistoryMovement> get _filteredMovements {
    if (_selectedFilter == HistoryMovementType.all) {
      return _movements;
    }

    return _movements
        .where(
          (movement) => movement.type == _selectedFilter,
        )
        .toList();
  }

  Future<void> _refreshHistory() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Historial actualizado correctamente.',
        ),
      ),
    );
  }

  void _showMovementDetails(
    HistoryMovement movement,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MovementDetailsSheet(
          movement: movement,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial'),
        centerTitle: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Información',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      'Sobre el historial',
                    ),
                    content: const Text(
                      'Aquí puedes consultar los puntos obtenidos, '
                      'las actividades pendientes y los ajustes realizados.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Entendido'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.info_outline_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            28,
          ),
          children: [
            const _BalanceCard(),
            const SizedBox(height: 22),
            const Text(
              'Resumen',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.route_outlined,
                    value: '192.5',
                    label: 'Kilómetros',
                    unit: 'km',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.directions_run_outlined,
                    value: '24',
                    label: 'Actividades',
                    unit: '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.stars_outlined,
                    value: '1,920',
                    label: 'Puntos obtenidos',
                    unit: '',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.hourglass_top_outlined,
                    value: '1',
                    label: 'Pendiente',
                    unit: '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Movimientos',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _HistoryFilters(
              selectedFilter: _selectedFilter,
              onFilterSelected: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
            const SizedBox(height: 18),
            if (_filteredMovements.isEmpty)
              const _EmptyHistory()
            else
              ..._filteredMovements.map(
                (movement) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _MovementCard(
                      movement: movement,
                      onTap: () {
                        _showMovementDetails(movement);
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Saldo actual',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '2,350',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'KM Points',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                '+304 puntos este mes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.unit,
  });

  final IconData icon;
  final String value;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 25,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 2,
                  ),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final HistoryMovementType selectedFilter;
  final ValueChanged<HistoryMovementType>
      onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            isSelected:
                selectedFilter == HistoryMovementType.all,
            onTap: () {
              onFilterSelected(
                HistoryMovementType.all,
              );
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Ganados',
            isSelected:
                selectedFilter == HistoryMovementType.earned,
            onTap: () {
              onFilterSelected(
                HistoryMovementType.earned,
              );
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Pendientes',
            isSelected:
                selectedFilter == HistoryMovementType.pending,
            onTap: () {
              onFilterSelected(
                HistoryMovementType.pending,
              );
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Ajustes',
            isSelected:
                selectedFilter ==
                    HistoryMovementType.adjustment,
            onTap: () {
              onFilterSelected(
                HistoryMovementType.adjustment,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        onTap();
      },
      selectedColor:
          AppColors.primary.withValues(alpha: 0.14),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : Colors.black.withValues(alpha: 0.08),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.primary
            : Colors.black54,
        fontWeight: isSelected
            ? FontWeight.w700
            : FontWeight.w500,
      ),
      showCheckmark: false,
    );
  }
}

class _MovementCard extends StatelessWidget {
  const _MovementCard({
    required this.movement,
    required this.onTap,
  });

  final HistoryMovement movement;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (movement.type) {
      case HistoryMovementType.earned:
        return Colors.green;
      case HistoryMovementType.pending:
        return Colors.orange;
      case HistoryMovementType.adjustment:
        return Colors.blue;
      case HistoryMovementType.all:
        return AppColors.primary;
    }
  }

  String get _pointsText {
    if (movement.type == HistoryMovementType.pending) {
      return 'En revisión';
    }

    if (movement.points > 0) {
      return '+${movement.points} pts';
    }

    return '${movement.points} pts';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  movement.icon,
                  color: _statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movement.subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      movement.date,
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    _pointsText,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black38,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementDetailsSheet extends StatelessWidget {
  const _MovementDetailsSheet({
    required this.movement,
  });

  final HistoryMovement movement;

  Color get _statusColor {
    switch (movement.type) {
      case HistoryMovementType.earned:
        return Colors.green;
      case HistoryMovementType.pending:
        return Colors.orange;
      case HistoryMovementType.adjustment:
        return Colors.blue;
      case HistoryMovementType.all:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        12,
        24,
        30,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: _statusColor.withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                movement.icon,
                color: _statusColor,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              movement.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              movement.date,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Distancia',
                    value: movement.distance,
                  ),
                  const Divider(height: 26),
                  _DetailRow(
                    label: 'Duración',
                    value: movement.duration,
                  ),
                  const Divider(height: 26),
                  _DetailRow(
                    label: 'Puntos',
                    value: movement.type ==
                            HistoryMovementType.pending
                        ? 'Pendientes'
                        : '${movement.points} puntos',
                  ),
                  const Divider(height: 26),
                  _DetailRow(
                    label: 'Estado',
                    value: movement.status,
                    valueColor: _statusColor,
                  ),
                  const Divider(height: 26),
                  _DetailRow(
                    label: 'Origen',
                    value: movement.source,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: Colors.black26,
            size: 54,
          ),
          SizedBox(height: 14),
          Text(
            'No hay movimientos',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'No encontramos registros para el filtro seleccionado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black45,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}