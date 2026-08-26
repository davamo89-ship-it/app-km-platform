import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isStravaConnected = false;
  bool _notificationsEnabled = true;
  bool _automaticSyncEnabled = true;

  void _toggleStravaConnection() {
    setState(() {
      _isStravaConnected = !_isStravaConnected;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isStravaConnected
              ? 'Cuenta de Strava conectada correctamente.'
              : 'Cuenta de Strava desconectada.',
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController =
        TextEditingController(text: 'David');
    final TextEditingController emailController =
        TextEditingController(text: 'david@email.com');

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Perfil actualizado correctamente.',
                    ),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Deseas cerrar la sesión actual?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushNamedAndRemoveUntil(
                  this.context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 24),
          _ProfileSection(
            title: 'Cuenta',
            children: [
              _ProfileOption(
                icon: Icons.edit_outlined,
                title: 'Editar perfil',
                subtitle: 'Nombre y correo electrónico',
                onTap: _showEditProfileDialog,
              ),
              const _OptionDivider(),
              const _ProfileOption(
                icon: Icons.lock_outline,
                title: 'Cambiar contraseña',
                subtitle: 'Actualiza tu contraseña de acceso',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProfileSection(
            title: 'Strava',
            children: [
              _StravaOption(
                isConnected: _isStravaConnected,
                onPressed: _toggleStravaConnection,
              ),
              const _OptionDivider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _automaticSyncEnabled,
                onChanged: _isStravaConnected
                    ? (value) {
                        setState(() {
                          _automaticSyncEnabled = value;
                        });
                      }
                    : null,
                secondary: const _OptionIcon(
                  icon: Icons.sync_outlined,
                ),
                title: const Text(
                  'Sincronización automática',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _isStravaConnected
                      ? 'Importar nuevas actividades automáticamente'
                      : 'Conecta Strava para activar esta opción',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProfileSection(
            title: 'Preferencias',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                secondary: const _OptionIcon(
                  icon: Icons.notifications_outlined,
                ),
                title: const Text(
                  'Notificaciones',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Recibe avisos sobre puntos y actividades',
                ),
              ),
              const _OptionDivider(),
              const _ProfileOption(
                icon: Icons.straighten_outlined,
                title: 'Unidad de distancia',
                subtitle: 'Kilómetros',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _ProfileSection(
            title: 'Información',
            children: [
              _ProfileOption(
                icon: Icons.help_outline_rounded,
                title: 'Ayuda y soporte',
                subtitle: 'Preguntas frecuentes y contacto',
              ),
              _OptionDivider(),
              _ProfileOption(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacidad',
                subtitle: 'Consulta nuestras políticas',
              ),
              _OptionDivider(),
              _ProfileOption(
                icon: Icons.info_outline_rounded,
                title: 'Acerca de App KM',
                subtitle: 'Versión MVP 1.0.0',
              ),
            ],
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(
                color: Colors.red,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 42,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'David',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'david@email.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '2,350 KM Points',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: 9,
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Esta función estará disponible próximamente.',
                ),
              ),
            );
          },
      leading: _OptionIcon(icon: icon),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.black38,
      ),
    );
  }
}

class _StravaOption extends StatelessWidget {
  const _StravaOption({
    required this.isConnected,
    required this.onPressed,
  });

  final bool isConnected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFC4C02)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          Icons.directions_run_rounded,
          color: Color(0xFFFC4C02),
        ),
      ),
      title: const Text(
        'Cuenta de Strava',
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        isConnected ? 'Cuenta conectada' : 'Sin conectar',
      ),
      trailing: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isConnected
              ? Colors.red
              : const Color(0xFFFC4C02),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
        ),
        child: Text(
          isConnected ? 'Desconectar' : 'Conectar',
        ),
      ),
    );
  }
}

class _OptionIcon extends StatelessWidget {
  const _OptionIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }
}

class _OptionDivider extends StatelessWidget {
  const _OptionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 58,
    );
  }
}