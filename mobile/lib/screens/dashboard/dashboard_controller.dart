import 'package:flutter/foundation.dart';

import '../../models/athletes/athlete_dashboard.dart';
import '../../services/athletes/athlete_api_service.dart';
import '../../services/strava/strava_backend_api_service.dart';
import '../../services/strava/strava_connection_controller.dart';
import '../../services/strava/strava_oauth_launcher.dart';
import '../../services/strava/strava_sync_controller.dart';

class DashboardController extends ChangeNotifier {
  DashboardController();

  final AthleteApiService _athleteApiService = AthleteApiService();
  final StravaBackendApiService _stravaBackendApiService =
      StravaBackendApiService();
  final StravaOAuthLauncher _oauthLauncher = const StravaOAuthLauncher();

  AthleteDashboard? _athleteDashboard;
  bool _isLoadingAthleteDashboard = true;
  String? _athleteDashboardError;

  StravaConnectionStatus _connectionStatus =
      StravaConnectionStatus.checking;
  StravaSyncStatus _syncStatus = StravaSyncStatus.idle;

  String? _connectionErrorMessage;
  String? _syncErrorMessage;

  StravaConnectionStatus get effectiveConnectionStatus =>
      _connectionStatus;

  StravaConnectionStatus get connectionStatus =>
      _connectionStatus;

  StravaSyncStatus get syncStatus => _syncStatus;

  String? get connectionErrorMessage =>
      _connectionErrorMessage;

  String? get syncErrorMessage => _syncErrorMessage;

  AthleteDashboard? get athleteDashboard => _athleteDashboard;

  bool get isLoadingAthleteDashboard =>
      _isLoadingAthleteDashboard;

  String? get athleteDashboardError =>
      _athleteDashboardError;

  Future<void> initialize() async {
    await loadAthleteDashboard();
  }

  Future<void> loadAthleteDashboard() async {
    _isLoadingAthleteDashboard = true;
    _athleteDashboardError = null;
    _connectionErrorMessage = null;
    _connectionStatus = StravaConnectionStatus.checking;
    notifyListeners();

    try {
      final dashboard =
          await _athleteApiService.getDashboard();

      _athleteDashboard = dashboard;
      _connectionStatus = dashboard.stravaConnected
          ? StravaConnectionStatus.connected
          : StravaConnectionStatus.disconnected;
    } catch (_) {
      _athleteDashboardError =
          'No fue posible obtener los datos actuales del atleta.';
      _connectionErrorMessage =
          'No fue posible verificar la conexión con Strava.';
      _connectionStatus = StravaConnectionStatus.error;
    } finally {
      _isLoadingAthleteDashboard = false;
      notifyListeners();
    }
  }

  Future<String?> connectWithStrava() async {
    if (_connectionStatus ==
        StravaConnectionStatus.authorizing) {
      return null;
    }

    _connectionStatus =
        StravaConnectionStatus.authorizing;
    _connectionErrorMessage = null;
    notifyListeners();

    try {
      final response =
          await _stravaBackendApiService.getConnectUrl();

      final authorizationUri =
          Uri.parse(response.authorizationUrl);

      await _oauthLauncher.openAuthorizationUri(
        authorizationUri,
      );

      return null;
    } on StravaBackendApiException catch (error) {
      _connectionStatus = StravaConnectionStatus.error;
      _connectionErrorMessage = error.message;
      notifyListeners();
      return error.message;
    } catch (_) {
      const message =
          'No fue posible abrir la autorización de Strava.';

      _connectionStatus = StravaConnectionStatus.error;
      _connectionErrorMessage = message;
      notifyListeners();

      return message;
    }
  }

  Future<String> disconnectStrava() async {
    try {
      await _stravaBackendApiService.disconnect();

      _syncStatus = StravaSyncStatus.idle;
      _syncErrorMessage = null;

      await loadAthleteDashboard();

      return 'Cuenta de Strava desconectada.';
    } on StravaBackendApiException catch (error) {
      _connectionErrorMessage = error.message;
      _connectionStatus = StravaConnectionStatus.error;
      notifyListeners();

      return error.message;
    } catch (_) {
      const message =
          'No fue posible desconectar Strava.';

      _connectionErrorMessage = message;
      _connectionStatus = StravaConnectionStatus.error;
      notifyListeners();

      return message;
    }
  }

  Future<String> syncActivities() async {
    if (_syncStatus == StravaSyncStatus.synchronizing) {
      return 'La sincronización ya está en proceso.';
    }

    if (_connectionStatus !=
        StravaConnectionStatus.connected) {
      return 'Conecta tu cuenta de Strava antes de sincronizar.';
    }

    _syncStatus = StravaSyncStatus.synchronizing;
    _syncErrorMessage = null;
    notifyListeners();

    try {
      final result =
          await _stravaBackendApiService.syncActivities();

      _syncStatus = StravaSyncStatus.success;

      await loadAthleteDashboard();

      notifyListeners();

      if (result.saved == 0) {
        return 'Sincronización completada: '
            '${result.retrieved} recuperadas, '
            'sin actividades nuevas guardadas. '
            '${result.skippedDuplicate} duplicadas y '
            '${result.skippedInvalid} inválidas omitidas.';
      }

      return 'Sincronización completada: '
          '${result.retrieved} recuperadas, '
          '${result.saved} guardadas, '
          '${result.skippedDuplicate} duplicadas y '
          '${result.skippedInvalid} inválidas omitidas.';
    } on StravaBackendApiException catch (error) {
      _syncStatus = StravaSyncStatus.error;
      _syncErrorMessage = error.message;
      notifyListeners();

      return error.message;
    } catch (_) {
      const message =
          'No fue posible sincronizar las actividades.';

      _syncStatus = StravaSyncStatus.error;
      _syncErrorMessage = message;
      notifyListeners();

      return message;
    }
  }

  void retryConnectionCheck() {
    loadAthleteDashboard();
  }

  Future<String> retrySynchronization() async {
    _syncStatus = StravaSyncStatus.idle;
    _syncErrorMessage = null;
    notifyListeners();

    return syncActivities();
  }

  String formatKilometers(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _athleteApiService.dispose();
    _stravaBackendApiService.dispose();
    super.dispose();
  }
}
