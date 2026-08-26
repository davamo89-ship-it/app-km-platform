import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/strava_config.dart';
import '../../models/strava_activity.dart';
import '../../models/strava_auth_result.dart';
import '../../models/strava_token.dart';
import 'strava_activity_mapper.dart';
import 'strava_api_client.dart';
import 'strava_api_exception.dart';

class HttpStravaApiClient extends StravaApiClient {
  HttpStravaApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<StravaAuthResult> exchangeCode({
    required String authorizationCode,
  }) async {
    final code = authorizationCode.trim();

    if (code.isEmpty) {
      throw const StravaApiException(
        message: 'El código de autorización está vacío.',
      );
    }

    final uri = StravaConfig.buildBackendUri('/strava/oauth/exchange');

    final response = await _postJson(
      uri,
      body: {'code': code, 'redirect_uri': StravaConfig.redirectUri},
    );


    return StravaAuthResult.fromJson(response);
  }

  @override
  Future<StravaToken> refreshToken({required String refreshToken}) async {
    final token = refreshToken.trim();

    if (token.isEmpty) {
      throw const StravaApiException(message: 'El refresh token está vacío.');
    }

    final uri = StravaConfig.buildBackendUri('/strava/oauth/refresh');

    final response = await _postJson(uri, body: {'refresh_token': token});

    return StravaToken.fromJson(response);
  }

  @override
  Future<StravaAthlete> getAthlete({required String accessToken}) async {
    final uri = Uri.parse('${StravaConfig.apiBaseUrl}/athlete');

    final response = await _getJson(uri, accessToken: accessToken);

    return StravaAthlete.fromJson(response);
  }

  @override
  Future<List<StravaActivity>> getActivities({
    required String accessToken,
    DateTime? after,
    DateTime? before,
    int page = 1,
    int perPage = 30,
  }) async {
    if (page < 1) {
      throw ArgumentError('La página debe ser mayor o igual a 1.');
    }

    if (perPage < 1 || perPage > 200) {
      throw ArgumentError('perPage debe estar entre 1 y 200.');
    }

    final queryParameters = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (after != null) 'after': _toUnixSeconds(after).toString(),
      if (before != null) 'before': _toUnixSeconds(before).toString(),
    };

    final uri = Uri.parse(
      '${StravaConfig.apiBaseUrl}/athlete/activities',
    ).replace(queryParameters: queryParameters);

    final response = await _getJsonList(uri, accessToken: accessToken);

    return response.map(StravaActivityMapper.fromJson).toList(growable: false);
  }

  Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    required String accessToken,
  }) async {
    final response = await _httpClient.get(
      uri,
      headers: _authorizationHeaders(accessToken),
    );

    return _decodeObjectResponse(response, endpoint: uri.toString());
  }

  Future<List<Map<String, dynamic>>> _getJsonList(
    Uri uri, {
    required String accessToken,
  }) async {
    final response = await _httpClient.get(
      uri,
      headers: _authorizationHeaders(accessToken),
    );

    _ensureSuccessful(response, endpoint: uri.toString());

    final decoded = _decodeJson(response.body);

    if (decoded is! List) {
      throw StravaApiException(
        message: 'La respuesta no contiene una lista válida.',
        statusCode: response.statusCode,
        endpoint: uri.toString(),
        responseBody: response.body,
      );
    }

    return decoded
        .map((item) {
          if (item is! Map) {
            throw const FormatException(
              'Una actividad recibida no tiene formato JSON válido.',
            );
          }

          return Map<String, dynamic>.from(item);
        })
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return _decodeObjectResponse(response, endpoint: uri.toString());
  }

  Map<String, dynamic> _decodeObjectResponse(
    http.Response response, {
    required String endpoint,
  }) {
    _ensureSuccessful(response, endpoint: endpoint);

    final decoded = _decodeJson(response.body);

    if (decoded is! Map) {
      throw StravaApiException(
        message: 'La respuesta no contiene un objeto JSON válido.',
        statusCode: response.statusCode,
        endpoint: endpoint,
        responseBody: response.body,
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw StravaApiException(
        message: 'El servidor devolvió una respuesta JSON inválida.',
        responseBody: body,
      );
    }
  }

  void _ensureSuccessful(http.Response response, {required String endpoint}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw StravaApiException(
      message: _resolveErrorMessage(response),
      statusCode: response.statusCode,
      endpoint: endpoint,
      responseBody: response.body,
    );
  }

  String _resolveErrorMessage(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return 'La solicitud enviada no es válida.';
      case 401:
        return 'La sesión de Strava no es válida o expiró.';
      case 403:
        return 'Strava rechazó el acceso solicitado.';
      case 404:
        return 'El recurso solicitado no existe.';
      case 429:
        return 'Se alcanzó el límite temporal de solicitudes a Strava.';
      default:
        if (response.statusCode >= 500) {
          return 'Strava no está disponible temporalmente.';
        }

        return 'La solicitud a Strava no pudo completarse.';
    }
  }

  Map<String, String> _authorizationHeaders(String accessToken) {
    final token = accessToken.trim();

    if (token.isEmpty) {
      throw const StravaApiException(message: 'El access token está vacío.');
    }

    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  int _toUnixSeconds(DateTime dateTime) {
    return dateTime.toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  void close() {
    _httpClient.close();
  }
}
