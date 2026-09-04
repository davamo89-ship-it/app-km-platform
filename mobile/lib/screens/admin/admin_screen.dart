import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth/auth_api_service.dart';
import '../../services/auth/auth_token_store.dart';
import 'admin_athletes_section.dart';
import 'admin_merchants_section.dart';
import 'admin_redemptions_section.dart';
import 'admin_summary_section.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthApiService _authApiService = AuthApiService();
  final AuthTokenStore _authTokenStore = AuthTokenStore();

  int _currentIndex = 0;
  String? _email;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadLocalSessionInfo();
  }

  @override
  void dispose() {
    _authApiService.dispose();
    super.dispose();
  }

  Future<void> _loadLocalSessionInfo() async {
    final email = await _authTokenStore.getEmail();

    if (!mounted) {
      return;
    }

    setState(() {
      _email = email;
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final refreshToken =
          await _authTokenStore.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await _authApiService.logout(
            refreshToken: refreshToken,
          );
        } catch (_) {
          // Aunque falle el cierre remoto,
          // siempre eliminamos la sesión local.
        }
      }

      await _authTokenStore.clearSession();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Desea cerrar la sesión de administración?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  void _goToSection(int index) {
    if (index < 0 || index > 3) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        title: const Text(
          'Administración',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _isLoggingOut ? null : _confirmLogout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AdminSummarySection(
            email: _email,
            onOpenSection: _goToSection,
          ),
          const AdminAthletesSection(),
          const AdminMerchantsSection(),
          const AdminRedemptionsSection(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToSection,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run_rounded),
            label: 'Atletas',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Comercios',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2_rounded),
            label: 'Canjes',
          ),
        ],
      ),
    );
  }
}
