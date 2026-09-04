import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth/auth_api_service.dart';
import '../../services/auth/auth_token_store.dart';
import '../../services/auth/role_access_service.dart';
import '../merchants/merchant_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthTokenStore _authTokenStore = AuthTokenStore();
  final AuthApiService _authApiService = AuthApiService();
  final RoleAccessService _roleAccessService =
      RoleAccessService();

  bool _isChecking = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession({
    bool withInitialDelay = true,
  }) async {
    if (_isChecking && !withInitialDelay) {
      return;
    }

    if (mounted) {
      setState(() {
        _isChecking = true;
        _errorMessage = null;
      });
    }

    if (withInitialDelay) {
      await Future.delayed(
        const Duration(seconds: 2),
      );
    }

    try {
      final hasSession =
          await _authTokenStore.hasSession();

      if (!hasSession) {
        _goToLogin();
        return;
      }

      final accessTokenExpiresAt =
          await _authTokenStore
              .getAccessTokenExpiresAtUtc();

      final now = DateTime.now().toUtc();

      if (accessTokenExpiresAt != null &&
          accessTokenExpiresAt.isAfter(
            now.add(const Duration(minutes: 1)),
          )) {
        await _goToRoleDestination();
        return;
      }

      final refreshToken =
          await _authTokenStore.getRefreshToken();

      final refreshTokenExpiresAt =
          await _authTokenStore
              .getRefreshTokenExpiresAtUtc();

      if (refreshToken == null ||
          refreshToken.isEmpty ||
          refreshTokenExpiresAt == null ||
          !refreshTokenExpiresAt.isAfter(now)) {
        await _clearSessionAndGoToLogin();
        return;
      }

      try {
        final refreshedSession =
            await _authApiService.refresh(
          refreshToken: refreshToken,
        );

        await _authTokenStore.saveSession(
          refreshedSession,
        );
      } on AuthApiException catch (error) {
        if (error.statusCode == 401) {
          await _clearSessionAndGoToLogin();
          return;
        }

        _showConnectionError(
          'No fue posible renovar la sesión en este momento. '
          'Revise su conexión e intente nuevamente.',
        );
        return;
      } catch (_) {
        _showConnectionError(
          'No fue posible conectar con App KM. '
          'Revise su conexión e intente nuevamente.',
        );
        return;
      }

      await _goToRoleDestination();
    } catch (_) {
      _showConnectionError(
        'No fue posible comprobar la sesión. '
        'Intente nuevamente.',
      );
    }
  }

  Future<void> _goToRoleDestination() async {
    try {
      final role =
          await _roleAccessService.resolveCurrentRole();

      if (!mounted) {
        return;
      }

      switch (role) {
        case AppUserRole.athlete:
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.dashboard,
          );
          return;

        case AppUserRole.merchant:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const MerchantScreen(),
            ),
          );
          return;

        case AppUserRole.admin:
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.admin,
          );
          return;

        case AppUserRole.unknown:
          await _clearSessionAndGoToLogin();
          return;
      }
    } on RoleAccessException catch (error) {
      if (error.statusCode == 401) {
        await _clearSessionAndGoToLogin();
        return;
      }

      _showConnectionError(
        'No fue posible validar el tipo de usuario. '
        'Intente nuevamente.',
      );
    } catch (_) {
      _showConnectionError(
        'No fue posible conectar con App KM. '
        'Revise su conexión e intente nuevamente.',
      );
    }
  }

  void _showConnectionError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isChecking = false;
      _errorMessage = message;
    });
  }

  Future<void> _clearSessionAndGoToLogin() async {
    await _authTokenStore.clearSession();
    _goToLogin();
  }

  void _goToLogin() {
    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _authApiService.dispose();
    _roleAccessService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_run,
                  color: Colors.white,
                  size: 90,
                ),
                const SizedBox(height: 24),
                const Text(
                  'APP KM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Entrena • Compite • Mejora',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 38),
                if (_isChecking) ...[
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Comprobando sesión...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: Colors.white,
                    size: 38,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      _checkSession(
                        withInitialDelay: false,
                      );
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text(
                      'Reintentar',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
