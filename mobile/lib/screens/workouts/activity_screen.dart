import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/strava/strava_activity.dart';
import '../../models/strava/strava_sync_result.dart';
import '../../services/strava/strava_backend_api_service.dart';
import '../../services/strava/strava_oauth_launcher.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with WidgetsBindingObserver {
  static const int _historyDays = 30;

  final StravaBackendApiService _stravaApiService =
      StravaBackendApiService();

  final StravaOAuthLauncher _oauthLauncher =
      const StravaOAuthLauncher();

  List<StravaActivity> _activities = const [];

  String _selectedFilter = 'Todas';

  bool _isCheckingConnection = true;
  bool _isConnected = false;
  bool _isAuthorizing = false;
  bool _isSynchronizing = false;
  bool _isLoadingActivities = false;

  String? _connectionError;
  String? _activitiesError;
  String? _syncError;

  StravaSyncResult? _lastSyncResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stravaApiService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeScreen();
    }
  }

  Future<void> _initializeScreen() async {
    await _loadStravaStatus();

    if (_isConnected) {
      await _loadActivities();
    }
  }

  List<StravaActivity> get _filteredActivities {
    if (_selectedFilter == 'Todas') {
      return _activities;
    }

    return _activities.where((activity) {
      return _sportLabel(activity.sportType) == _selectedFilter;
    }).toList();
  }

  double get _totalKilometers {
    return _activities.fold<double>(
      0,
      (total, activity) =>
          total + activity.distanceKilometers,
    );
  }

  int get _totalMovingSeconds {
    return _activities.fold<int>(
      0,
      (total, activity) =>
          total + activity.movingTimeSeconds,
    );
  }

  Future<void> _loadStravaStatus() async {
    if (mounted) {
      setState(() {
        _isCheckingConnection = true;
        _connectionError = null;
      });
    }

    try {
      final status = await _stravaApiService.getStatus();

      if (!mounted) {
        return;
      }

      setState(() {
        _isConnected = status.connected;
        _isAuthorizing = false;
        _isCheckingConnection = false;
        _connectionError = null;

        if (!status.connected) {
          _activities = const [];
          _activitiesError = null;
        }
      });
    } on StravaBackendApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingConnection = false;
        _isAuthorizing = false;
        _connectionError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingConnection = false;
        _isAuthorizing = false;
        _connectionError =
            'No fue posible verificar la conexión con Strava.';
      });
    }
  }

  Future<void> _loadActivities() async {
    if (!_isConnected) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingActivities = true;
        _activitiesError = null;
      });
    }

    final now = DateTime.now();
    final after = now.subtract(
      const Duration(days: _historyDays),
    );

    try {
      final activities =
          await _stravaApiService.getActivities(
        after: after,
        before: now.add(const Duration(minutes: 5)),
        page: 1,
        perPage: 100,
      );

      activities.sort(
        (a, b) =>
            b.startDateLocal.compareTo(a.startDateLocal),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activities = activities;
        _isLoadingActivities = false;
        _activitiesError = null;
      });
    } on StravaBackendApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingActivities = false;
        _activitiesError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingActivities = false;
        _activitiesError =
            'No fue posible cargar las actividades de Strava.';
      });
    }
  }

  Future<void> _connectStrava() async {
    if (_isAuthorizing) {
      return;
    }

    setState(() {
      _isAuthorizing = true;
      _connectionError = null;
    });

    try {
      final response =
          await _stravaApiService.getConnectUrl();

      final authorizationUri =
          Uri.parse(response.authorizationUrl);

      await _oauthLauncher.openAuthorizationUri(
        authorizationUri,
      );
    } on StravaBackendApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAuthorizing = false;
        _connectionError = error.message;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAuthorizing = false;
        _connectionError =
            'No fue posible iniciar la conexión con Strava.';
      });

      _showMessage(
        'No fue posible iniciar la conexión con Strava.',
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

    try {
      await _stravaApiService.disconnect();
      await _loadStravaStatus();

      if (!mounted) {
        return;
      }

      setState(() {
        _lastSyncResult = null;
        _syncError = null;
      });

      _showMessage(
        'La cuenta de Strava fue desconectada.',
      );
    } on StravaBackendApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    }
  }

  Future<void> _synchronizeActivities() async {
    if (_isSynchronizing) {
      return;
    }

    if (!_isConnected) {
      await _connectStrava();
      return;
    }

    setState(() {
      _isSynchronizing = true;
      _syncError = null;
    });

    try {
      final result =
          await _stravaApiService.syncActivities();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSynchronizing = false;
        _lastSyncResult = result;
        _syncError = null;
      });

      await _loadActivities();

      if (!mounted) {
        return;
      }

      await _showSyncSummary(result);
    } on StravaBackendApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSynchronizing = false;
        _syncError = error.message;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSynchronizing = false;
        _syncError =
            'No fue posible sincronizar las actividades.';
      });

      _showMessage(
        'No fue posible sincronizar las actividades.',
      );
    }
  }

  Future<void> _showSyncSummary(
    StravaSyncResult result,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.sync_rounded,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sincronización completada',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryDialogRow(
                label: 'Recuperadas de Strava',
                value: result.retrieved.toString(),
              ),
              _SummaryDialogRow(
                label: 'Guardadas',
                value: result.saved.toString(),
              ),
              _SummaryDialogRow(
                label: 'Duplicadas omitidas',
                value: result.skippedDuplicate.toString(),
              ),
              _SummaryDialogRow(
                label: 'Inválidas omitidas',
                value: result.skippedInvalid.toString(),
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
    await _initializeScreen();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showActivityDetail(StravaActivity activity) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SportIcon(
                    sportType: activity.sportType,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDateTime(
                            activity.startDateLocal,
                          ),
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(
                label: 'Deporte',
                value:
                    _sportLabel(activity.sportType),
              ),
              _DetailRow(
                label: 'Distancia',
                value:
                    '${_formatDistance(activity.distanceKilometers)} km',
              ),
              _DetailRow(
                label: 'Tiempo en movimiento',
                value: _formatDuration(
                  activity.movingTimeSeconds,
                ),
              ),
              _DetailRow(
                label: 'Tiempo total',
                value: _formatDuration(
                  activity.elapsedTimeSeconds,
                ),
              ),
              _DetailRow(
                label: 'Origen',
                value: 'Strava',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mis actividades',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.primary,
        ),
        actions: [
          IconButton(
            tooltip: _isConnected
                ? 'Sincronizar'
                : 'Conectar Strava',
            onPressed: _isSynchronizing
                ? null
                : _synchronizeActivities,
            icon: _isSynchronizing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.sync_rounded,
                    color: AppColors.primary,
                  ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshActivities,
        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                28,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StravaStatusCard(
                    isChecking: _isCheckingConnection,
                    isConnected: _isConnected,
                    isAuthorizing: _isAuthorizing,
                    isSynchronizing: _isSynchronizing,
                    connectionError: _connectionError,
                    syncError: _syncError,
                    result: _lastSyncResult,
                    onConnect: _connectStrava,
                    onDisconnect: _disconnectStrava,
                    onSynchronize:
                        _synchronizeActivities,
                  ),
                  const SizedBox(height: 22),
                  _ActivitySummary(
                    activityCount: _activities.length,
                    totalKilometers: _totalKilometers,
                    totalMovingSeconds:
                        _totalMovingSeconds,
                  ),
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
                  if (_isLoadingActivities)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    )
                  else if (_activitiesError != null)
                    _ErrorActivities(
                      message: _activitiesError!,
                      onRetry: _loadActivities,
                    )
                  else if (!_isConnected)
                    const _EmptyActivities(
                      message:
                          'Conecta Strava para consultar tus actividades reales.',
                    )
                  else if (_filteredActivities.isEmpty)
                    const _EmptyActivities(
                      message:
                          'No encontramos actividades de Strava en los últimos 30 días.',
                    )
                  else
                    ..._filteredActivities.map(
                      (activity) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 12,
                        ),
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
  }
}

class _StravaStatusCard extends StatelessWidget {
  const _StravaStatusCard({
    required this.isChecking,
    required this.isConnected,
    required this.isAuthorizing,
    required this.isSynchronizing,
    required this.connectionError,
    required this.syncError,
    required this.result,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSynchronize,
  });

  final bool isChecking;
  final bool isConnected;
  final bool isAuthorizing;
  final bool isSynchronizing;

  final String? connectionError;
  final String? syncError;
  final StravaSyncResult? result;

  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;
  final Future<void> Function() onSynchronize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color:
                connectionError != null ||
                    syncError != null
                ? Colors.red.withValues(alpha: 0.25)
                : AppColors.primary
                    .withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppColors.primary
                            .withValues(alpha: 0.12)
                        : Colors.orange
                            .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isConnected
                        ? Icons.check_circle_rounded
                        : Icons.link_rounded,
                    color: isConnected
                        ? AppColors.primary
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                            ? 'Mostrando actividades reales de Strava.'
                            : 'Autoriza App KM para consultar tus actividades.',
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
                          child: Text(
                            'Desconectar cuenta',
                          ),
                        ),
                      ];
                    },
                  ),
              ],
            ),
            if (isChecking) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Verificando conexión con Strava...',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ] else if (isAuthorizing) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text(
                'Completa la autorización en Strava y regresa a App KM.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ] else if (connectionError != null) ...[
              const SizedBox(height: 16),
              Text(
                connectionError!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (isConnected && isSynchronizing) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(),
              const SizedBox(height: 9),
              const Text(
                'Sincronizando actividades...',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ] else if (isConnected &&
                syncError != null) ...[
              const SizedBox(height: 16),
              Text(
                syncError!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (isConnected &&
                result != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _SmallValue(
                    label: 'Recuperadas',
                    value:
                        result!.retrieved.toString(),
                  ),
                  _SmallValue(
                    label: 'Guardadas',
                    value: result!.saved.toString(),
                  ),
                  _SmallValue(
                    label: 'Duplicadas',
                    value: result!
                        .skippedDuplicate
                        .toString(),
                  ),
                  _SmallValue(
                    label: 'Inválidas',
                    value: result!
                        .skippedInvalid
                        .toString(),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isConnected
                  ? OutlinedButton.icon(
                      onPressed: isSynchronizing
                          ? null
                          : onSynchronize,
                      icon: isSynchronizing
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.sync_rounded,
                            ),
                      label: Text(
                        isSynchronizing
                            ? 'Sincronizando...'
                            : 'Sincronizar ahora',
                      ),
                    )
                  : FilledButton.icon(
                      onPressed:
                          isAuthorizing || isChecking
                          ? null
                          : onConnect,
                      icon: const Icon(
                        Icons.link_rounded,
                      ),
                      label: Text(
                        isAuthorizing
                            ? 'Esperando autorización...'
                            : 'Conectar con Strava',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({
    required this.activityCount,
    required this.totalKilometers,
    required this.totalMovingSeconds,
  });

  final int activityCount;
  final double totalKilometers;
  final int totalMovingSeconds;

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
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimos 30 días en Strava',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_formatDistance(totalKilometers)} km',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  icon:
                      Icons.calendar_today_outlined,
                  value: activityCount.toString(),
                  label: 'Actividades',
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  icon: Icons.schedule_outlined,
                  value: _formatDuration(
                    totalMovingSeconds,
                  ),
                  label: 'Tiempo',
                ),
              ),
              const Expanded(
                child: _SummaryValue(
                  icon: Icons.cloud_done_outlined,
                  value: 'Strava',
                  label: 'Origen',
                ),
              ),
            ],
          ),
        ],
      ),
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

  static const filters = [
    'Todas',
    'Carrera',
    'Caminata',
    'Ciclismo',
    'Natación',
    'Gimnasio',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding:
                const EdgeInsets.only(right: 9),
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
  const _ActivityCard({
    required this.activity,
    required this.onPressed,
  });

  final StravaActivity activity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
              _SportIcon(
                sportType: activity.sportType,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(
                        activity.startDateLocal,
                      ),
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
                          text:
                              '${_formatDistance(activity.distanceKilometers)} km',
                        ),
                        _ActivityInfo(
                          icon:
                              Icons.schedule_outlined,
                          text: _formatDuration(
                            activity.movingTimeSeconds,
                          ),
                        ),
                      ],
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
                    _sportLabel(
                      activity.sportType,
                    ),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
  const _SportIcon({
    required this.sportType,
  });

  final String sportType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color:
            AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(
        _sportIcon(sportType),
        color: AppColors.primary,
        size: 28,
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
        Icon(
          icon,
          color: Colors.white,
          size: 21,
        ),
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SmallValue extends StatelessWidget {
  const _SmallValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color:
            AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDialogRow extends StatelessWidget {
  const _SummaryDialogRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
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

class _ActivityInfo extends StatelessWidget {
  const _ActivityInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.black45,
          size: 15,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
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
  const _EmptyActivities({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              color: Colors.black38,
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'No encontramos actividades',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorActivities extends StatelessWidget {
  const _ErrorActivities({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade700,
              size: 44,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Intentar nuevamente',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDistance(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1);
}

String _formatDuration(int seconds) {
  if (seconds <= 0) {
    return '0 min';
  }

  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours <= 0) {
    return '$minutes min';
  }

  if (minutes == 0) {
    return '$hours h';
  }

  return '$hours h $minutes min';
}

String _formatDateTime(DateTime date) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  final now = DateTime.now();

  final isToday =
      date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;

  final yesterday =
      now.subtract(const Duration(days: 1));

  final isYesterday =
      date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day;

  final hour12 = date.hour == 0
      ? 12
      : date.hour > 12
      ? date.hour - 12
      : date.hour;

  final minute =
      date.minute.toString().padLeft(2, '0');

  final period =
      date.hour >= 12 ? 'p. m.' : 'a. m.';

  final time = '$hour12:$minute $period';

  if (isToday) {
    return 'Hoy • $time';
  }

  if (isYesterday) {
    return 'Ayer • $time';
  }

  return '${date.day} ${months[date.month - 1]} • $time';
}

String _sportLabel(String sportType) {
  switch (sportType.toLowerCase()) {
    case 'run':
    case 'running':
    case 'trailrun':
    case 'virtualrun':
      return 'Carrera';

    case 'walk':
    case 'hike':
      return 'Caminata';

    case 'ride':
    case 'cycling':
    case 'mountainbikeride':
    case 'gravelride':
    case 'virtualride':
    case 'ebikeride':
      return 'Ciclismo';

    case 'swim':
    case 'swimming':
      return 'Natación';

    case 'weighttraining':
    case 'workout':
    case 'crossfit':
      return 'Gimnasio';

    default:
      return sportType;
  }
}

IconData _sportIcon(String sportType) {
  switch (_sportLabel(sportType)) {
    case 'Carrera':
      return Icons.directions_run_rounded;

    case 'Caminata':
      return Icons.directions_walk_rounded;

    case 'Ciclismo':
      return Icons.directions_bike_rounded;

    case 'Natación':
      return Icons.pool_rounded;

    case 'Gimnasio':
      return Icons.fitness_center_rounded;

    default:
      return Icons.sports_rounded;
  }
}
