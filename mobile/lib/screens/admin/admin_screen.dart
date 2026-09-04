import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth/auth_api_service.dart';
import '../../services/auth/auth_token_store.dart';

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
          _AdminHomeSection(
            email: _email,
            onOpenSection: _goToSection,
          ),
          const _AdminPlaceholderSection(
            icon: Icons.directions_run_rounded,
            title: 'Atletas',
            description:
                'Aquí se administrarán los atletas registrados '
                'y su estado dentro de App KM.',
          ),
          const _AdminPlaceholderSection(
            icon: Icons.storefront_rounded,
            title: 'Comercios',
            description:
                'Aquí se administrarán los comercios registrados '
                'y su estado dentro de App KM.',
          ),
          const _AdminPlaceholderSection(
            icon: Icons.qr_code_2_rounded,
            title: 'Canjes',
            description:
                'Aquí se consultarán los canjes realizados '
                'y sus diferentes estados.',
          ),
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

class _AdminHomeSection extends StatelessWidget {
  const _AdminHomeSection({
    required this.email,
    required this.onOpenSection,
  });

  final String? email;
  final ValueChanged<int> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final sessionEmail = email?.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        28,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panel administrador',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      sessionEmail == null || sessionEmail.isEmpty
                          ? 'Sesión administrativa activa'
                          : sessionEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Gestión',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _AdminMenuCard(
          icon: Icons.directions_run_rounded,
          title: 'Atletas',
          subtitle: 'Consultar y gestionar atletas.',
          onTap: () => onOpenSection(1),
        ),
        const SizedBox(height: 12),
        _AdminMenuCard(
          icon: Icons.storefront_rounded,
          title: 'Comercios',
          subtitle: 'Consultar y gestionar comercios.',
          onTap: () => onOpenSection(2),
        ),
        const SizedBox(height: 12),
        _AdminMenuCard(
          icon: Icons.qr_code_2_rounded,
          title: 'Canjes',
          subtitle: 'Consultar el flujo de canjes.',
          onTap: () => onOpenSection(3),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.primary,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'La sesión fue validada con el rol Administrador. '
                  'Los datos operativos se conectarán en los '
                  'siguientes bloques funcionales.',
                  style: TextStyle(
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminPlaceholderSection extends StatelessWidget {
  const _AdminPlaceholderSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        28,
      ),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 42,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Todavía no se muestran datos para evitar '
                'información simulada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
