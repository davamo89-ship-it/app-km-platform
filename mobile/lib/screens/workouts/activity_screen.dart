import 'package:flutter/material.dart';

import '../../core/app_dependencies.dart';
import '../../core/theme/app_colors.dart';
import '../../models/strava_sync_result.dart';
import '../../services/strava/strava_connection_controller.dart';
import '../../services/strava/strava_oauth_launcher.dart';
import '../../services/strava/strava_sync_controller.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  static const String _userId = 'local-user';

  late final StravaSyncController _syncController;
  late final StravaConnectionController _connectionController;
  late final StravaOAuthLauncher _oauthLauncher;

  String _selectedFilter = 'Todas';

  final List<ActivityData> _activities = const [
    ActivityData(
      title: 'Carrera matutina',
      sport: 'Carrera',
      date: 'Hoy • 6:15 a. m.',
      distance: 8.4,
      duration: '48 min',
      points: 84,
      icon: Icons.directions_run_rounded,
      status: ActivityStatus.approved,
    ),
    ActivityData(
      title: 'Ruta alrededor del lago',
      sport: 'Ciclismo',
      date: 'Ayer • 4:40 p. m.',
      distance: 24.6,
      duration: '1 h 18 min',
      points: 74,
      icon: Icons.directions_bike_rounded,
      status: ActivityStatus.approved,
    ),
    ActivityData(
      title: 'Caminata vespertina',
      sport: 'Caminata',
      date: '16 jul • 5:20 p. m.',
      distance: 4.2,
      duration: '52 min',
      points: 34,
      icon: Icons.directions_walk_rounded,
      status: ActivityStatus.approved,
    ),
    ActivityData(
      title: 'Actividad manual',
      sport: 'Carrera',
      date: '14 jul • 7:10 a. m.',
      distance: 10,
      duration: '58 min',
      points: 0,
      icon: Icons.directions_run_rounded,
      status: ActivityStatus.review,
    ),
  ];

  @override
  void initState() {
    super.initState();

    final dependencies = AppDependencies.instance;

    _syncController = dependencies.stravaSyncController;
    _connectionController = dependencies.stravaConnectionController;
    _oauthLauncher = dependencies.stravaOAuthLauncher;
  }

  List<ActivityData> get _filteredActivities {
    if (_selectedFilter == 'Todas') {
      return _activities;
    }

    return _activities
        .where((activity) => activity.sport == _selectedFilter)
        .toList();
  }

  Future<void> _connectStrava() async {
    try {
      final authorizationUri = _connectionController.beginAuthorization();

      await _oauthLauncher.openAuthorizationUri(authorizationUri);
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message.toString()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StravaOAuthLauncherException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No fue posible iniciar la conexión con Strava.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _disconnectStrava() async {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Desconectar Strava'),
          content: const Text(
            '¿Deseas desconectar la cuenta de Strava de App KM?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Desconectar'),
            ),
          ],
        );
      },
    );

    if (shouldDisconnect != true) {
      return;
    }

    await _connectionController.disconnect();
    _syncController.clearResult();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La cuenta de Strava fue desconectada.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _synchronizeActivities() async {
    if (_syncController.isSynchronizing) {
      return;
    }

    if (!_connectionController.isConnected) {
      await _connectStrava();
      return;
    }

    final result = await _syncController.synchronizeToday(userId: _userId);

    if (!mounted) {
      return;
    }

    if (result != null) {
      await _showSyncSummary(result);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _syncController.errorMessage ??
              'No fue posible sincronizar las actividades.',
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSyncSummary(StravaSyncResult result) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.sync_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(child: Text('Sincronización completada')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SyncSummaryRow(
                label: 'Actividades aprobadas',
                value: result.approvedCount.toString(),
              ),
              _SyncSummaryRow(
                label: 'Actividades rechazadas',
                value: result.rejectedCount.toString(),
              ),
              _SyncSummaryRow(
                label: 'Puntos obtenidos',
                value: '+${result.totalPointsAwarded}',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshActivities() async {
    if (_connectionController.isConnected) {
      await _synchronizeActivities();
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conecta Strava para actualizar tus actividades.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showActivityDetail(ActivityData activity) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SportIcon(icon: activity.icon, status: activity.status),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activity.date,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(label: 'Deporte', value: activity.sport),
              _DetailRow(label: 'Distancia', value: '${activity.distance} km'),
              _DetailRow(label: 'Duración', value: activity.duration),
              _DetailRow(
                label: 'Puntos obtenidos',
                value: activity.points > 0
                    ? '+${activity.points} puntos'
                    : 'Pendiente',
              ),
              _DetailRow(
                label: 'Estado',
                value: activity.status == ActivityStatus.approved
                    ? 'Actividad aprobada'
                    : 'En revisión',
              ),
              const SizedBox(height: 20),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_syncController, _connectionController]),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Mis actividades'),
            actions: [
              IconButton(
                tooltip: _connectionController.isConnected
                    ? 'Sincronizar'
                    : 'Conectar Strava',
                onPressed: _syncController.isSynchronizing
                    ? null
                    : _synchronizeActivities,
                icon: _syncController.isSynchronizing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshActivities,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _StravaSyncCard(
                        syncController: _syncController,
                        connectionController: _connectionController,
                        onConnect: _connectStrava,
                        onDisconnect: _disconnectStrava,
                        onSynchronize: _synchronizeActivities,
                      ),
                      const SizedBox(height: 22),
                      const _ActivitySummary(),
                      const SizedBox(height: 22),
                      const Text(
                        'Filtrar actividades',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActivityFilters(
                        selectedFilter: _selectedFilter,
                        onSelected: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Actividades recientes',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${_filteredActivities.length} registros',
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_filteredActivities.isEmpty)
                        const _EmptyActivities()
                      else
                        ..._filteredActivities.map(
                          (activity) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ActivityCard(
                              activity: activity,
                              onPressed: () {
                                _showActivityDetail(activity);
                              },
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StravaSyncCard extends StatelessWidget {
  const _StravaSyncCard({
    required this.syncController,
    required this.connectionController,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSynchronize,
  });

  final StravaSyncController syncController;
  final StravaConnectionController connectionController;

  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;
  final Future<void> Function() onSynchronize;

  @override
  Widget build(BuildContext context) {
    final result = syncController.lastResult;
    final athlete = connectionController.athlete;
    final isConnected = connectionController.isConnected;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: connectionController.hasError || syncController.hasError
              ? Colors.red.withValues(alpha: 0.25)
              : AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isConnected ? Icons.check_circle_rounded : Icons.link_rounded,
                  color: isConnected ? AppColors.primary : Colors.orange,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected
                          ? 'Strava conectado'
                          : 'Conecta tu cuenta de Strava',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isConnected
                          ? athlete?.fullName ?? 'Cuenta autorizada'
                          : 'Autoriza App KM para descargar tus actividades.',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConnected)
                PopupMenuButton<String>(
                  tooltip: 'Opciones de Strava',
                  onSelected: (value) {
                    if (value == 'disconnect') {
                      onDisconnect();
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'disconnect',
                        child: Text('Desconectar cuenta'),
                      ),
                    ];
                  },
                ),
            ],
          ),
          if (connectionController.isChecking) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text(
              'Verificando conexión con Strava...',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ] else if (connectionController.isAuthorizing) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text(
              'Completa la autorización en Strava y regresa a App KM.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ] else if (connectionController.hasError) ...[
            const SizedBox(height: 16),
            Text(
              connectionController.errorMessage ??
                  'No fue posible conectar Strava.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (isConnected && syncController.isSynchronizing) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(),
            const SizedBox(height: 9),
            const Text(
              'Sincronizando actividades...',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ] else if (isConnected && syncController.hasError) ...[
            const SizedBox(height: 16),
            Text(
              syncController.errorMessage ?? 'No fue posible sincronizar.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (isConnected && result != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _SyncCardValue(
                  label: 'Aprobadas',
                  value: result.approvedCount.toString(),
                ),
                _SyncCardValue(
                  label: 'Rechazadas',
                  value: result.rejectedCount.toString(),
                ),
                _SyncCardValue(
                  label: 'Puntos',
                  value: '+${result.totalPointsAwarded}',
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isConnected
                ? OutlinedButton.icon(
                    onPressed: syncController.isSynchronizing
                        ? null
                        : onSynchronize,
                    icon: syncController.isSynchronizing
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(
                      syncController.isSynchronizing
                          ? 'Sincronizando...'
                          : 'Sincronizar ahora',
                    ),
                  )
                : FilledButton.icon(
                    onPressed: connectionController.isAuthorizing
                        ? null
                        : onConnect,
                    icon: const Icon(Icons.link_rounded),
                    label: Text(
                      connectionController.isAuthorizing
                          ? 'Esperando autorización...'
                          : 'Conectar con Strava',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SyncCardValue extends StatelessWidget {
  const _SyncCardValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SyncSummaryRow extends StatelessWidget {
  const _SyncSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de julio',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 5),
          Text(
            '47.2 km',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  icon: Icons.calendar_today_outlined,
                  value: '4',
                  label: 'Actividades',
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  icon: Icons.schedule_outlined,
                  value: '3 h 56 min',
                  label: 'Tiempo',
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  icon: Icons.stars_outlined,
                  value: '192',
                  label: 'Puntos',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 21),
        const SizedBox(height: 7),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

class _ActivityFilters extends StatelessWidget {
  const _ActivityFilters({
    required this.selectedFilter,
    required this.onSelected,
  });

  final String selectedFilter;
  final ValueChanged<String> onSelected;

  static const filters = ['Todas', 'Carrera', 'Caminata', 'Ciclismo'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              label: Text(filter),
              selected: selectedFilter == filter,
              onSelected: (_) {
                onSelected(filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onPressed});

  final ActivityData activity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isApproved = activity.status == ActivityStatus.approved;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(21),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              _SportIcon(icon: activity.icon, status: activity.status),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.date,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _ActivityInfo(
                          icon: Icons.route_outlined,
                          text: '${activity.distance} km',
                        ),
                        _ActivityInfo(
                          icon: Icons.schedule_outlined,
                          text: activity.duration,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isApproved ? '+${activity.points}' : 'Revisión',
                    style: TextStyle(
                      color: isApproved ? AppColors.primary : Colors.orange,
                      fontSize: isApproved ? 18 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isApproved)
                    const Text(
                      'puntos',
                      style: TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                  const SizedBox(height: 12),
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

class _SportIcon extends StatelessWidget {
  const _SportIcon({required this.icon, required this.status});

  final IconData icon;
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final isApproved = status == ActivityStatus.approved;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: isApproved
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(
        icon,
        color: isApproved ? AppColors.primary : Colors.orange,
        size: 28,
      ),
    );
  }
}

class _ActivityInfo extends StatelessWidget {
  const _ActivityInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.black45, size: 15),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivities extends StatelessWidget {
  const _EmptyActivities();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_outlined, color: Colors.black38, size: 52),
          SizedBox(height: 12),
          Text(
            'No encontramos actividades',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

enum ActivityStatus { approved, review }

class ActivityData {
  const ActivityData({
    required this.title,
    required this.sport,
    required this.date,
    required this.distance,
    required this.duration,
    required this.points,
    required this.icon,
    required this.status,
  });

  final String title;
  final String sport;
  final String date;
  final double distance;
  final String duration;
  final int points;
  final IconData icon;
  final ActivityStatus status;
}
