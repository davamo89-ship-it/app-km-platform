import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth/auth_api_service.dart';
import '../../services/auth/auth_token_store.dart';
import '../../services/auth/role_access_service.dart';
import '../../services/notifications/push_device_registration_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.initialEmail = '',
  });

  final String initialEmail;

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController
      _emailController;

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  final AuthApiService _authApiService =
      AuthApiService();

  final AuthTokenStore _authTokenStore =
      AuthTokenStore();

  final RoleAccessService _roleAccessService =
      RoleAccessService();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController(
      text: widget.initialEmail,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authApiService.dispose();
    _roleAccessService.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    final formState = _formKey.currentState;

    if (formState == null ||
        !formState.validate() ||
        _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text;

    try {
      final registration = await _authApiService.register(
        email: email,
        password: password,
      );

      if (registration.requiresConfirmation) {
        final confirmationCode =
            await _requestConfirmationCode(email);

        if (confirmationCode == null) {
          return;
        }

        await _authApiService.confirmRegistration(
          email: email,
          code: confirmationCode,
        );
      }

      // Cognito ya confirmó la cuenta; iniciamos sesión.
      // Si por algún motivo no fuera posible, la cuenta
      // ya quedó creada y se regresa al login.
      try {
        final session =
            await _authApiService.login(
          email: email,
          password: password,
        );

        await _authTokenStore.saveSession(
          session,
        );

        await PushDeviceRegistrationService
            .instance
            .syncCurrentToken();

        final role =
            await _roleAccessService
                .resolveCurrentRole();

        if (!mounted) {
          return;
        }

        if (role == AppUserRole.athlete) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
          return;
        }
      } catch (_) {
        await _authTokenStore.clearSession();
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, email);
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'No fue posible crear la cuenta.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña';
    }

    if (value.length < 8) {
      return 'Debe tener al menos 8 caracteres';
    }

    if (!value.contains(
      RegExp(r'[A-Z]'),
    )) {
      return 'Debe incluir una letra mayúscula';
    }

    if (!value.contains(
      RegExp(r'[a-z]'),
    )) {
      return 'Debe incluir una letra minúscula';
    }

    if (!value.contains(
      RegExp(r'[0-9]'),
    )) {
      return 'Debe incluir un número';
    }

    return null;
  }

  Future<String?> _requestConfirmationCode(String email) async {
    final controller = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Confirmar correo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AWS Cognito envió un código de confirmación a $email.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Código de confirmación',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
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
      appBar: AppBar(
        title: const Text(
          'Crear cuenta',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 430,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Crea tu cuenta de atleta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight:
                            FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Usa un correo al que tengas acceso. '
                      'La cuenta quedará lista para iniciar sesión.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller:
                          _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
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
                        final email =
                            value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Ingresa tu correo electrónico';
                        }

                        if (!email.contains('@')) {
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
                          TextInputAction.next,
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
                      validator:
                          _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller:
                          _confirmPasswordController,
                      obscureText:
                          _obscureConfirmation,
                      textInputAction:
                          TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_isSubmitting) {
                          _register();
                        }
                      },
                      decoration:
                          InputDecoration(
                        labelText:
                            'Confirmar contraseña',
                        prefixIcon:
                            const Icon(
                          Icons.lock_reset_outlined,
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmation =
                                  !_obscureConfirmation;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value !=
                            _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'La contraseña debe tener al menos 8 caracteres, '
                      'una mayúscula, una minúscula y un número.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : _register,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Crear cuenta',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
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
