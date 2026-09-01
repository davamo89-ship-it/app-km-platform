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

          if (serverMessage is String &&
              serverMessage.trim().isNotEmpty) {
            message = serverMessage;
          }

          if (serverCode is String &&
              serverCode.trim().isNotEmpty) {
            code = serverCode;
          }
        }
      } on FormatException {
        // Conserva el mensaje genérico.
      }
    }

    throw AuthApiException(
      message,
      statusCode: response.statusCode,
      code: code,
    );
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  void dispose() {
    _client.close();
  }
}
