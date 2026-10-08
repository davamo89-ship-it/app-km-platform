import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
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

class AuthApiService {
  AuthApiService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConfig.identityUri('/api/v1/identity/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    return LoginResponse.fromJson(
      _decodeObject(response),
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConfig.identityUri('/api/v1/identity/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    _ensureSuccess(response);
  }

  Future<void> requestPasswordReset({
    required String email,
  }) async {
    final response = await _client.post(
      ApiConfig.identityUri(
        '/api/v1/identity/password-reset/request',
      ),
      headers: _headers,
      body: jsonEncode({
        'email': email.trim(),
      }),
    );

    _ensureSuccess(response);
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _client.post(
      ApiConfig.identityUri(
        '/api/v1/identity/password-reset/confirm',
      ),
      headers: _headers,
      body: jsonEncode({
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      }),
    );

    _ensureSuccess(response);
  }

  Future<LoginResponse> refresh({
    required String refreshToken,
  }) async {
    final response = await _client.post(
      ApiConfig.identityUri('/api/v1/identity/refresh'),
      headers: _headers,
      body: jsonEncode({
        'refreshToken': refreshToken,
      }),
    );

    return LoginResponse.fromJson(
      _decodeObject(response),
    );
  }

  Future<void> logout({
    required String refreshToken,
  }) async {
    final response = await _client.post(
      ApiConfig.identityUri('/api/v1/identity/logout'),
      headers: _headers,
      body: jsonEncode({
        'refreshToken': refreshToken,
      }),
    );

    _ensureSuccess(response);
  }

  void _ensureSuccess(
    http.Response response,
  ) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    _throwApiException(response);
  }

  Map<String, dynamic> _decodeObject(
    http.Response response,
  ) {
    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      _throwApiException(response);
    }

    final body = utf8.decode(response.bodyBytes);

    if (body.trim().isEmpty) {
      throw AuthApiException(
        'El servidor devolvió una respuesta vacía.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw AuthApiException(
        'La respuesta del servidor no tiene el formato esperado.',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  Never _throwApiException(
    http.Response response,
  ) {
    String message =
        'No fue posible completar la solicitud.';
    String? code;

    if (response.bodyBytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (decoded is Map<String, dynamic>) {
          final serverMessage = decoded['message'];
          final serverCode = decoded['code'];

          if (serverCode is String &&
              serverCode.trim().isNotEmpty) {
            code = serverCode;
          }

          if (serverMessage is String &&
              serverMessage.trim().isNotEmpty) {
            message = serverMessage;
          }
        }
      } on FormatException {
        // Conserva el mensaje genérico.
      }
    }

    message = _localizedMessage(
      code,
      fallback: message,
    );

    throw AuthApiException(
      message,
      statusCode: response.statusCode,
      code: code,
    );
  }

  String _localizedMessage(
    String? code, {
    required String fallback,
  }) {
    switch (code) {
      case 'Identity.Register.EmailAlreadyExists':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'Identity.Register.PasswordRequired':
        return 'La contraseña es obligatoria.';
      case 'Identity.Register.PasswordTooShort':
        return 'La contraseña debe tener al menos 8 caracteres.';
      case 'Identity.Register.PasswordRequiresUppercase':
        return 'La contraseña debe incluir al menos una letra mayúscula.';
      case 'Identity.Register.PasswordRequiresLowercase':
        return 'La contraseña debe incluir al menos una letra minúscula.';
      case 'Identity.Register.PasswordRequiresDigit':
        return 'La contraseña debe incluir al menos un número.';
      case 'Identity.Login.AccountNotActive':
        return 'La cuenta no está activa.';
      case 'Identity.PasswordReset.InvalidOrExpiredCode':
        return 'El código es inválido o ya venció.';
      default:
        return fallback;
    }
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  void dispose() {
    _client.close();
  }
}
