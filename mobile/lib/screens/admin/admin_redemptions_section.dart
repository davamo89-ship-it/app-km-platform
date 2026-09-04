import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/admin/admin_redemption_item.dart';
import '../../services/admin/admin_backend_api_service.dart';
import '../../services/api/authenticated_api_client.dart';

class AdminRedemptionsSection extends StatefulWidget {
  const AdminRedemptionsSection({super.key});

  @override
  State<AdminRedemptionsSection> createState() =>
      _AdminRedemptionsSectionState();
}

class _AdminRedemptionsSectionState extends State<AdminRedemptionsSection> {
  final AdminBackendApiService _adminApi = AdminBackendApiService();
  final TextEditingController _searchController = TextEditingController();

  List<AdminRedemptionItem> _items = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchText = '';
  String _statusFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adminApi.dispose();
    super.dispose();
  }

  List<AdminRedemptionItem> get _filtered {
    final query = _searchText.trim().toLowerCase();

    return _items.where((item) {
      final matchesStatus = _statusFilter == 'Todos' ||
          _statusLabel(item.status) == _statusFilter;
      final matchesQuery = query.isEmpty ||
          item.code.toLowerCase().contains(query) ||
          item.athleteDisplayName.toLowerCase().contains(query) ||
          (item.merchantName ?? '').toLowerCase().contains(query) ||
          item.status.toLowerCase().contains(query);

      return matchesStatus && matchesQuery;
    }).toList();
  }

  Future<void> _load({bool showSuccessMessage = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final items = await _adminApi.getRedemptions();

      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
      });

      if (showSuccessMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Lista de canjes actualizada.')),
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
    return 'No fue posible cargar los canjes.';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _load(showSuccessMessage: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'Canjes',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Consulta el historial operativo de canjes y su estado actual.',
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchText = value),
            decoration: InputDecoration(
              hintText: 'Buscar por código, atleta o comercio',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchText = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Todos',
              'Pendiente',
              'Por confirmar',
              'Completado',
              'Cancelado',
              'Vencido',
            ].map((label) {
              return ChoiceChip(
                label: Text(label),
                selected: _statusFilter == label,
                onSelected: (_) => setState(() => _statusFilter = label),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const _LoadingCard()
          else if (_errorMessage != null)
            _ErrorCard(message: _errorMessage!, onRetry: _load)
          else ...[
            _CountCard(
              total: _items.length,
              visible: _filtered.length,
              filtering: _searchText.trim().isNotEmpty ||
                  _statusFilter != 'Todos',
            ),
            const SizedBox(height: 14),
            if (_filtered.isEmpty)
              const _EmptyCard()
            else
              ..._filtered.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RedemptionCard(item: item),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.total,
    required this.visible,
    required this.filtering,
  });

  final int total;
  final int visible;
  final bool filtering;

  @override
  Widget build(BuildContext context) {
    final text = filtering
        ? '$visible de $total canjes'
        : '$total canjes registrados';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  const _RedemptionCard({required this.item});

  final AdminRedemptionItem item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    final merchant = item.merchantName?.trim();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Código ${item.code}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(item.status),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.directions_run_rounded,
            text: item.athleteDisplayName,
          ),
          const SizedBox(height: 6),
          _InfoLine(
            icon: Icons.storefront_rounded,
            text: merchant == null || merchant.isEmpty
                ? 'Sin comercio asignado'
                : merchant,
          ),
          const SizedBox(height: 6),
          _InfoLine(
            icon: Icons.stars_rounded,
            text: '${item.points} puntos',
          ),
          const SizedBox(height: 6),
          _InfoLine(
            icon: Icons.calendar_month_outlined,
            text: 'Creado: ${_formatDateTime(item.createdAtUtc)}',
          ),
          if (item.completedAtUtc != null) ...[
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.check_circle_outline_rounded,
              text: 'Completado: ${_formatDateTime(item.completedAtUtc!)}',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.black38, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

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
          const Icon(Icons.cloud_off_outlined, color: Colors.black38, size: 46),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDark, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.black26, size: 52),
          SizedBox(height: 12),
          Text(
            'No se encontraron canjes',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pruebe con otro código, atleta, comercio o estado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, height: 1.4),
          ),
        ],
      ),
    );
  }
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

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
