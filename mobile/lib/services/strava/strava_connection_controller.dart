import 'package:flutter/foundation.dart';

import '../../models/strava_auth_result.dart';
import 'strava_auth_exception.dart';
import 'strava_auth_service.dart';

enum StravaConnectionStatus {
  checking,
  disconnected,
  authorizing,
  connected,
  error,
}

class StravaConnectionController extends ChangeNotifier {
  StravaConnectionController({required StravaAuthService authService})
    : _authService = authService;

  final StravaAuthService _authService;

  StravaConnectionStatus _status = StravaConnectionStatus.checking;

  StravaAthlete? _athlete;
  Uri? _authorizationUri;
  String? _errorMessage;
  String? _errorCode;

  StravaConnectionStatus get status => _status;

  StravaAthlete? get athlete => _athlete;

  Uri? get authorizationUri => _authorizationUri;

  String? get errorMessage => _errorMessage;

  String? get errorCode => _errorCode;

  bool get isChecking {
    return _status == StravaConnectionStatus.checking;
  }

  bool get isAuthorizing {
    return _status == StravaConnectionStatus.authorizing;
  }

  bool get isConnected {
    return _status == StravaConnectionStatus.connected;
  }

  bool get hasError {
    return _status == StravaConnectionStatus.error;
  }

  Future<void> initialize() async {
    _status = StravaConnectionStatus.checking;
    _errorMessage = null;
    _errorCode = null;

    notifyListeners();

    try {
      final connected = await _authService.isConnected();

      if (!connected) {
        _athlete = null;
        _status = StravaConnectionStatus.disconnected;

        notifyListeners();
        return;
      }

      _athlete = await _authService.getStoredAthlete();
      _status = StravaConnectionStatus.connected;

      notifyListeners();
    } catch (_) {
      _athlete = null;
      _status = StravaConnectionStatus.disconnected;

      notifyListeners();
    }
  }

  Uri beginAuthorization() {
    try {
      final uri = _authService.createAuthorizationUri();

      _authorizationUri = uri;
      _status = StravaConnectionStatus.authorizing;
      _errorMessage = null;
      _errorCode = null;

      notifyListeners();

      return uri;
    } on StateError catch (error) {
      _setError(message: error.message.toString(), code: 'configuration_error');

      rethrow;
    } catch (_) {
      _setError(
        message: 'No fue posible iniciar la conexión con Strava.',
        code: 'authorization_start_failed',
      );

      rethrow;
    }
  }

  Future<bool> handleCallback(Uri callbackUri) async {
    try {
      final result = await _authService.handleCallback(callbackUri);

      _athlete = result.athlete;
      _authorizationUri = null;
      _status = StravaConnectionStatus.connected;
      _errorMessage = null;
      _errorCode = null;

      notifyListeners();

      return true;
    } on StravaAuthException catch (error) {
      _setError(
        message: error.message,
        code: error.code ?? 'authorization_failed',
      );

      return false;
    } catch (_) {
      _setError(
        message: 'No fue posible completar la conexión con Strava.',
        code: 'authorization_failed',
      );

      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _authService.disconnect();

      _athlete = null;
      _authorizationUri = null;
      _errorMessage = null;
      _errorCode = null;
      _status = StravaConnectionStatus.disconnected;

      notifyListeners();
    } catch (_) {
      _setError(
        message: 'No fue posible desconectar la cuenta de Strava.',
        code: 'disconnect_failed',
      );
    }
  }

  void cancelAuthorization() {
    _authorizationUri = null;
    _errorMessage = null;
    _errorCode = null;

    _status = _athlete == null
        ? StravaConnectionStatus.disconnected
        : StravaConnectionStatus.connected;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _errorCode = null;

    _status = _athlete == null
        ? StravaConnectionStatus.disconnected
        : StravaConnectionStatus.connected;

    notifyListeners();
  }

  void _setError({required String message, required String code}) {
    _errorMessage = message;
    _errorCode = code;
    _status = StravaConnectionStatus.error;

    notifyListeners();
  }
}
