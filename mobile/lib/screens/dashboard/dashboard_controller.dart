import 'package:flutter/foundation.dart';

import '../../core/app_dependencies.dart';
import '../../models/dashboard_summary.dart';
import '../../services/dashboard_service.dart';
import '../../services/strava/strava_connection_controller.dart';
import '../../services/strava/strava_oauth_launcher.dart';
import '../../services/strava/strava_sync_controller.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    AppDependencies? dependencies,
    this.userId = 'local-user',
  }) {
    final resolvedDependencies = dependencies ?? AppDependencies.instance;

    _connectionController = resolvedDependencies.stravaConnectionController;
    _syncController = resolvedDependencies.stravaSyncController;
    _oauthLauncher = resolvedDependencies.stravaOAuthLauncher;
    _dashboardService = resolvedDependencies.dashboardService;

    _connectionController.addListener(_handleExternalChange);
    _syncController.addListener(_handleExternalChange);
  }

  final String userId;

  late final StravaConnectionController _connectionController;
  late final StravaSyncController _syncController;
  late final StravaOAuthLauncher _oauthLauncher;
  late final DashboardService _dashboardService;

  DashboardSummary _summary = DashboardSummary.empty();
  bool _isLoadingSummary = true;
  String? _dashboardError;

  DashboardSummary get summary => _summary;

  bool get isLoadingSummary => _isLoadingSummary;

  String? get dashboardError => _dashboardError;

  StravaConnectionStatus get connectionStatus => _connectionController.status;

  StravaSyncStatus get syncStatus => _syncController.status;

  String? get connectionErrorMessage => _connectionController.errorMessage;

  String? get syncErrorMessage => _syncController.errorMessage;

  Future<void> initialize() async {
    await loadSummary();
  }

  Future<void> loadSummary() async {
    _isLoadingSummary = true;
    _dashboardError = null;
    notifyListeners();

    try {
      _summary = await _dashboardService.loadSummary(userId: userId);
    } catch (_) {
      _dashboardError = 'No fue posible actualizar el resumen del dashboard.';
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  Future<String?> connectWithStrava() async {
    if (_connectionController.isAuthorizing) {
      return null;
    }

    try {
      final authorizationUri = _connectionController.beginAuthorization();

      await _oauthLauncher.openAuthorizationUri(authorizationUri);

      return null;
    } catch (_) {
      return _connectionController.errorMessage ??
          'No fue posible abrir la autorización de Strava.';
    }
  }

  Future<String> disconnectStrava() async {
    await _connectionController.disconnect();
    _syncController.clearResult();

    if (_connectionController.hasError) {
      return _connectionController.errorMessage ??
          'No fue posible desconectar Strava.';
    }

    return 'Cuenta de Strava desconectada.';
  }

  Future<String> syncActivities() async {
    if (_syncController.isSynchronizing) {
      return 'La sincronización ya está en proceso.';
    }

    final result = await _syncController.synchronizeToday(userId: userId);

    if (result == null) {
      return _syncController.errorMessage ??
          'No fue posible sincronizar las actividades.';
    }

    await loadSummary();

    if (!result.hasResults) {
      return 'Sincronización completada sin actividades nuevas.';
    }

    return 'Sincronización completada: '
        '${result.approvedCount} aprobadas, '
        '${result.rejectedCount} rechazadas y '
        '${result.totalPointsAwarded} puntos generados.';
  }

  void retryConnectionCheck() {
    _connectionController.initialize();
  }

  Future<String> retrySynchronization() async {
    _syncController.clearResult();
    return syncActivities();
  }

  String formatKilometers(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  void _handleExternalChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionController.removeListener(_handleExternalChange);
    _syncController.removeListener(_handleExternalChange);
    super.dispose();
  }
}
