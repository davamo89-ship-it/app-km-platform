import 'package:flutter/foundation.dart';

import '../../core/app_dependencies.dart';
import '../../services/strava/strava_connection_controller.dart';
import '../../services/strava/strava_oauth_launcher.dart';
import '../../services/strava/strava_sync_controller.dart';
import '../../models/athletes/athlete_dashboard.dart';
import '../../services/athletes/athlete_api_service.dart';


class DashboardController extends ChangeNotifier {
  DashboardController({
    AppDependencies? dependencies,
    this.userId = 'local-user',
  }) {
    final resolvedDependencies = dependencies ?? AppDependencies.instance;

    _connectionController = resolvedDependencies.stravaConnectionController;
    _syncController = resolvedDependencies.stravaSyncController;
    _oauthLauncher = resolvedDependencies.stravaOAuthLauncher;
    _athleteApiService = AthleteApiService();

    _connectionController.addListener(_handleExternalChange);
    _syncController.addListener(_handleExternalChange);
  }

  final String userId;

  late final StravaConnectionController _connectionController;
  late final StravaSyncController _syncController;
  late final StravaOAuthLauncher _oauthLauncher;
  late final AthleteApiService _athleteApiService;
  
  AthleteDashboard? _athleteDashboard;
  bool _isLoadingAthleteDashboard = true;
  String? _athleteDashboardError;

  StravaConnectionStatus get effectiveConnectionStatus {
    if (_isLoadingAthleteDashboard) {
      return StravaConnectionStatus.checking;
    }

    if (_athleteDashboard?.stravaConnected == true) {
      return StravaConnectionStatus.connected;
    }

    return StravaConnectionStatus.disconnected;
  }

  StravaConnectionStatus get connectionStatus => _connectionController.status;

  StravaSyncStatus get syncStatus => _syncController.status;

  String? get connectionErrorMessage => _connectionController.errorMessage;

  String? get syncErrorMessage => _syncController.errorMessage;

  AthleteDashboard? get athleteDashboard => _athleteDashboard;

  bool get isLoadingAthleteDashboard => _isLoadingAthleteDashboard;

  String? get athleteDashboardError => _athleteDashboardError;

  Future<void> initialize() async {
  await loadAthleteDashboard();
  }

    Future<void> loadAthleteDashboard() async {
      _isLoadingAthleteDashboard = true;
      _athleteDashboardError = null;
      notifyListeners();

      try {
        _athleteDashboard = await _athleteApiService.getDashboard();
      } catch (_) {
        _athleteDashboardError =
            'No fue posible obtener los datos actuales del atleta.';
      } finally {
        _isLoadingAthleteDashboard = false;
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

    await loadAthleteDashboard();

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
    _athleteApiService.dispose();
    super.dispose();
  }
}
