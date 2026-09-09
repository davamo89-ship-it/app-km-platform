import 'dart:async';

import 'package:flutter/material.dart';

import '../../screens/merchants/merchant_screen.dart';
import '../../screens/redemptions/redemptions_screen.dart';
import '../auth/auth_token_store.dart';
import '../auth/role_access_service.dart';
import 'push_notification_service.dart';

class PushNotificationNavigationService {
  PushNotificationNavigationService._();

  static final PushNotificationNavigationService instance =
      PushNotificationNavigationService._();

  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final AuthTokenStore _authTokenStore =
      AuthTokenStore();

  final RoleAccessService _roleAccessService =
      RoleAccessService();

  StreamSubscription<PushNotificationAction>?
      _openedActionSubscription;

  bool _initialized = false;
  bool _isHandlingAction = false;

  void initialize() {
    if (_initialized) {
      return;
    }

    _openedActionSubscription =
        PushNotificationService.instance.openedActions.listen(
      (action) async {
        await _handleOpenedAction(action);
      },
    );

    _initialized = true;
  }

  Future<bool> openPendingForRole(
    AppUserRole role,
  ) async {
    final action =
        PushNotificationService.instance
            .takePendingOpenedAction();

    if (action == null) {
      return false;
    }

    if (!action.isRedemptionChanged) {
      return false;
    }

    final opened = await _navigateForRole(
      role,
      action,
    );

    if (!opened) {
      PushNotificationService.instance
          .restorePendingOpenedAction(action);
    }

    return opened;
  }

  Future<void> _handleOpenedAction(
    PushNotificationAction action,
  ) async {
    if (_isHandlingAction ||
        !action.isRedemptionChanged) {
      return;
    }

    _isHandlingAction = true;

    try {
      final hasSession =
          await _authTokenStore.hasSession();

      if (!hasSession) {
        PushNotificationService.instance
            .restorePendingOpenedAction(action);
        return;
      }

      final role =
          await _roleAccessService.resolveCurrentRole();

      final opened =
          await _navigateForRole(role, action);

      if (!opened) {
        PushNotificationService.instance
            .restorePendingOpenedAction(action);
      }
    } catch (error) {
      PushNotificationService.instance
          .restorePendingOpenedAction(action);

      debugPrint(
        '[FCM] No fue posible navegar '
        'desde la notificación: $error',
      );
    } finally {
      _isHandlingAction = false;
    }
  }

  Future<bool> _navigateForRole(
    AppUserRole role,
    PushNotificationAction action,
  ) async {
    if (!action.isRedemptionChanged) {
      return false;
    }

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      PushNotificationService.instance
          .restorePendingOpenedAction(action);
      return false;
    }

    switch (role) {
      case AppUserRole.athlete:
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) =>
                const RedemptionsScreen(),
          ),
          (route) => false,
        );

        debugPrint(
          '[FCM] Navegación a canjes del atleta '
          'desde push.',
        );

        return true;

      case AppUserRole.merchant:
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) =>
                const MerchantScreen(),
          ),
          (route) => false,
        );

        debugPrint(
          '[FCM] Navegación a comercio '
          'desde push.',
        );

        return true;

      case AppUserRole.admin:
      case AppUserRole.unknown:
        return false;
    }
  }

  void dispose() {
    _openedActionSubscription?.cancel();
    _openedActionSubscription = null;
    _roleAccessService.dispose();
    _initialized = false;
  }
}
