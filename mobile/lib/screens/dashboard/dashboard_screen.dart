import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/athletes/current_athlete.dart';
import '../../services/athletes/athlete_api_service.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../workouts/activity_screen.dart';
import 'dashboard_controller.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/points_card.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/section_title.dart';
import 'widgets/statistics_grid.dart';
import 'widgets/strava_connection_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final GlobalKey<_HomeDashboardState> _homeDashboardKey =
      GlobalKey<_HomeDashboardState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeDashboard(key: _homeDashboardKey),
      const ActivityScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
  }

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      _homeDashboardKey.currentState?.reloadAthlete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changePage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Actividad',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  late final DashboardController _controller;
  late final AthleteApiService _athleteApiService;

  CurrentAthlete? _currentAthlete;
  bool _isLoadingAthlete = true;
  String? _athleteError;

  @override
  void initState() {
    super.initState();

    _controller = DashboardController();
    _controller.addListener(_handleControllerChange);
    _controller.initialize();

    _athleteApiService = AthleteApiService();
    _loadCurrentAthlete();
  }

  Future<void> _loadCurrentAthlete() async {
    try {
      final athlete = await _athleteApiService.getCurrentAthlete();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentAthlete = athlete;
        _athleteError = null;
        _isLoadingAthlete = false;
      });
    } on AthleteApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _athleteError = error.message;
        _isLoadingAthlete = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _athleteError = 'No fue posible cargar el perfil.';
        _isLoadingAthlete = false;
      });
    }
  }

  Future<void> reloadAthlete() async {
    await _loadCurrentAthlete();
    await _controller.loadAthleteDashboard();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    _athleteApiService.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _connectWithStrava() async {
    final message = await _controller.connectWithStrava();

    if (message != null) {
      _showMessage(message);
    }
  }

  Future<void> _disconnectStrava() async {
    final message = await _controller.disconnectStrava();

    _showMessage(message);
  }

  Future<void> _syncActivities() async {
    final message = await _controller.syncActivities();

    _showMessage(message);
  }

  Future<void> _retrySynchronization() async {
    final message = await _controller.retrySynchronization();

    _showMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: DashboardHeader(
                displayName: _currentAthlete?.displayName ?? 'Atleta',
                onNotificationsPressed: () {
                  _showMessage('No tienes notificaciones nuevas.');
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_isLoadingAthlete)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(),
                    )
                  else if (_athleteError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _athleteError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  PointsCard(
                    points:
                        _controller.athleteDashboard?.pointsBalance ?? 0,
                    isLoading:
                        _controller.isLoadingAthleteDashboard,
                  ),
                  if ((_controller
                              .athleteDashboard
                              ?.pointsExpiringSoon ??
                          0) >
                      0) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_controller.athleteDashboard!.pointsExpiringSoon} '
                              'puntos vencen en los próximos 30 días.',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const SectionTitle(
                    title: 'Tu resumen',
                    actionText: 'Este mes',
                  ),
                  const SizedBox(height: 12),
                  if (_controller.athleteDashboard != null)
                    StatisticsGrid(
                      dashboard: _controller.athleteDashboard!,
                      isLoading:
                          _controller.isLoadingAthleteDashboard,
                      formatKilometers:
                          _controller.formatKilometers,
                    ),
                  const SizedBox(height: 24),
                  StravaConnectionCard(
                    status: _controller.effectiveConnectionStatus,
                    syncStatus: _controller.syncStatus,
                    errorMessage:
                        _controller.connectionErrorMessage,
                    syncErrorMessage:
                        _controller.syncErrorMessage,
                    onConnect: _connectWithStrava,
                    onSync: _syncActivities,
                    onDisconnect: _disconnectStrava,
                    onRetryConnection:
                        _controller.retryConnectionCheck,
                    onRetrySync: _retrySynchronization,
                  ),
                  if (_controller.athleteDashboardError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _controller.athleteDashboardError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const SectionTitle(
                    title: 'Actividad reciente',
                    actionText: 'Ver todas',
                  ),
                  const SizedBox(height: 12),
                  RecentActivityCard(
                    activity:
                        _controller.athleteDashboard?.lastActivity,
                    isLoading:
                        _controller.isLoadingAthleteDashboard,
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