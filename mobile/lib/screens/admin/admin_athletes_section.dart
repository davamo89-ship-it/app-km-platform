import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/admin/admin_athlete_item.dart';
import '../../services/admin/admin_backend_api_service.dart';
import '../../services/api/authenticated_api_client.dart';

class AdminAthletesSection extends StatefulWidget {
  const AdminAthletesSection({super.key});

  @override
  State<AdminAthletesSection> createState() =>
      _AdminAthletesSectionState();
}

class _AdminAthletesSectionState
    extends State<AdminAthletesSection> {
  final AdminBackendApiService _adminApi =
      AdminBackendApiService();
  final TextEditingController _searchController =
      TextEditingController();

  List<AdminAthleteItem> _athletes = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adminApi.dispose();
    super.dispose();
  }

  List<AdminAthleteItem> get _filteredAthletes {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return _athletes;
    }

    return _athletes.where((athlete) {
      final name = athlete.displayName.toLowerCase();
      final status = athlete.status.toLowerCase();
      final country =
          athlete.countryCode?.toLowerCase() ?? '';
      final sport =
          athlete.preferredSport?.toLowerCase() ?? '';
      final userId = athlete.userId.toLowerCase();

      return name.contains(query) ||
          status.contains(query) ||
          country.contains(query) ||
          sport.contains(query) ||
          userId.contains(query);
    }).toList();
  }

  Future<void> _loadAthletes({
    bool showSuccessMessage = false,
  }) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final athletes = await _adminApi.getAthletes();

      if (!mounted) {
        return;
      }

      setState(() {
        _athletes = athletes;
        _isLoading = false;
      });

      if (showSuccessMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Lista de atletas actualizada.',
              ),
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

    return 'No fue posible cargar los atletas.';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadAthletes(
        showSuccessMessage: true,
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          28,
        ),
        children: [
          const Text(
            'Atletas',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Consulta los atletas registrados y su estado actual.',
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
              hintText: 'Buscar atleta',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
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
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
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
              onRetry: _loadAthletes,
            )
          else ...[
            _CountCard(
              total: _athletes.length,
              visible: _filteredAthletes.length,
              filtering: _searchText.trim().isNotEmpty,
            ),
            const SizedBox(height: 14),
            if (_filteredAthletes.isEmpty)
              const _EmptyCard()
            else
              ..._filteredAthletes.map(
                (athlete) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _AthleteCard(
                    athlete: athlete,
                  ),
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
        ? '$visible de $total atletas'
        : '$total atletas registrados';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.groups_2_outlined,
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

class _AthleteCard extends StatelessWidget {
  const _AthleteCard({
    required this.athlete,
  });

  final AdminAthleteItem athlete;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColor(athlete.status);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            imageUrl: athlete.profileImageUrl,
            displayName: athlete.displayName,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        athlete.displayName,
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
                        color: statusColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(athlete.status),
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
                  icon: Icons.sports_outlined,
                  text: athlete.preferredSport == null ||
                          athlete.preferredSport!
                              .trim()
                              .isEmpty
                      ? 'Deporte no indicado'
                      : athlete.preferredSport!,
                ),
                const SizedBox(height: 5),
                _InfoLine(
                  icon: Icons.public_rounded,
                  text: athlete.countryCode == null ||
                          athlete.countryCode!
                              .trim()
                              .isEmpty
                      ? 'País no indicado'
                      : athlete.countryCode!,
                ),
                const SizedBox(height: 5),
                _InfoLine(
                  icon: Icons.calendar_month_outlined,
                  text:
                      'Registro: ${_formatDate(athlete.createdAtUtc)}',
                ),
                const SizedBox(height: 7),
                Text(
                  'Usuario: ${_shortId(athlete.userId)}',
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
        backgroundColor:
            AppColors.primary.withValues(alpha: 0.10),
        backgroundImage: NetworkImage(url),
      );
    }

    final initial = displayName.trim().isEmpty
        ? 'A'
        : displayName.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 27,
      backgroundColor:
          AppColors.primary.withValues(alpha: 0.10),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            color: Colors.black26,
            size: 52,
          ),
          SizedBox(height: 12),
          Text(
            'No se encontraron atletas',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pruebe con otro nombre, estado, país o deporte.',
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
      return value.trim().isEmpty
          ? 'Sin estado'
          : value;
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
