import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/athletes/current_athlete.dart';
import '../../models/athletes/athlete_settings.dart';
import '../../services/athletes/athlete_api_service.dart';
import '../../services/auth/auth_token_store.dart';
import '../../services/auth/auth_api_service.dart';
import '../../services/strava/strava_backend_api_service.dart';
import '../../services/strava/strava_oauth_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  bool _notificationsEnabled = true;
  bool _automaticSyncEnabled = true;

  late final AthleteApiService _athleteApiService;
  late final AuthTokenStore _authTokenStore;
  late final AuthApiService _authApiService;
  late final StravaBackendApiService _stravaBackendApiService;
  late final StravaOAuthLauncher _stravaOAuthLauncher;

    CurrentAthlete? _athlete;
    AthleteSettings? _settings;
    String? _email;
    int _pointsBalance = 0;
    bool _isLoadingProfile = true;
    String? _profileError;
    bool _isStravaActionInProgress = false;

    @override
    void initState() {
      super.initState();

      _athleteApiService = AthleteApiService();
      _authTokenStore = AuthTokenStore();
      _authApiService = AuthApiService();
      _stravaBackendApiService = StravaBackendApiService();
      _stravaOAuthLauncher = const StravaOAuthLauncher();
      WidgetsBinding.instance.addObserver(this);

      _loadProfile();
    }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _athleteApiService.dispose();
    _authApiService.dispose();
    _stravaBackendApiService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStravaState();
    }
  }

    Future<void> _loadProfile() async {
      try {
        final athlete = await _athleteApiService.getCurrentAthlete();
        final dashboard = await _athleteApiService.getDashboard();
        final settings = await _athleteApiService.getSettings();
        final email = await _authTokenStore.getEmail();

        if (!mounted) {
          return;
        }

        setState(() {
          _athlete = athlete;
          _settings = settings;
          _email = email;
          _pointsBalance = dashboard.pointsBalance;
          _profileError = null;
          _isLoadingProfile = false;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _profileError = 'No fue posible cargar el perfil.';
          _isLoadingProfile = false;
        });
      }
    }

  Future<void> _refreshStravaState() async {
    try {
      final settings = await _athleteApiService.getSettings();

      if (!mounted) {
        return;
      }

      setState(() {
        _settings = settings;
      });
    } catch (_) {
      // El perfil ya maneja su propio estado de error.
      // Aquí evitamos mostrar errores al volver desde el navegador.
    }
  }

  Future<void> _handleStravaConnectionPressed() async {
    if (_isStravaActionInProgress) {
      return;
    }

    final isConnected = _settings?.stravaConnected ?? false;

    setState(() {
      _isStravaActionInProgress = true;
    });

    try {
      if (isConnected) {
        await _stravaBackendApiService.disconnect();
        await _refreshStravaState();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cuenta de Strava desconectada correctamente.',
            ),
          ),
        );

        return;
      }

      final connectResponse =
          await _stravaBackendApiService.getConnectUrl();

      final authorizationUri =
          Uri.parse(connectResponse.authorizationUrl);

      await _stravaOAuthLauncher.openAuthorizationUri(
        authorizationUri,
      );
    } on StravaBackendApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible completar la operación con Strava.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStravaActionInProgress = false;
        });
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    final TextEditingController nameController = TextEditingController(
      text: _athlete?.displayName ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: _email ?? '',
    );
    final TextEditingController countryController = TextEditingController(
      text: _athlete?.countryCode ?? '',
    );

    DateTime? selectedBirthDate = _athlete?.birthDate;
    String? selectedSport = _athlete?.preferredSport;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
              content: SingleChildScrollView(
                child: Column(
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
                      enabled: false,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: countryController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        labelText: 'País',
                        prefixIcon: Icon(Icons.public_outlined),
                        hintText: 'Ejemplo: CR',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedBirthDate ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1940, 1, 1),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedBirthDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                          ),
                        ),
                        child: Text(
                          selectedBirthDate == null
                              ? 'Seleccionar fecha'
                              : '${selectedBirthDate!.day.toString().padLeft(2, '0')}/'
                                  '${selectedBirthDate!.month.toString().padLeft(2, '0')}/'
                                  '${selectedBirthDate!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSport,
                      decoration: const InputDecoration(
                        labelText: 'Deporte preferido',
                        prefixIcon: Icon(
                          Icons.directions_run_outlined,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Cycling',
                          child: Text('Ciclismo'),
                        ),
                        DropdownMenuItem(
                          value: 'Running',
                          child: Text('Correr'),
                        ),
                        DropdownMenuItem(
                          value: 'Walking',
                          child: Text('Caminar'),
                        ),
                        DropdownMenuItem(
                          value: 'Swimming',
                          child: Text('Natación'),
                        ),
                        DropdownMenuItem(
                          value: 'Gym',
                          child: Text('Gimnasio'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSport = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final athlete = _athlete;

                    if (athlete == null) {
                      return;
                    }

                    final displayName = nameController.text.trim();
                    final countryCode =
                        countryController.text.trim().toUpperCase();

                    if (displayName.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'El nombre no puede estar vacío.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (countryCode.isNotEmpty &&
                        countryCode.length != 2) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'El país debe indicarse con un código de 2 letras, por ejemplo CR.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    try {
                      await _athleteApiService.updateCurrentAthlete(
                        athlete: athlete,
                        displayName: displayName,
                        countryCode:
                            countryCode.isEmpty ? null : countryCode,
                        birthDate: selectedBirthDate,
                        preferredSport: selectedSport,
                      );

                      await _loadProfile();

                      if (!mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Perfil actualizado correctamente.',
                          ),
                        ),
                      );
                    } on AthleteApiException catch (error) {
                      if (!mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(error.message),
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    countryController.dispose();
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
              onPressed: () async {
                Navigator.pop(context);

                try {
                  final refreshToken =
                      await _authTokenStore.getRefreshToken();

                  if (refreshToken != null &&
                      refreshToken.isNotEmpty) {
                    await _authApiService.logout(
                      refreshToken: refreshToken,
                    );
                  }
                } catch (_) {
                  // Aunque falle el logout remoto,
                  // eliminamos la sesión local.
                }

                await _authTokenStore.clearSession();

                if (!mounted) {
                  return;
                }

                Navigator.of(this.context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
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
          _ProfileHeader(
            displayName: _athlete?.displayName ?? 'Atleta',
            email: _email ?? '',
            points: _pointsBalance,
            isLoading: _isLoadingProfile,
          ),
          if (_profileError != null) ...[
              const SizedBox(height: 12),
              Text(
                _profileError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          const SizedBox(height: 24),
          _ProfileSection(
            title: 'Cuenta',
            children: [
              _ProfileOption(
                icon: Icons.edit_outlined,
                title: 'Editar perfil',
                subtitle: 'Nombre, país, nacimiento y deporte',
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
                isConnected: _settings?.stravaConnected ?? false,
                isBusy: _isStravaActionInProgress,
                onPressed: _handleStravaConnectionPressed,
              ),
              const _OptionDivider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _automaticSyncEnabled,
                onChanged: (_settings?.stravaConnected ?? false)
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
                  (_settings?.stravaConnected ?? false)
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
      const _ProfileHeader({
        required this.displayName,
        required this.email,
        required this.points,
        required this.isLoading,
      });

      final String displayName;
      final String email;
      final int points;
      final bool isLoading;

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
      child: Row(
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
                  isLoading ? 'Cargando...' : displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isLoading ? '' : email,
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
                      isLoading ? '' : '$points KM Points',
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
    required this.isBusy,
    required this.onPressed,
  });

  final bool isConnected;
  final bool isBusy;
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
        onPressed: isBusy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isConnected
              ? Colors.red
              : const Color(0xFFFC4C02),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
        ),
        child: Text(
          isBusy
              ? 'Procesando...'
              : isConnected
                  ? 'Desconectar'
                  : 'Conectar',
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