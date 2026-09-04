import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/admin/admin_merchant_item.dart';
import '../../services/admin/admin_backend_api_service.dart';
import '../../services/api/authenticated_api_client.dart';

class AdminMerchantsSection extends StatefulWidget {
  const AdminMerchantsSection({super.key});

  @override
  State<AdminMerchantsSection> createState() =>
      _AdminMerchantsSectionState();
}

class _AdminMerchantsSectionState extends State<AdminMerchantsSection> {
  final AdminBackendApiService _adminApi = AdminBackendApiService();
  final TextEditingController _searchController = TextEditingController();

  List<AdminMerchantItem> _merchants = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adminApi.dispose();
    super.dispose();
  }

  List<AdminMerchantItem> get _filteredMerchants {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return _merchants;
    }

    return _merchants.where((merchant) {
      final name = merchant.displayName.toLowerCase();
      final status = merchant.status.toLowerCase();
      final country = merchant.countryCode?.toLowerCase() ?? '';
      final userId = merchant.userId.toLowerCase();

      return name.contains(query) ||
          status.contains(query) ||
          country.contains(query) ||
          userId.contains(query);
    }).toList();
  }

  Future<void> _loadMerchants({
    bool showSuccessMessage = false,
  }) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final merchants = await _adminApi.getMerchants();

      if (!mounted) {
        return;
      }

      setState(() {
        _merchants = merchants;
        _isLoading = false;
      });

      if (showSuccessMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Lista de comercios actualizada.'),
            ),
          );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    if (error is AdminBackendApiException) {
      return error.message;
    }

    if (error is AuthenticatedApiException) {
      return error.message;
    }

    return 'No fue posible cargar los comercios.';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadMerchants(showSuccessMessage: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'Comercios',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Consulta los comercios registrados y su estado actual.',
            style: TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar comercio',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchText.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchText = '';
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const _LoadingCard()
          else if (_errorMessage != null)
            _ErrorCard(
              message: _errorMessage!,
              onRetry: _loadMerchants,
            )
          else ...[
            _CountCard(
              total: _merchants.length,
              visible: _filteredMerchants.length,
              filtering: _searchText.trim().isNotEmpty,
            ),
            const SizedBox(height: 14),
            if (_filteredMerchants.isEmpty)
              const _EmptyCard()
            else
              ..._filteredMerchants.map(
                (merchant) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MerchantCard(merchant: merchant),
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
        ? '$visible de $total comercios'
        : '$total comercios registrados';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_outlined,
            color: AppColors.primary,
          ),
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

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({
    required this.merchant,
  });

  final AdminMerchantItem merchant;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(merchant.status);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            imageUrl: merchant.profileImageUrl,
            displayName: merchant.displayName,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        merchant.displayName,
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
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(merchant.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.public_rounded,
                  text: merchant.countryCode == null ||
                          merchant.countryCode!.trim().isEmpty
                      ? 'País no indicado'
                      : merchant.countryCode!,
                ),
                const SizedBox(height: 5),
                _InfoLine(
                  icon: Icons.calendar_month_outlined,
                  text: 'Registro: ${_formatDate(merchant.createdAtUtc)}',
                ),
                const SizedBox(height: 7),
                Text(
                  'Usuario: ${_shortId(merchant.userId)}',
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageUrl,
    required this.displayName,
  });

  final String? imageUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 27,
        backgroundColor: AppColors.primary.withValues(alpha: 0.10),
        backgroundImage: NetworkImage(url),
      );
    }

    final initial = displayName.trim().isEmpty
        ? 'C'
        : displayName.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 27,
      backgroundColor: AppColors.primary.withValues(alpha: 0.10),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
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
          color: Colors.black38,
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
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
      child: const Center(
        child: CircularProgressIndicator(),
      ),
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
          Icon(
            Icons.store_mall_directory_outlined,
            color: Colors.black26,
            size: 52,
          ),
          SizedBox(height: 12),
          Text(
            'No se encontraron comercios',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pruebe con otro nombre, estado o país.',
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

String _statusLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'active':
      return 'Activo';
    case 'suspended':
      return 'Suspendido';
    case 'disabled':
      return 'Deshabilitado';
    default:
      return value.trim().isEmpty ? 'Sin estado' : value;
  }
}

Color _statusColor(String value) {
  switch (value.trim().toLowerCase()) {
    case 'active':
      return AppColors.success;
    case 'suspended':
      return Colors.orange;
    case 'disabled':
      return AppColors.danger;
    default:
      return Colors.blueGrey;
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

String _shortId(String value) {
  final normalized = value.trim();

  if (normalized.length <= 8) {
    return normalized;
  }

  return '${normalized.substring(0, 8)}…';
}
