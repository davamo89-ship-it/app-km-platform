import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationAction {
  const PushNotificationAction({
    required this.type,
    required this.code,
    required this.status,
  });

  final String type;
  final String code;
  final String status;

  bool get isRedemptionChanged =>
      type == 'redemption_changed';

  static PushNotificationAction? fromMessage(
    RemoteMessage message,
  ) {
    final type = message.data['type']?.trim();
    final code = message.data['code']?.trim();
    final status = message.data['status']?.trim();

    if (type == null ||
        type.isEmpty ||
        code == null ||
        code.isEmpty ||
        status == null ||
        status.isEmpty) {
      return null;
    }

    return PushNotificationAction(
      type: type,
      code: code,
      status: status,
    );
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  final StreamController<PushNotificationAction>
      _openedActionController =
      StreamController<PushNotificationAction>.broadcast();

  bool _initialized = false;

  String? _currentToken;
  PushNotificationAction? _pendingOpenedAction;

  String? get currentToken => _currentToken;

  Stream<String> get tokenChanges =>
      _tokenController.stream;

  Stream<PushNotificationAction> get openedActions =>
      _openedActionController.stream;

  PushNotificationAction? takePendingOpenedAction() {
    final action = _pendingOpenedAction;
    _pendingOpenedAction = null;
    return action;
  }

  void restorePendingOpenedAction(
    PushNotificationAction action,
  ) {
    _pendingOpenedAction = action;
  }

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
      '[FCM] permissionStatus='
      '${settings.authorizationStatus.name}',
    );

    try {
      final token = await _messaging.getToken();
      _setToken(token);
    } catch (error) {
      debugPrint(
        '[FCM] No fue posible obtener el token: $error',
      );
    }

    _messaging.onTokenRefresh.listen(
      (token) {
        _setToken(
          token,
          refreshed: true,
        );
      },
      onError: (Object error) {
        debugPrint(
          '[FCM] Error al refrescar el token: $error',
        );
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
      onError: (Object error) {
        debugPrint(
          '[FCM] Error procesando apertura '
          'desde notificación: $error',
        );
      },
    );

    try {
      final initialMessage =
          await _messaging.getInitialMessage();

      if (initialMessage != null) {
        final action =
            PushNotificationAction.fromMessage(
          initialMessage,
        );

        if (action != null) {
          _pendingOpenedAction = action;

          debugPrint(
            '[FCM] Apertura inicial pendiente '
            'type=${action.type}.',
          );
        }
      }
    } catch (error) {
      debugPrint(
        '[FCM] No fue posible leer la '
        'notificación inicial: $error',
      );
    }

    _initialized = true;
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final action =
        PushNotificationAction.fromMessage(message);

    if (action == null) {
      return;
    }

    debugPrint(
      '[FCM] Notificación abierta '
      'type=${action.type}.',
    );

    _openedActionController.add(action);
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
    final preview =
        token.substring(0, previewLength);

    debugPrint(
      '[FCM] '
      '${refreshed ? 'Token refrescado' : 'Token obtenido'} '
      'correctamente. prefix=$preview... '
      'length=${token.length}',
    );
  }
}
