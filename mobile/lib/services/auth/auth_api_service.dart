import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart' as app_api;
import '../../models/auth/login_response.dart';

class AuthApiException implements Exception {
  const AuthApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class AuthRegistrationResult {
  const AuthRegistrationResult({
    required this.requiresConfirmation,
  });

  final bool requiresConfirmation;
}

class AuthApiService {
  AuthApiService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email.trim(),
        password: password,
      );

      if (!result.isSignedIn) {
        throw const AuthApiException(
          'El inicio de sesión requiere un paso adicional que esta versión todavía no puede completar.',
        );
      }

      return await _buildSession(
        emailHint: email.trim(),
      );
    } on AuthApiException {
      rethrow;
    } on UserNotConfirmedException {
      throw const AuthApiException(
        'Debe confirmar su correo electrónico antes de iniciar sesión.',
        code: 'Cognito.UserNotConfirmed',
      );
    } on NotAuthorizedServiceException {
      throw const AuthApiException(
        'Correo o contraseña incorrectos.',
        statusCode: 401,
        code: 'Cognito.NotAuthorized',
      );
    } on AuthException catch (error) {
      throw AuthApiException(error.message);
    }
  }

  Future<AuthRegistrationResult> register({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim();
      final result = await Amplify.Auth.signUp(
        username: normalizedEmail,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: normalizedEmail,
          },
        ),
      );

      return AuthRegistrationResult(
        requiresConfirmation: !result.isSignUpComplete,
      );
    } on UsernameExistsException {
      throw const AuthApiException(
        'Ya existe una cuenta con este correo electrónico.',
        code: 'Cognito.UsernameExists',
      );
    } on AuthException catch (error) {
      throw AuthApiException(error.message);
    }
  }

  Future<void> confirmRegistration({
    required String email,
    required String code,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email.trim(),
        confirmationCode: code.trim(),
      );

      if (!result.isSignUpComplete) {
        throw const AuthApiException(
          'No fue posible completar la confirmación de la cuenta.',
        );
      }
    } on CodeMismatchException {
      throw const AuthApiException('El código de confirmación no es válido.');
    } on ExpiredCodeException {
      throw const AuthApiException('El código de confirmación ya venció.');
    } on AuthException catch (error) {
      throw AuthApiException(error.message);
    }
  }

  Future<void> requestPasswordReset({
    required String email,
  }) async {
    try {
      await Amplify.Auth.resetPassword(
        username: email.trim(),
      );
    } on AuthException catch (error) {
      // Cognito puede devolver UserNotFound. La UI evita enumeración de cuentas
      // manteniendo un mensaje genérico para el usuario.
      if (error is UserNotFoundException) {
        return;
      }
      throw AuthApiException(error.message);
    }
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email.trim(),
        newPassword: newPassword,
        confirmationCode: code.trim(),
      );
    } on CodeMismatchException {
      throw const AuthApiException('El código es inválido.');
    } on ExpiredCodeException {
      throw const AuthApiException('El código ya venció.');
    } on AuthException catch (error) {
      throw AuthApiException(error.message);
    }
  }

  Future<LoginResponse> refresh({
    required String refreshToken,
  }) async {
    // El refresh token lo administra Amplify de forma segura. El parámetro se
    // conserva temporalmente para no romper el contrato de la app existente.
    try {
      return await _buildSession(forceRefresh: true);
    } on AuthApiException {
      rethrow;
    } on AuthException catch (error) {
      throw AuthApiException(
        error.message,
        statusCode: 401,
      );
    }
  }

  Future<void> logout({
    required String refreshToken,
  }) async {
    try {
      await Amplify.Auth.signOut();
    } on AuthException catch (error) {
      throw AuthApiException(error.message);
    }
  }

  Future<LoginResponse> _buildSession({
    bool forceRefresh = false,
    String? emailHint,
  }) async {
    final cognito = Amplify.Auth.getPlugin(
      AmplifyAuthCognito.pluginKey,
    );

    final session = await cognito.fetchAuthSession(
      options: FetchAuthSessionOptions(
        forceRefresh: forceRefresh,
      ),
    );

    if (!session.isSignedIn) {
      throw const AuthApiException(
        'La sesión ha expirado.',
        statusCode: 401,
      );
    }

    final tokens = session.userPoolTokensResult.value;
    final accessToken = tokens.accessToken.raw;
    final refreshToken = tokens.refreshToken;
    final email = (tokens.idToken.email ?? emailHint ?? '').trim();

    if (email.isEmpty) {
      throw const AuthApiException(
        'Cognito no devolvió el correo de la cuenta.',
      );
    }

    final provisionResponse = await _client.post(
      app_api.ApiConfig.identityUri('/api/v1/identity/provision-cognito'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'email': email}),
    );

    if (provisionResponse.statusCode < 200 ||
        provisionResponse.statusCode >= 300) {
      _throwHttpException(provisionResponse);
    }

    final provisionJson = jsonDecode(
      utf8.decode(provisionResponse.bodyBytes),
    ) as Map<String, dynamic>;

    return LoginResponse(
      userId: provisionJson['userId'] as String,
      email: provisionJson['email'] as String,
      accessToken: accessToken,
      accessTokenExpiresAtUtc: _readJwtExpiration(accessToken),
      refreshToken: refreshToken,
      refreshTokenExpiresAtUtc:
          DateTime.now().toUtc().add(const Duration(days: 30)),
    );
  }

  DateTime _readJwtExpiration(String token) {
    try {
      final parts = token.split('.');
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final exp = json['exp'] as num;
      return DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
    } catch (_) {
      return DateTime.now().toUtc().add(const Duration(minutes: 55));
    }
  }

  Never _throwHttpException(http.Response response) {
    var message = 'No fue posible preparar la cuenta de App KM.';
    String? code;

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] is String) {
          message = decoded['message'] as String;
        }
        if (decoded['code'] is String) {
          code = decoded['code'] as String;
        }
      }
    } catch (_) {
      // Mantener mensaje genérico.
    }

    throw AuthApiException(
      message,
      statusCode: response.statusCode,
      code: code,
    );
  }

  void dispose() {
    _client.close();
  }
}
