import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/merchants/merchant_latest_redemption.dart';
import '../../services/merchants/merchant_backend_api_service.dart';

class MerchantRedemptionsHistoryScreen extends StatefulWidget {
  const MerchantRedemptionsHistoryScreen({super.key});

  @override
  State<MerchantRedemptionsHistoryScreen> createState() =>
      _MerchantRedemptionsHistoryScreenState();
}

class _MerchantRedemptionsHistoryScreenState
    extends State<MerchantRedemptionsHistoryScreen> {
  final MerchantBackendApiService _merchantApi =
      MerchantBackendApiService();

  List<MerchantLatestRedemption> _items = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _merchantApi.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final items = await _merchantApi.getRedemptionHistory();

      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'No fue posible cargar el historial de canjes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial de canjes'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 120),
        children: const [
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
        children: [
          _MessageCard(
            icon: Icons.cloud_off_outlined,
            title: 'No pudimos cargar los canjes',
            message: _errorMessage!,
            actionLabel: 'Reintentar',
            onAction: _load,
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
        children: const [
          _MessageCard(
            icon: Icons.history_rounded,
            title: 'Todavía no hay canjes',
            message:
                'Los canjes procesados por este comercio aparecerán aquí.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const Text(
          'Canjes recientes',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Se muestran hasta los 20 canjes más recientes del comercio.',
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 18),
        ..._items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HistoryCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final MerchantLatestRedemption item;

  @override
  Widget build(BuildContext context) {
    final status = item.status.trim().toLowerCase();
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled' ||
        status == 'canceled' ||
        status == 'rejected';
    final isExpired = status == 'expired';

    final color = isCompleted
        ? Colors.green.shade700
        : isCancelled
            ? Colors.red.shade700
            : isExpired
                ? Colors.blueGrey
                : Colors.orange.shade800;

    final eventDate = (item.completedAtUtc ??
            item.merchantProposedAtUtc ??
            item.createdAtUtc)
        .toLocal();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.athleteDisplayName,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(item.status),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${item.points} KM Points',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _Detail(label: 'Código', value: item.code),
          const SizedBox(height: 6),
          _Detail(label: 'Fecha', value: _formatDate(eventDate)),
          if (isCancelled) ...[
            const SizedBox(height: 10),
            const Text(
              'Canje cancelado. No se descontaron puntos al atleta.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          Icon(icon, color: Colors.black38, size: 48),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

String _statusLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'pending':
      return 'Pendiente';
    case 'awaitingathleteconfirmation':
    case 'pendingathleteconfirmation':
    case 'merchantproposed':
      return 'Por confirmar';
    case 'completed':
      return 'Confirmado';
    case 'cancelled':
    case 'canceled':
    case 'rejected':
      return 'Cancelado';
    case 'expired':
      return 'Vencido';
    default:
      return value.isEmpty ? 'Sin estado' : value;
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? 'a. m.' : 'p. m.';

  return '$day/$month/$year • $hour12:$minute $period';
}
