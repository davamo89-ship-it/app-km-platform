import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_dependencies.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/strava/strava_connection_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final StravaConnectionController _stravaConnectionController;

  bool _obscurePassword = true;
  bool _openingStrava = false;
  bool _navigatedAfterStravaConnection = false;

  @override
  void initState() {
    super.initState();

    final dependencies = AppDependencies.instance;

    if (!dependencies.isInitialized) {
      dependencies.initialize();
    }

    _stravaConnectionController =
        dependencies.stravaConnectionController;

    _stravaConnectionController.addListener(
      _handleStravaConnectionChange,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStravaConnectionChange();
    });
  }

  @override
  void dispose() {
    _stravaConnectionController.removeListener(
      _handleStravaConnectionChange,
    );

    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  void _handleStravaConnectionChange() {
    if (!mounted) {
      return;
    }

    final controller = _stravaConnectionController;

    if (controller.isConnected &&
        !_navigatedAfterStravaConnection) {
      _navigatedAfterStravaConnection = true;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.dashboard,
      );

      return;
    }

    if (controller.hasError) {
      setState(() {
        _openingStrava = false;
      });

      final message =
          controller.errorMessage ??
          'No fue posible completar la conexión con Strava.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );

      controller.clearError();
      return;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _login() {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.dashboard,
    );
  }

  Future<void> _continueWithStrava() async {
    if (_openingStrava ||
        _stravaConnectionController.isAuthorizing) {
      return;
    }

    setState(() {
      _openingStrava = true;
    });

    try {
      final authorizationUri =
          _stravaConnectionController.beginAuthorization();
         debugPrint('STRAVA URL: $authorizationUri');
      final opened = await launchUrl(
        authorizationUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        _stravaConnectionController.cancelAuthorization();

        throw StateError(
          'No fue posible abrir la autorización de Strava.',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _stravaConnectionController.cancelAuthorization();

      setState(() {
        _openingStrava = false;
      });

      final message = error is StateError
          ? error.message.toString()
          : 'No fue posible abrir Strava.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
    }
  }

  String _stravaButtonLabel() {
    if (_stravaConnectionController.isChecking) {
      return 'Comprobando Strava...';
    }

    if (_openingStrava ||
        _stravaConnectionController.isAuthorizing) {
      return 'Abriendo Strava...';
    }

    if (_stravaConnectionController.isConnected) {
      return 'Strava conectado';
    }

    return 'Continuar con Strava';
  }

  bool get _stravaButtonDisabled {
    return _stravaConnectionController.isChecking ||
        _openingStrava ||
        _stravaConnectionController.isAuthorizing ||
        _stravaConnectionController.isConnected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.directions_run_rounded,
                      color: Colors.white,
                      size: 72,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'APP KM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Convierte tus kilómetros en recompensas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ingresa para consultar tus puntos y actividades.',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType:
                                  TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon:
                                    Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Ingresa tu correo electrónico';
                                }

                                if (!value.contains('@')) {
                                  return 'Ingresa un correo válido';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon:
                                    const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons
                                              .visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Ingresa tu contraseña';
                                }

                                if (value.length < 6) {
                                  return 'Debe tener al menos 6 caracteres';
                                }

                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Recuperación de contraseña próximamente.',
                                        ),
                                      ),
                                    );
                                },
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _login,
                              child: const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text('o continúa con'),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Inicio con Google próximamente.',
                                      ),
                                    ),
                                  );
                              },
                              icon: const Icon(
                                Icons.g_mobiledata,
                                size: 30,
                              ),
                              label: const Text(
                                'Continuar con Google',
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _stravaButtonDisabled
                                  ? null
                                  : _continueWithStrava,
                              icon: _openingStrava ||
                                      _stravaConnectionController
                                          .isAuthorizing ||
                                      _stravaConnectionController
                                          .isChecking
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                    )
                                  : const Icon(
                                      Icons
                                          .directions_bike_outlined,
                                    ),
                              label: Text(
                                _stravaButtonLabel(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '¿No tienes cuenta?',
                                ),
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Registro de usuario próximamente.',
                                          ),
                                        ),
                                      );
                                  },
                                  child:
                                      const Text('Registrarse'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}