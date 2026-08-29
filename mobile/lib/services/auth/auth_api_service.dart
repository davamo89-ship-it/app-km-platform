import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../models/auth/login_response.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthApiService {
  AuthApiService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = ApiConfig.identityUri(
      '/api/v1/identity/login',
    );

    final response = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body)
          as Map<String, dynamic>;

      return LoginResponse.fromJson(json);
    }

    if (response.statusCode == 401) {
      throw const AuthApiException(
        'Correo electrónico o contraseña incorrectos.',
        statusCode: 401,
      );
    }

    if (response.statusCode == 403) {
      throw const AuthApiException(
        'Su usuario no tiene acceso autorizado.',
        statusCode: 403,
      );
    }

    throw AuthApiException(
      'No fue posible iniciar sesión.',
      statusCode: response.statusCode,
    );
  }
  
  Future<LoginResponse> refresh({
  required String refreshToken,
    }) async {
      final uri = ApiConfig.identityUri(
        '/api/v1/identity/refresh',
      );

      final response = await _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final json =
            jsonDecode(response.body) as Map<String, dynamic>;

        return LoginResponse.fromJson(json);
      }

      if (response.statusCode == 401) {
        throw const AuthApiException(
          'La sesión ha expirado.',
          statusCode: 401,
        );
      }

      throw AuthApiException(
        'No fue posible renovar la sesión.',
        statusCode: response.statusCode,
      );
    }

  void dispose() {
    _client.close();
  }
}