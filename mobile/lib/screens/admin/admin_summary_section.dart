import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/admin/admin_redemption_item.dart';
import '../../services/admin/admin_backend_api_service.dart';
import '../../services/api/authenticated_api_client.dart';

class AdminSummarySection extends StatefulWidget {
  const AdminSummarySection({
    super.key,
    required this.email,
    required this.onOpenSection,
  });

  final String? email;
  final ValueChanged<int> onOpenSection;

  @override
  State<AdminSummarySection> createState() => _AdminSummarySectionState();
}

class _AdminSummarySectionState extends State<AdminSummarySection> {
  final AdminBackendApiService _adminApi = AdminBackendApiService();

  bool _isLoading = true;
  String? _errorMessage;

  int _athletes = 0;
  int _merchants = 0;
  List<AdminRedemptionItem> _redemptions = const [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _adminApi.dispose();
    super.dispose();
  }

  int _countStatus(String status) {
    final normalized = status.toLowerCase();

    return _redemptions.where((item) {
      final value = item.status.trim().toLowerCase();

      switch (normalized) {
        case 'pending':
          return value == 'pending';
        case 'awaiting':
          return value == 'awaitingathleteconfirmation' ||
              value == 'merchantproposed' ||
              value == 'pendingathleteconfirmation';
        case 'completed':
          return value == 'completed';
        case 'cancelled':
          return value == 'cancelled' ||
              value == 'canceled' ||
              value == 'rejected';
        case 'expired':
          return value == 'expired';
        default:
          return false;
      }
    }).length;
  }

  List<AdminRedemptionItem> get _pendingRedemptions {
    return _redemptions
        .where((item) => _isPendingStatus(item.status))
        .toList();
  }

  Future<void> _loadSummary({bool showSuccessMessage = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _adminApi.getAthletes(),
        _adminApi.getMerchants(),
        _adminApi.getRedemptions(),
      ]);

      if (!mounted) return;

      setState(() {
        _athletes = results[0].length;
        _merchants = results[1].length;
        _redemptions = results[2] as List<AdminRedemptionItem>;
        _isLoading = false;
      });

      if (showSuccessMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Resumen actualizado.')),
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

  String _friendlyError(Object error) {
    if (error is AdminBackendApiException) return error.message;
    if (error is AuthenticatedApiException) return error.message;
    return 'No fue posible cargar el resumen operativo.';
  }

  @override
  Widget build(BuildContext context) {
    final sessionEmail = widget.email?.trim();

    return RefreshIndicator(
      onRefresh: () => _loadSummary(showSuccessMessage: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
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
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen operativo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        sessionEmail == null || sessionEmail.isEmpty
                            ? 'Sesión administrativa activa'
                            : sessionEmail,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (_isLoading)
            const _LoadingCard()
          else if (_errorMessage != null)
            _ErrorCard(
              message: _errorMessage!,
              onRetry: _loadSummary,
            )
          else ...[
            const Text(
              'Indicadores',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.directions_run_rounded,
                    label: 'Atletas',
                    value: _athletes,
                    onTap: () => widget.onOpenSection(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.storefront_rounded,
                    label: 'Comercios',
                    value: _merchants,
                    onTap: () => widget.onOpenSection(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricCard(
              icon: Icons.qr_code_2_rounded,
              label: 'Canjes registrados',
              value: _redemptions.length,
              onTap: () => widget.onOpenSection(3),
            ),
            const SizedBox(height: 22),
            const Text(
              'Estado de canjes',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _StatusRow(
              label: 'Pendientes',
              value: _countStatus('pending'),
              icon: Icons.schedule_rounded,
              color: Colors.orange,
            ),
            const SizedBox(height: 9),
            _StatusRow(
              label: 'Por confirmar',
              value: _countStatus('awaiting'),
              icon: Icons.hourglass_top_rounded,
              color: Colors.orange,
            ),
            const SizedBox(height: 9),
            _StatusRow(
              label: 'Completados',
              value: _countStatus('completed'),
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
            const SizedBox(height: 9),
            _StatusRow(
              label: 'Cancelados',
              value: _countStatus('cancelled'),
              icon: Icons.cancel_outlined,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 9),
            _StatusRow(
              label: 'Vencidos',
              value: _countStatus('expired'),
              icon: Icons.timer_off_outlined,
              color: AppColors.danger,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Canjes pendientes',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onOpenSection(3),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_pendingRedemptions.isEmpty)
              const _NoPendingRedemptionsCard()
            else
              ..._pendingRedemptions.take(3).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PendingRedemptionCard(item: item),
                    ),
                  ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Canjes recientes',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onOpenSection(3),
                  child: const Text('Ver canjes'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_redemptions.isEmpty)
              const _NoRedemptionsCard()
            else
              ..._redemptions.take(3).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecentRedemptionCard(item: item),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final VoidCallback onTap;

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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRedemptionCard extends StatelessWidget {
  const _PendingRedemptionCard({required this.item});

  final AdminRedemptionItem item;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.athleteDisplayName,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.code} · ${item.points} puntos',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                _RedemptionInfoLine(
                  icon: Icons.calendar_month_outlined,
                  text: 'Iniciado: ${_formatDateTime(item.createdAtUtc)}',
                ),
                const SizedBox(height: 3),
                _RedemptionInfoLine(
                  icon: Icons.storefront_outlined,
                  text: 'Comercio: ${_merchantLabel(item.merchantName)}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(item.status),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRedemptionCard extends StatelessWidget {
  const _RecentRedemptionCard({required this.item});

  final AdminRedemptionItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _statusColor(item.status).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              color: _statusColor(item.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.athleteDisplayName,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.code} · ${item.points} puntos',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                _RedemptionInfoLine(
                  icon: Icons.calendar_month_outlined,
                  text: _formatDateTime(item.createdAtUtc),
                ),
                const SizedBox(height: 3),
                _RedemptionInfoLine(
                  icon: Icons.storefront_outlined,
                  text: 'Comercio: ${_merchantLabel(item.merchantName)}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _statusLabel(item.status),
            style: TextStyle(
              color: _statusColor(item.status),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RedemptionInfoLine extends StatelessWidget {
  const _RedemptionInfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.black45,
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoPendingRedemptionsCard extends StatelessWidget {
  const _NoPendingRedemptionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No hay canjes pendientes en este momento.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(child: CircularProgressIndicator()),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Colors.black38,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _NoRedemptionsCard extends StatelessWidget {
  const _NoRedemptionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.black38),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Todavía no hay canjes registrados.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}


bool _isPendingStatus(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
    case 'awaitingathleteconfirmation':
    case 'merchantproposed':
    case 'pendingathleteconfirmation':
      return true;
    default:
      return false;
  }
}

String _merchantLabel(String? merchantName) {
  final value = merchantName?.trim();

  if (value == null || value.isEmpty) {
    return 'Sin comercio asignado';
  }

  return value;
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/${local.year} $hour:$minute';
}

String _statusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return 'Pendiente';
    case 'awaitingathleteconfirmation':
    case 'merchantproposed':
    case 'pendingathleteconfirmation':
      return 'Por confirmar';
    case 'completed':
      return 'Completado';
    case 'cancelled':
    case 'canceled':
    case 'rejected':
      return 'Cancelado';
    case 'expired':
      return 'Vencido';
    default:
      return status.trim().isEmpty ? 'Sin estado' : status;
  }
}

Color _statusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
    case 'awaitingathleteconfirmation':
    case 'merchantproposed':
    case 'pendingathleteconfirmation':
      return Colors.orange;
    case 'completed':
      return AppColors.success;
    case 'cancelled':
    case 'canceled':
    case 'rejected':
      return Colors.blueGrey;
    case 'expired':
      return AppColors.danger;
    default:
      return AppColors.primary;
  }
}
