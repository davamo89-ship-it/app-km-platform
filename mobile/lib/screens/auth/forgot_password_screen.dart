import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth/auth_api_service.dart';

class ForgotPasswordScreen
    extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
  });

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _requestFormKey =
      GlobalKey<FormState>();

  final _resetFormKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _emailController;

  final _codeController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  final AuthApiService _authApiService =
      AuthApiService();

  bool _codeRequested = false;
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
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authApiService.dispose();

    super.dispose();
  }

  Future<void> _requestCode() async {
    final formState =
        _requestFormKey.currentState;

    if (formState == null ||
        !formState.validate() ||
        _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authApiService
          .requestPasswordReset(
        email: _emailController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _codeRequested = true;
      });

      _showMessage(
        'Si existe una cuenta con ese correo, '
        'recibirá un código de 6 dígitos.',
      );
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
        'No fue posible solicitar el código.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final formState =
        _resetFormKey.currentState;

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

    try {
      await _authApiService
          .confirmPasswordReset(
        email: email,
        code: _codeController.text.trim(),
        newPassword:
            _passwordController.text,
      );

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
        'No fue posible cambiar la contraseña.',
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
      return 'Ingresa una nueva contraseña';
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
          'Recuperar contraseña',
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
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Recupere su acceso',
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
                    'Enviaremos un código temporal al correo asociado a su cuenta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _requestFormKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller:
                              _emailController,
                          enabled:
                              !_codeRequested,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
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

                            if (!email
                                .contains('@')) {
                              return 'Ingresa un correo válido';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : _requestCode,
                          child: _isSubmitting &&
                                  !_codeRequested
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _codeRequested
                                      ? 'Reenviar código'
                                      : 'Enviar código',
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (_codeRequested) ...[
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 20),
                    Form(
                      key: _resetFormKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,
                        children: [
                          TextFormField(
                            controller:
                                _codeController,
                            keyboardType:
                                TextInputType
                                    .number,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                              LengthLimitingTextInputFormatter(
                                6,
                              ),
                            ],
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Código de 6 dígitos',
                              prefixIcon: Icon(
                                Icons
                                    .pin_outlined,
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().length !=
                                      6) {
                                return 'Ingresa el código de 6 dígitos';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          TextFormField(
                            controller:
                                _passwordController,
                            obscureText:
                                _obscurePassword,
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Nueva contraseña',
                              prefixIcon:
                                  const Icon(
                                Icons
                                    .lock_outline,
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
                          const SizedBox(
                            height: 16,
                          ),
                          TextFormField(
                            controller:
                                _confirmPasswordController,
                            obscureText:
                                _obscureConfirmation,
                            textInputAction:
                                TextInputAction.done,
                            onFieldSubmitted:
                                (_) {
                              if (!_isSubmitting) {
                                _resetPassword();
                              }
                            },
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Confirmar contraseña',
                              prefixIcon:
                                  const Icon(
                                Icons
                                    .lock_reset_outlined,
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
                                  _passwordController
                                      .text) {
                                return 'Las contraseñas no coinciden';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          ElevatedButton(
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : _resetPassword,
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
                                    'Cambiar contraseña',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
