import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/points/point_history_item.dart';
import '../../models/points/upcoming_point_expiration.dart';
import '../../services/api/authenticated_api_client.dart';
import '../../services/points/points_backend_api_service.dart';
import '../redemptions/redemptions_screen.dart';

enum HistoryMovementType {
  all,
  earned,
  redeemed,
  expired,
  adjustment,
  other,
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final PointsBackendApiService _pointsApi =
      PointsBackendApiService();

  HistoryMovementType _selectedFilter =
      HistoryMovementType.all;

  List<PointHistoryItem> _movements = const [];
  List<UpcomingPointExpiration> _expirations = const [];

  int _balance = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _pointsApi.dispose();
    super.dispose();
  }

  List<PointHistoryItem> get _filteredMovements {
    if (_selectedFilter == HistoryMovementType.all) {
      return _movements;
    }

    return _movements
        .where(
          (movement) =>
              _movementType(movement) == _selectedFilter,
        )
        .toList();
  }

  double get _totalKilometers {
    return _movements.fold<double>(
      0,
      (total, movement) =>
          total + (movement.distanceKilometers ?? 0),
    );
  }

  int get _activityCount {
    return _movements
        .where(
          (movement) =>
              movement.athleteActivityId != null ||
              movement.stravaActivityId != null,
        )
        .length;
  }

  int get _earnedPoints {
    return _movements
        .where(
          (movement) =>
              _movementType(movement) ==
              HistoryMovementType.earned,
        )
        .fold<int>(
          0,
          (total, movement) =>
              total + movement.points.abs(),
        );
  }

  int get _pointsExpiringSoon {
    return _expirations
        .where((expiration) => expiration.shouldNotify)
        .fold<int>(
          0,
          (total, expiration) =>
              total + expiration.remainingPoints,
        );
  }

  Future<void> _loadHistory({
    bool showSuccessMessage = false,
  }) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final balanceFuture = _pointsApi.getBalance();
      final historyFuture = _pointsApi.getHistory();
      final expirationsFuture =
          _pointsApi.getExpirations();

      final balance = await balanceFuture;
      final history = await historyFuture;
      final expirations = await expirationsFuture;

      history.sort(
        (a, b) =>
            b.createdAtUtc.compareTo(a.createdAtUtc),
      );

      expirations.sort(
        (a, b) =>
            a.expiresAtUtc.compareTo(b.expiresAtUtc),
      );

      if (!mounted) return;

      setState(() {
        _balance = balance;
        _movements = history;
        _expirations = expirations;
        _isLoading = false;
      });

      if (showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Historial actualizado correctamente.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  Future<void> _refreshHistory() {
    return _loadHistory(
      showSuccessMessage: true,
    );
  }

  String _friendlyError(Object error) {
    if (error is PointsBackendApiException) {
      return error.message;
    }

    if (error is AuthenticatedApiException) {
      return error.message;
    }

    return 'No fue posible cargar el historial de puntos.';
  }

  HistoryMovementType _movementType(
    PointHistoryItem movement,
  ) {
    final type = movement.type.toLowerCase();

    if (type.contains('redeem') ||
        type.contains('canje')) {
      return HistoryMovementType.redeemed;
    }

    if (type.contains('expire') ||
        type.contains('venc')) {
      return HistoryMovementType.expired;
    }

    if (type.contains('adjust') ||
        type.contains('ajuste')) {
      return HistoryMovementType.adjustment;
    }

    if (type.contains('earn') ||
        type.contains('award') ||
        type.contains('credit') ||
        type.contains('activity') ||
        movement.points > 0) {
      return HistoryMovementType.earned;
    }

    return HistoryMovementType.other;
  }

  void _showMovementDetails(
    PointHistoryItem movement,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MovementDetailsSheet(
          movement: movement,
          movementType: _movementType(movement),
        );
      },
    );
  }

  Future<void> _openRedemptions() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            const RedemptionsScreen(),
      ),
    );

    if (!mounted) return;

    await _loadHistory();
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
          TextButton.icon(
            onPressed: _openRedemptions,
            icon: const Icon(
              Icons.qr_code_2_rounded,
              size: 20,
            ),
            label: const Text('Canjes'),
          ),
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
                      'Aquí puede consultar los movimientos '
                      'reales de KM Points registrados por '
                      'App KM.',
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          80,
          20,
          28,
        ),
        children: const [
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          80,
          20,
          28,
        ),
        children: [
          _ErrorCard(
            message: _errorMessage!,
            onRetry: _loadHistory,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        28,
      ),
      children: [
        _BalanceCard(
          balance: _balance,
        ),
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
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.route_outlined,
                value: _formatDistance(
                  _totalKilometers,
                ),
                label: 'Kilómetros',
                unit: 'km',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon:
                    Icons.directions_run_outlined,
                value: '$_activityCount',
                label: 'Actividades',
                unit: '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.stars_outlined,
                value: '$_earnedPoints',
                label: 'Puntos obtenidos',
                unit: '',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.schedule_outlined,
                value: '$_pointsExpiringSoon',
                label: 'Por vencer',
                unit: 'pts',
              ),
            ),
          ],
        ),
        if (_expirations.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ExpirationCard(
            expirations: _expirations,
          ),
        ],
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
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: _MovementCard(
                  movement: movement,
                  movementType:
                      _movementType(movement),
                  onTap: () {
                    _showMovementDetails(
                      movement,
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDistance(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
  });

  final int balance;

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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .account_balance_wallet_outlined,
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
          const SizedBox(height: 12),
          Text(
            '$balance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'KM Points',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
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
          color:
              Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 25,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
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
                  padding:
                      const EdgeInsets.only(
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

class _ExpirationCard extends StatelessWidget {
  const _ExpirationCard({
    required this.expirations,
  });

  final List<UpcomingPointExpiration>
      expirations;

  @override
  Widget build(BuildContext context) {
    final first = expirations.first;
    final notified = expirations
        .where((item) => item.shouldNotify)
        .toList();

    final expiration =
        notified.isNotEmpty ? notified.first : first;

    final text = expiration.shouldNotify
        ? '${expiration.remainingPoints} puntos '
            'vencen en ${expiration.daysRemaining} días.'
        : 'Próximo vencimiento: '
            '${expiration.remainingPoints} puntos '
            'en ${expiration.daysRemaining} días.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.event_busy_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textDark,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
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
                selectedFilter ==
                HistoryMovementType.all,
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
                selectedFilter ==
                HistoryMovementType.earned,
            onTap: () {
              onFilterSelected(
                HistoryMovementType.earned,
              );
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Canjeados',
            isSelected:
                selectedFilter ==
                HistoryMovementType.redeemed,
            onTap: () {
              onFilterSelected(
                HistoryMovementType.redeemed,
              );
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Vencidos',
            isSelected:
                selectedFilter ==
                HistoryMovementType.expired,
            onTap: () {
              onFilterSelected(
                HistoryMovementType.expired,
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
          AppColors.primary.withValues(
        alpha: 0.14,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : Colors.black.withValues(
                alpha: 0.08,
              ),
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
    required this.movementType,
    required this.onTap,
  });

  final PointHistoryItem movement;
  final HistoryMovementType movementType;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (movementType) {
      case HistoryMovementType.earned:
        return Colors.green;
      case HistoryMovementType.redeemed:
        return Colors.deepOrange;
      case HistoryMovementType.expired:
        return Colors.red;
      case HistoryMovementType.adjustment:
        return Colors.blue;
      case HistoryMovementType.other:
      case HistoryMovementType.all:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    final activity =
        movement.activityType?.toLowerCase() ?? '';

    if (activity.contains('run')) {
      return Icons.directions_run_rounded;
    }

    if (activity.contains('ride') ||
        activity.contains('cycl')) {
      return Icons.directions_bike_rounded;
    }

    if (activity.contains('walk') ||
        activity.contains('hike')) {
      return Icons.directions_walk_rounded;
    }

    if (activity.contains('swim')) {
      return Icons.pool_rounded;
    }

    switch (movementType) {
      case HistoryMovementType.earned:
        return Icons.stars_rounded;
      case HistoryMovementType.redeemed:
        return Icons.shopping_bag_outlined;
      case HistoryMovementType.expired:
        return Icons.event_busy_outlined;
      case HistoryMovementType.adjustment:
        return Icons.tune_rounded;
      case HistoryMovementType.other:
      case HistoryMovementType.all:
        return Icons.receipt_long_outlined;
    }
  }

  String get _title {
    if (movement.activityType != null &&
        movement.activityType!.trim().isNotEmpty) {
      return _activityLabel(
        movement.activityType!,
      );
    }

    switch (movementType) {
      case HistoryMovementType.earned:
        return 'Puntos obtenidos';
      case HistoryMovementType.redeemed:
        return 'Canje de puntos';
      case HistoryMovementType.expired:
        return 'Puntos vencidos';
      case HistoryMovementType.adjustment:
        return 'Ajuste de puntos';
      case HistoryMovementType.other:
      case HistoryMovementType.all:
        return _typeLabel(movement.type);
    }
  }

  String get _subtitle {
    if (movement.stravaActivityId != null) {
      return 'Actividad de Strava';
    }

    return _typeLabel(movement.type);
  }

  String get _pointsText {
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
        borderRadius:
            BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      _statusColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: Icon(
                  _icon,
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
                      _title,
                      style: const TextStyle(
                        color:
                            AppColors.textDark,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _formatDate(
                        movement.createdAtUtc,
                      ),
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
                      fontWeight:
                          FontWeight.bold,
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

class _MovementDetailsSheet
    extends StatelessWidget {
  const _MovementDetailsSheet({
    required this.movement,
    required this.movementType,
  });

  final PointHistoryItem movement;
  final HistoryMovementType movementType;

  Color get _statusColor {
    switch (movementType) {
      case HistoryMovementType.earned:
        return Colors.green;
      case HistoryMovementType.redeemed:
        return Colors.deepOrange;
      case HistoryMovementType.expired:
        return Colors.red;
      case HistoryMovementType.adjustment:
        return Colors.blue;
      case HistoryMovementType.other:
      case HistoryMovementType.all:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance =
        movement.distanceKilometers == null
            ? 'No aplica'
            : '${movement.distanceKilometers!.toStringAsFixed(2)} km';

    final expiration =
        movement.expiresAtUtc == null
            ? 'No aplica'
            : _formatDate(
                movement.expiresAtUtc!,
              );

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
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 22),
            Icon(
              Icons.receipt_long_rounded,
              color: _statusColor,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              _typeLabel(movement.type),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(
                movement.createdAtUtc,
              ),
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
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Puntos',
                    value:
                        '${movement.points} puntos',
                    valueColor: _statusColor,
                  ),
                  const Divider(height: 26),
                  _DetailRow(
                    label: 'Distancia',
                    value: distance,
                  ),
                  const Divider(height: 26),
                  _DetailRow(
                    label: 'Actividad',
                    value:
                        movement.activityType ==
                                null
                            ? 'No aplica'
                            : _activityLabel(
                                movement
                                    .activityType!,
                              ),
                  ),
                  const Divider(height: 26),
                  _DetailRow(
                    label: 'Vencimiento',
                    value: expiration,
                  ),
                  const Divider(height: 26),
                  _DetailRow(
                    label: 'Origen',
                    value:
                        movement.stravaActivityId ==
                                null
                            ? 'App KM'
                            : 'Strava',
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color:
                  valueColor ?? AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Colors.black38,
            size: 48,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
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
            'No encontramos registros para el '
            'filtro seleccionado.',
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

String _formatDate(DateTime date) {
  final local = date.toLocal();

  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  return '${local.day} de '
      '${months[local.month - 1]} de '
      '${local.year}';
}

String _typeLabel(String value) {
  final normalized = value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .trim();

  if (normalized.isEmpty) {
    return 'Movimiento de puntos';
  }

  final lower = normalized.toLowerCase();

  if (lower.contains('earn') ||
      lower.contains('award')) {
    return 'Puntos obtenidos';
  }

  if (lower.contains('redeem')) {
    return 'Canje de puntos';
  }

  if (lower.contains('expire')) {
    return 'Puntos vencidos';
  }

  if (lower.contains('adjust')) {
    return 'Ajuste de puntos';
  }

  return normalized[0].toUpperCase() +
      normalized.substring(1);
}

String _activityLabel(String value) {
  final lower = value.toLowerCase();

  if (lower.contains('run')) {
    return 'Carrera';
  }

  if (lower.contains('ride') ||
      lower.contains('cycl')) {
    return 'Ciclismo';
  }

  if (lower.contains('walk')) {
    return 'Caminata';
  }

  if (lower.contains('hike')) {
    return 'Senderismo';
  }

  if (lower.contains('swim')) {
    return 'Natación';
  }

  if (lower.contains('workout') ||
      lower.contains('weight') ||
      lower.contains('gym')) {
    return 'Gimnasio';
  }

  return value;
}
