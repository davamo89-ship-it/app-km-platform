import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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

  final List<Widget> _pages = const [
    HomeDashboard(),
    ActivityScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
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

  @override
  void initState() {
    super.initState();

    _controller = DashboardController();
    _controller.addListener(_handleControllerChange);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
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
    ).showSnackBar(SnackBar(content: Text(message)));
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
    final summary = _controller.summary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: DashboardHeader(
                onNotificationsPressed: () {
                  _showMessage('No tienes notificaciones nuevas.');
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  PointsCard(
                    points: summary.currentPoints,
                    isLoading: _controller.isLoadingSummary,
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(
                    title: 'Tu resumen',
                    actionText: 'Este mes',
                  ),
                  const SizedBox(height: 12),
                  StatisticsGrid(
                    summary: summary,
                    isLoading: _controller.isLoadingSummary,
                    formatKilometers: _controller.formatKilometers,
                  ),
                  const SizedBox(height: 24),
                  StravaConnectionCard(
                    status: _controller.connectionStatus,
                    syncStatus: _controller.syncStatus,
                    errorMessage: _controller.connectionErrorMessage,
                    syncErrorMessage: _controller.syncErrorMessage,
                    onConnect: _connectWithStrava,
                    onSync: _syncActivities,
                    onDisconnect: _disconnectStrava,
                    onRetryConnection: _controller.retryConnectionCheck,
                    onRetrySync: _retrySynchronization,
                  ),
                  if (_controller.dashboardError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _controller.dashboardError!,
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
                    activity: summary.latestActivity,
                    isLoading: _controller.isLoadingSummary,
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
