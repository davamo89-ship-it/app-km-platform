import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/athletes/current_athlete.dart';
import '../../models/points/upcoming_point_expiration.dart';
import '../../models/redemptions/pending_redemption_confirmation.dart';
import '../../services/athletes/athlete_api_service.dart';
import '../../services/points/points_backend_api_service.dart';
import '../../services/redemptions/pending_redemptions_backend_api_service.dart';
import '../history/history_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../redemptions/redemptions_screen.dart';
import '../workouts/activity_screen.dart';
import 'dashboard_controller.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/points_card.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/section_title.dart';
import 'widgets/statistics_grid.dart';
import 'widgets/strava_connection_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late int _currentIndex;

  int _unreadNotificationCount = 0;
  String? _currentNotificationSignature;
  String? _reviewedNotificationSignature;

  final GlobalKey<_HomeDashboardState>
      _homeDashboardKey =
      GlobalKey<_HomeDashboardState>();

  final PointsBackendApiService _pointsApi =
      PointsBackendApiService();

  final PendingRedemptionsBackendApiService
      _pendingRedemptionsApi =
      PendingRedemptionsBackendApiService();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex < 0
        ? 0
        : widget.initialIndex > 3
            ? 3
            : widget.initialIndex;

    WidgetsBinding.instance.addObserver(this);

    _pages = [
      HomeDashboard(
        key: _homeDashboardKey,
        onNotificationsPressed:
            _openNotifications,
        unreadNotificationCount: () =>
            _unreadNotificationCount,
        onOpenRedemptions: _openRedemptions,
      ),
      const ActivityScreen(),
      HistoryScreen(
        onNavigateMainSection: _changePage,
      ),
      const ProfileScreen(),
    ];

    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);
    _pointsApi.dispose();
    _pendingRedemptionsApi.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
        AppLifecycleState.resumed) {
      _loadUnreadNotifications();
    }
  }

  Future<void> _loadUnreadNotifications({
    bool markCurrentAsReviewed = false,
  }) async {
    try {
      final pendingFuture =
          _pendingRedemptionsApi
              .getPendingConfirmations();

      final expirationsFuture =
          _pointsApi.getExpirations();

      final pending = await pendingFuture;
      final expirations =
          await expirationsFuture;

      pending.sort(
        (a, b) => b.merchantProposedAtUtc
            .compareTo(
                a.merchantProposedAtUtc),
      );

      final relevantExpirations =
          expirations
              .where(
                (item) =>
                    item.daysRemaining >= 0 &&
                    item.daysRemaining <= 30 &&
                    item.remainingPoints > 0,
              )
              .toList()
            ..sort(
              (a, b) =>
                  a.expiresAtUtc.compareTo(
                    b.expiresAtUtc,
                  ),
            );

      final signature =
          _buildNotificationSignature(
        pending,
        relevantExpirations,
      );

      final totalCount =
          pending.length +
          relevantExpirations.length;

      if (markCurrentAsReviewed) {
        _reviewedNotificationSignature =
            signature;
      }

      final hasUnread =
          signature != null &&
          signature !=
              _reviewedNotificationSignature;

      if (!mounted) return;

      setState(() {
        _currentNotificationSignature =
            signature;
        _unreadNotificationCount =
            hasUnread ? totalCount : 0;
      });

      _homeDashboardKey.currentState
          ?.refreshHeader();
    } catch (_) {
      // Conservamos el último estado visual
      // conocido ante un error temporal.
    }
  }

  String? _buildNotificationSignature(
    List<PendingRedemptionConfirmation>
        pending,
    List<UpcomingPointExpiration>
        expirations,
  ) {
    final parts = <String>[];

    for (final item in pending) {
      parts.add(
        'redemption:'
        '${item.redemptionRequestId}:'
        '${item.code}:'
        '${item.proposedPoints}:'
        '${item.merchantProposedAtUtc.toUtc().toIso8601String()}',
      );
    }

    for (final expiration
        in expirations) {
      parts.add(
        'expiration:'
        '${expiration.remainingPoints}:'
        '${expiration.expiresAtUtc.toUtc().toIso8601String()}',
      );
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join('|');
  }

  Future<void> _openNotifications() async {
    final signatureAtOpen =
        _currentNotificationSignature;

    if (mounted) {
      setState(() {
        _reviewedNotificationSignature =
            signatureAtOpen;
        _unreadNotificationCount = 0;
      });

      _homeDashboardKey.currentState
          ?.refreshHeader();
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            NotificationsScreen(
              onNavigateMainSection: _changePage,
            ),
      ),
    );

    if (!mounted) return;

    await _loadUnreadNotifications(
      markCurrentAsReviewed: true,
    );

    if (_currentIndex == 0) {
      await _homeDashboardKey.currentState
          ?.reloadAthlete();
    }
  }

  Future<void> _openRedemptions() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RedemptionsScreen(
          onNavigateMainSection: _changePage,
        ),
      ),
    );

    if (!mounted) return;

    await _loadUnreadNotifications();
    await _homeDashboardKey.currentState?.reloadAthlete();
  }

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });

    _loadUnreadNotifications();

    if (index == 0) {
      _homeDashboardKey.currentState
          ?.reloadAthlete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showUnreadBanner =
        _currentIndex != 0 &&
        _unreadNotificationCount > 0;

    return Scaffold(
      body: Column(
        children: [
          if (showUnreadBanner)
            _UnreadNotificationsBanner(
              count:
                  _unreadNotificationCount,
              onPressed:
                  _openNotifications,
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected:
            _changePage,
        destinations: [
          NavigationDestination(
            icon: _HomeNavigationIcon(
              selected: false,
              unreadCount:
                  _unreadNotificationCount,
            ),
            selectedIcon:
                _HomeNavigationIcon(
              selected: true,
              unreadCount:
                  _unreadNotificationCount,
            ),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(
              Icons.directions_run_outlined,
            ),
            selectedIcon: Icon(
              Icons.directions_run,
            ),
            label: 'Actividad',
          ),
          const NavigationDestination(
            icon: Icon(
              Icons.history_outlined,
            ),
            selectedIcon:
                Icon(Icons.history),
            label: 'Historial',
          ),
          const NavigationDestination(
            icon:
                Icon(Icons.person_outline),
            selectedIcon:
                Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _HomeNavigationIcon
    extends StatelessWidget {
  const _HomeNavigationIcon({
    required this.selected,
    required this.unreadCount,
  });

  final bool selected;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      selected
          ? Icons.home
          : Icons.home_outlined,
    );

    if (unreadCount <= 0) {
      return icon;
    }

    return Badge(
      label: Text(
        unreadCount > 9
            ? '9+'
            : '$unreadCount',
      ),
      child: icon,
    );
  }
}

class _UnreadNotificationsBanner
    extends StatelessWidget {
  const _UnreadNotificationsBanner({
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Material(
        color: AppColors.primary
            .withValues(alpha: 0.10),
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              10,
              14,
              10,
            ),
            child: Row(
              children: [
                Badge(
                  label: Text(
                    count > 9
                        ? '9+'
                        : '$count',
                  ),
                  child: const Icon(
                    Icons
                        .notifications_active_outlined,
                    color:
                        AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    count == 1
                        ? 'Tiene una notificación sin revisar.'
                        : 'Tiene $count notificaciones sin revisar.',
                    style:
                        const TextStyle(
                      color:
                          AppColors.textDark,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
                const Text(
                  'Revisar',
                  style: TextStyle(
                    color:
                        AppColors.primary,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeDashboard
    extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.onNotificationsPressed,
    required this
        .unreadNotificationCount,
    required this.onOpenRedemptions,
  });

  final VoidCallback
      onNotificationsPressed;
  final int Function()
      unreadNotificationCount;
  final VoidCallback onOpenRedemptions;

  @override
  State<HomeDashboard> createState() =>
      _HomeDashboardState();
}

class _HomeDashboardState
    extends State<HomeDashboard> {
  late final DashboardController
      _controller;
  late final AthleteApiService
      _athleteApiService;

  CurrentAthlete? _currentAthlete;
  bool _isLoadingAthlete = true;
  String? _athleteError;

  @override
  void initState() {
    super.initState();

    _controller =
        DashboardController();
    _controller.addListener(
        _handleControllerChange);
    _controller.initialize();

    _athleteApiService =
        AthleteApiService();
    _loadCurrentAthlete();
  }

  Future<void>
      _loadCurrentAthlete() async {
    try {
      final athlete =
          await _athleteApiService
              .getCurrentAthlete();

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
        _athleteError =
            error.message;
        _isLoadingAthlete = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _athleteError =
            'No fue posible cargar el perfil.';
        _isLoadingAthlete = false;
      });
    }
  }

  Future<void>
      reloadAthlete() async {
    await _loadCurrentAthlete();
    await _controller
        .loadAthleteDashboard();
  }

  void refreshHeader() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(
        _handleControllerChange);
    _controller.dispose();
    _athleteApiService.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showMessage(
      String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void>
      _connectWithStrava() async {
    final message =
        await _controller
            .connectWithStrava();

    if (message != null) {
      _showMessage(message);
    }
  }

  Future<void>
      _disconnectStrava() async {
    final message =
        await _controller
            .disconnectStrava();

    _showMessage(message);
  }

  Future<void>
      _syncActivities() async {
    final message =
        await _controller
            .syncActivities();

    _showMessage(message);
  }

  Future<void>
      _retrySynchronization() async {
    final message =
        await _controller
            .retrySynchronization();

    _showMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: DashboardHeader(
                displayName:
                    _currentAthlete
                            ?.displayName ??
                        'Atleta',
                unreadNotificationCount:
                    widget
                        .unreadNotificationCount(),
                onNotificationsPressed:
                    widget
                        .onNotificationsPressed,
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                20,
                8,
                20,
                28,
              ),
              sliver: SliverList(
                delegate:
                    SliverChildListDelegate(
                  [
                    if (_isLoadingAthlete)
                      const Padding(
                        padding:
                            EdgeInsets.only(
                          bottom: 16,
                        ),
                        child:
                            LinearProgressIndicator(),
                      )
                    else if (_athleteError !=
                        null)
                      Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          bottom: 16,
                        ),
                        child: Text(
                          _athleteError!,
                          style:
                              const TextStyle(
                            color:
                                Colors.red,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                    PointsCard(
                      points: _controller
                              .athleteDashboard
                              ?.pointsBalance ??
                          0,
                      isLoading:
                          _controller
                              .isLoadingAthleteDashboard,
                    ),
                    const SizedBox(height: 12),
                    _DashboardRedemptionButton(
                      onPressed: widget.onOpenRedemptions,
                    ),
                    if ((_controller
                                .athleteDashboard
                                ?.pointsExpiringSoon ??
                            0) >
                        0) ...[
                      const SizedBox(
                          height: 12),
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(14),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .orange
                              .withValues(
                                  alpha:
                                      0.10),
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      16),
                          border:
                              Border.all(
                            color: Colors
                                .orange
                                .withValues(
                                    alpha:
                                        0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .schedule_rounded,
                              color: Colors
                                  .orange,
                            ),
                            const SizedBox(
                                width:
                                    10),
                            Expanded(
                              child:
                                  Text(
                                '${_controller.athleteDashboard!.pointsExpiringSoon} '
                                'puntos vencen en los próximos 30 días.',
                                style:
                                    const TextStyle(
                                  color:
                                      AppColors
                                          .textDark,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(
                        height: 20),
                    const SectionTitle(
                      title:
                          'Tu resumen',
                      actionText:
                          'Este mes',
                    ),
                    const SizedBox(
                        height: 12),
                    if (_controller
                            .athleteDashboard !=
                        null)
                      StatisticsGrid(
                        dashboard:
                            _controller
                                .athleteDashboard!,
                        isLoading:
                            _controller
                                .isLoadingAthleteDashboard,
                        formatKilometers:
                            _controller
                                .formatKilometers,
                      ),
                    const SizedBox(
                        height: 24),
                    StravaConnectionCard(
                      status: _controller
                          .effectiveConnectionStatus,
                      syncStatus:
                          _controller
                              .syncStatus,
                      errorMessage:
                          _controller
                              .connectionErrorMessage,
                      syncErrorMessage:
                          _controller
                              .syncErrorMessage,
                      onConnect:
                          _connectWithStrava,
                      onSync:
                          _syncActivities,
                      onDisconnect:
                          _disconnectStrava,
                      onRetryConnection:
                          _controller
                              .retryConnectionCheck,
                      onRetrySync:
                          _retrySynchronization,
                    ),
                    if (_controller
                            .athleteDashboardError !=
                        null) ...[
                      const SizedBox(
                          height: 12),
                      Text(
                        _controller
                            .athleteDashboardError!,
                        style:
                            const TextStyle(
                          color:
                              Colors.red,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ],
                    const SizedBox(
                        height: 24),
                    const SectionTitle(
                      title:
                          'Actividad del último día sincronizado',
                      actionText:
                          'Ver todas',
                    ),
                    const SizedBox(height: 12),
                    if (_controller.isLoadingAthleteDashboard)
                      const RecentActivityCard(
                        activity: null,
                        isLoading: true,
                      )
                    else if ((_controller
                                .athleteDashboard
                                ?.latestDayActivities ??
                            const [])
                        .isEmpty)
                      const RecentActivityCard(
                        activity: null,
                        isLoading: false,
                      )
                    else
                      ..._controller
                          .athleteDashboard!
                          .latestDayActivities
                          .map(
                            (activity) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: RecentActivityCard(
                                activity: activity,
                                isLoading: false,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardRedemptionButton extends StatelessWidget {
  const _DashboardRedemptionButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear canje',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Genera un código para canjear tus puntos.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
