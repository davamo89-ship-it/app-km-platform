import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_api_service.dart';
import '../auth/auth_token_store.dart';

class AuthenticatedApiException implements Exception {
  const AuthenticatedApiException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthenticatedApiClient {
  AuthenticatedApiClient({
    http.Client? client,
    AuthTokenStore? tokenStore,
    AuthApiService? authApiService,
  })  : _client = client ?? http.Client(),
        _tokenStore = tokenStore ?? AuthTokenStore(),
        _authApiService = authApiService ?? AuthApiService();

  final http.Client _client;
  final AuthTokenStore _tokenStore;
  final AuthApiService _authApiService;

  Future<http.Response> get(Uri uri) async {
    return _sendWithAuthentication(
      (headers) => _client.get(
        uri,
        headers: headers,
      ),
    );
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    return _sendWithAuthentication(
      (headers) => _client.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<http.Response> patch(
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    return _sendWithAuthentication(
      (headers) => _client.patch(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<http.Response> delete(Uri uri) async {
    return _sendWithAuthentication(
      (headers) => _client.delete(
        uri,
        headers: headers,
      ),
    );
  }

  Future<http.Response> _sendWithAuthentication(
    Future<http.Response> Function(
      Map<String, String> headers,
    ) request,
  ) async {
    var accessToken = await _getValidAccessToken();

    var response = await request(
      _headers(accessToken),
    );

    if (response.statusCode != 401) {
      return response;
    }

    accessToken = await _refreshAccessToken();

    response = await request(
      _headers(accessToken),
    );

    return response;
  }

  Future<String> _getValidAccessToken() async {
    final accessToken =
        await _tokenStore.getAccessToken();

    final expiresAt =
        await _tokenStore.getAccessTokenExpiresAtUtc();

    final now = DateTime.now().toUtc();

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        expiresAt != null &&
        expiresAt.isAfter(
          now.add(const Duration(minutes: 1)),
        )) {
      return accessToken;
    }

    return _refreshAccessToken();
  }

  Future<String> _refreshAccessToken() async {
    final refreshToken =
        await _tokenStore.getRefreshToken();

    final refreshExpiresAt =
        await _tokenStore.getRefreshTokenExpiresAtUtc();

    final now = DateTime.now().toUtc();

    if (refreshToken == null ||
        refreshToken.isEmpty ||
        refreshExpiresAt == null ||
        !refreshExpiresAt.isAfter(now)) {
      await _tokenStore.clearSession();

      throw const AuthenticatedApiException(
        'La sesión ha expirado.',
        statusCode: 401,
      );
    }

    try {
      final refreshedSession =
          await _authApiService.refresh(
        refreshToken: refreshToken,
      );

      await _tokenStore.saveSession(
        refreshedSession,
      );

      return refreshedSession.accessToken;
    } on AuthApiException {
      await _tokenStore.clearSession();

      throw const AuthenticatedApiException(
        'La sesión ha expirado.',
        statusCode: 401,
      );
    }
  }

  Map<String, String> _headers(
    String accessToken,
  ) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  void dispose() {
    _client.close();
    _authApiService.dispose();
  }
}