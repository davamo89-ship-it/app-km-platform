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
