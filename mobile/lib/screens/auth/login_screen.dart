import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth/auth_api_service.dart';
import '../../services/auth/auth_token_store.dart';
import '../../services/auth/role_access_service.dart';
import '../merchants/merchant_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthApiService _authApiService = AuthApiService();
  final AuthTokenStore _authTokenStore = AuthTokenStore();
  final RoleAccessService _roleAccessService =
      RoleAccessService();

  bool _isLoggingIn = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authApiService.dispose();
    _roleAccessService.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    if (_isLoggingIn) {
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final result = await _authApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _authTokenStore.saveSession(result);

      final role =
          await _roleAccessService.resolveCurrentRole();

      if (!mounted) {
        return;
      }

      await _navigateForRole(role);
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on RoleAccessException catch (error) {
      await _authTokenStore.clearSession();

      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      await _authTokenStore.clearSession();

      if (!mounted) {
        return;
      }

      _showMessage(
        'No fue posible conectar con el servidor.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  Future<void> _navigateForRole(
    AppUserRole role,
  ) async {
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
            builder: (_) => const MerchantScreen(),
          ),
        );
        return;

      case AppUserRole.admin:
        await _authTokenStore.clearSession();

        if (!mounted) {
          return;
        }

        _showMessage(
          'La interfaz de administración todavía '
          'no está disponible en la app móvil.',
        );
        return;

      case AppUserRole.unknown:
        await _authTokenStore.clearSession();

        if (!mounted) {
          return;
        }

        _showMessage(
          'La cuenta no tiene un rol compatible '
          'con esta versión de la app.',
        );
        return;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
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
                        borderRadius:
                            BorderRadius.circular(24),
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
                                fontWeight:
                                    FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ingresa con tu cuenta de atleta o comercio.',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller:
                                  _emailController,
                              keyboardType:
                                  TextInputType
                                      .emailAddress,
                              textInputAction:
                                  TextInputAction.next,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Correo electrónico',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value
                                        .trim()
                                        .isEmpty) {
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
                              controller:
                                  _passwordController,
                              obscureText:
                                  _obscurePassword,
                              textInputAction:
                                  TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!_isLoggingIn) {
                                  _login();
                                }
                              },
                              decoration:
                                  InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon:
                                    const Icon(
                                  Icons.lock_outline,
                                ),
                                suffixIcon:
                                    IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons
                                            .visibility_outlined
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
                              alignment:
                                  Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _showMessage(
                                    'Recuperación de contraseña próximamente.',
                                  );
                                },
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _isLoggingIn
                                  ? null
                                  : _login,
                              child: _isLoggingIn
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar sesión',
                                      style:
                                          TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Strava se conecta desde el perfil del atleta '
                              'después de iniciar sesión.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '¿No tienes cuenta?',
                                ),
                                TextButton(
                                  onPressed: () {
                                    _showMessage(
                                      'Registro de usuario próximamente.',
                                    );
                                  },
                                  child: const Text(
                                    'Registrarse',
                                  ),
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
