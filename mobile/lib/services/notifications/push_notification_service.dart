import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  bool _initialized = false;

  String? _currentToken;

  String? get currentToken => _currentToken;

  Stream<String> get tokenChanges => _tokenController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      '[FCM] permissionStatus=${settings.authorizationStatus.name}',
    );

    try {
      final token = await _messaging.getToken();

      _setToken(token);
    } catch (error) {
      debugPrint('[FCM] No fue posible obtener el token: $error');
    }

    _messaging.onTokenRefresh.listen(
      (token) {
        _setToken(
          token,
          refreshed: true,
        );
      },
      onError: (Object error) {
        debugPrint('[FCM] Error al refrescar el token: $error');
      },
    );

    _initialized = true;
  }

  void _setToken(
    String? token, {
    bool refreshed = false,
  }) {
    if (token == null || token.trim().isEmpty) {
      debugPrint('[FCM] Token no disponible.');
      return;
    }

    final normalized = token.trim();

    _currentToken = normalized;

    _logTokenState(
      normalized,
      refreshed: refreshed,
    );

    _tokenController.add(normalized);
  }

  void _logTokenState(
    String token, {
    bool refreshed = false,
  }) {
    final previewLength =
        token.length >= 12 ? 12 : token.length;
    final preview = token.substring(0, previewLength);

    debugPrint(
      '[FCM] ${refreshed ? 'Token refrescado' : 'Token obtenido'} '
      'correctamente. prefix=$preview... length=${token.length}',
    );
  }
}
