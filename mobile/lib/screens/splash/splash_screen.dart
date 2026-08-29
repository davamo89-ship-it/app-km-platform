import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth/auth_api_service.dart';
import '../../services/auth/auth_token_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthTokenStore _authTokenStore = AuthTokenStore();
  final AuthApiService _authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final hasSession = await _authTokenStore.hasSession();

    if (!hasSession) {
      _goToLogin();
      return;
    }

    final accessTokenExpiresAt =
        await _authTokenStore.getAccessTokenExpiresAtUtc();

    final now = DateTime.now().toUtc();

    if (accessTokenExpiresAt != null &&
        accessTokenExpiresAt.isAfter(
          now.add(const Duration(minutes: 1)),
        )) {
      _goToDashboard();
      return;
    }

    final refreshToken =
        await _authTokenStore.getRefreshToken();

    final refreshTokenExpiresAt =
        await _authTokenStore.getRefreshTokenExpiresAtUtc();

    if (refreshToken == null ||
        refreshToken.isEmpty ||
        refreshTokenExpiresAt == null ||
        !refreshTokenExpiresAt.isAfter(now)) {
      await _authTokenStore.clearSession();
      _goToLogin();
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

      _goToDashboard();
    } on AuthApiException {
      await _authTokenStore.clearSession();
      _goToLogin();
    } catch (_) {
      await _authTokenStore.clearSession();
      _goToLogin();
    }
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

  void _goToDashboard() {
    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.dashboard,
    );
  }

  @override
  void dispose() {
    _authApiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_run,
              color: Colors.white,
              size: 90,
            ),
            SizedBox(height: 24),
            Text(
              'APP KM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Entrena • Compite • Mejora',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}