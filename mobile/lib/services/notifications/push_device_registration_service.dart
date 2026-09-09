import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import '../api/authenticated_api_client.dart';
import '../auth/auth_token_store.dart';
import 'push_notification_service.dart';

class PushDeviceRegistrationService {
  PushDeviceRegistrationService._();

  static final PushDeviceRegistrationService instance =
      PushDeviceRegistrationService._();

  final AuthTokenStore _authTokenStore = AuthTokenStore();
  final AuthenticatedApiClient _apiClient =
      AuthenticatedApiClient();

  StreamSubscription<String>? _tokenSubscription;

  bool _initialized = false;
  bool _isRegistering = false;

  String? _lastRegisteredToken;

  void initialize() {
    if (_initialized) {
      return;
    }

    _tokenSubscription =
        PushNotificationService.instance.tokenChanges.listen(
      (token) async {
        await _registerTokenIfSessionExists(
          token,
          reason: 'refresh',
        );
      },
      onError: (Object error) {
        debugPrint(
          '[FCM] Error escuchando cambios de token: $error',
        );
      },
    );

    _initialized = true;
  }

  Future<void> syncCurrentToken() async {
    final token =
        PushNotificationService.instance.currentToken;

    if (token == null || token.trim().isEmpty) {
      debugPrint(
        '[FCM] No hay token disponible para sincronizar.',
      );
      return;
    }

    await _registerTokenIfSessionExists(
      token,
      reason: 'session',
      force: true,
    );
  }

  Future<void> _registerTokenIfSessionExists(
    String token, {
    required String reason,
    bool force = false,
  }) async {
    final hasSession = await _authTokenStore.hasSession();

    if (!hasSession) {
      return;
    }

    final normalizedToken = token.trim();

    if (normalizedToken.isEmpty) {
      return;
    }

    if (!force &&
        _lastRegisteredToken == normalizedToken) {
      return;
    }

    if (_isRegistering) {
      return;
    }

    _isRegistering = true;

    try {
      final response = await _apiClient.post(
        ApiConfig.identityUri(
          '/api/v1/identity/push-devices',
        ),
        body: {
          'token': normalizedToken,
          'platform': 'android',
        },
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        _lastRegisteredToken = normalizedToken;

        debugPrint(
          '[FCM] Dispositivo registrado en backend '
          'correctamente ($reason).',
        );

        return;
      }

      debugPrint(
        '[FCM] Backend rechazó el registro del dispositivo. '
        'status=${response.statusCode}',
      );
    } catch (error) {
      debugPrint(
        '[FCM] No fue posible registrar el dispositivo '
        'en backend: $error',
      );
    } finally {
      _isRegistering = false;
    }
  }

  Future<void> deactivateCurrentTokenForLogout() async {
    final token =
        PushNotificationService.instance.currentToken;

    if (token == null || token.trim().isEmpty) {
      _lastRegisteredToken = null;
      return;
    }

    final hasSession = await _authTokenStore.hasSession();

    if (!hasSession) {
      _lastRegisteredToken = null;
      return;
    }

    final normalizedToken = token.trim();

    try {
      final response = await _apiClient.post(
        ApiConfig.identityUri(
          '/api/v1/identity/push-devices/deactivate',
        ),
        body: {
          'token': normalizedToken,
        },
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        debugPrint(
          '[FCM] Dispositivo desactivado en backend '
          'antes del logout.',
        );
      } else {
        debugPrint(
          '[FCM] Backend rechazó la desactivación '
          'del dispositivo. status=${response.statusCode}',
        );
      }
    } catch (error) {
      // El logout local no debe quedar bloqueado
      // por un fallo de red o del servicio push.
      debugPrint(
        '[FCM] No fue posible desactivar el dispositivo '
        'antes del logout: $error',
      );
    } finally {
      _lastRegisteredToken = null;
    }
  }

  Future<void> resetForLogout() async {
    _lastRegisteredToken = null;
  }

  void dispose() {
    _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _apiClient.dispose();
    _initialized = false;
  }
}
