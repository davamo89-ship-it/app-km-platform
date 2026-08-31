import 'dart:convert';

import '../../core/config/api_config.dart';
import '../../models/strava/strava_activity.dart';
import '../../models/strava/strava_connect_response.dart';
import '../../models/strava/strava_connection_status.dart';
import '../../models/strava/strava_sync_result.dart';
import '../api/authenticated_api_client.dart';

class StravaBackendApiService {
  StravaBackendApiService({
    AuthenticatedApiClient? client,
  }) : _client = client ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _client;

  Future<StravaConnectResponse> getConnectUrl() async {
    final uri = ApiConfig.athletesUri(
      '/api/v1/athletes/strava/connect',
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final json =
          jsonDecode(response.body) as Map<String, dynamic>;

      return StravaConnectResponse.fromJson(json);
    }

    throw _buildException(
      response.statusCode,
      responseBody: response.body,
      defaultMessage:
          'No fue posible iniciar la conexión con Strava.',
    );
  }

  Future<StravaConnectionStatus> getStatus() async {
    final uri = ApiConfig.athletesUri(
      '/api/v1/athletes/strava/status',
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final json =
          jsonDecode(response.body) as Map<String, dynamic>;

      return StravaConnectionStatus.fromJson(json);
    }

    throw _buildException(
      response.statusCode,
      responseBody: response.body,
      defaultMessage:
          'No fue posible consultar el estado de Strava.',
    );
  }

  Future<List<StravaActivity>> getActivities({
    DateTime? after,
    DateTime? before,
    int page = 1,
    int perPage = 100,
  }) async {
    final baseUri = ApiConfig.athletesUri(
      '/api/v1/athletes/strava/activities',
    );

    final queryParameters = <String, String>{
      'page': page.toString(),
      'perPage': perPage.toString(),
      if (after != null) 'after': after.toUtc().toIso8601String(),
      if (before != null) 'before': before.toUtc().toIso8601String(),
    };

    final uri = baseUri.replace(
      queryParameters: queryParameters,
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw const StravaBackendApiException(
          'El servidor devolvió un formato inesperado para las actividades.',
        );
      }

      return decoded
          .map(
            (item) => StravaActivity.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw _buildException(
      response.statusCode,
      responseBody: response.body,
      defaultMessage:
          'No fue posible obtener las actividades de Strava.',
    );
  }

  Future<StravaSyncResult> syncActivities() async {
    final uri = ApiConfig.athletesUri(
      '/api/v1/athletes/strava/sync',
    );

    final response = await _client.post(uri);

    if (response.statusCode == 200) {
      final json =
          jsonDecode(response.body) as Map<String, dynamic>;

      return StravaSyncResult.fromJson(json);
    }

    throw _buildException(
      response.statusCode,
      responseBody: response.body,
      defaultMessage:
          'No fue posible sincronizar las actividades de Strava.',
    );
  }

  Future<void> disconnect() async {
    final uri = ApiConfig.athletesUri(
      '/api/v1/athletes/strava/disconnect',
    );

    final response = await _client.delete(uri);

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      return;
    }

    throw _buildException(
      response.statusCode,
      responseBody: response.body,
      defaultMessage:
          'No fue posible desconectar la cuenta de Strava.',
    );
  }

  StravaBackendApiException _buildException(
    int statusCode, {
    String? responseBody,
    required String defaultMessage,
  }) {
    if (statusCode == 401) {
      return const StravaBackendApiException(
        'La sesión ha expirado.',
        statusCode: 401,
      );
    }

    if (statusCode == 403) {
      return const StravaBackendApiException(
        'La cuenta actual no tiene permisos de atleta.',
        statusCode: 403,
      );
    }

    String? backendCode;
    String? backendMessage;

    if (responseBody != null &&
        responseBody.trim().isNotEmpty) {
      try {
        final decoded =
            jsonDecode(responseBody) as Map<String, dynamic>;

        backendCode = decoded['code'] as String?;
        backendMessage = decoded['message'] as String?;
      } catch (_) {
        // Si el backend no devuelve JSON, usamos el mensaje
        // definido por la aplicación.
      }
    }

    return StravaBackendApiException(
      backendMessage?.trim().isNotEmpty == true
          ? backendMessage!
          : defaultMessage,
      statusCode: statusCode,
      code: backendCode,
    );
  }

  void dispose() {
    _client.dispose();
  }
}

class StravaBackendApiException implements Exception {
  const StravaBackendApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() {
    return 'StravaBackendApiException('
        'statusCode: $statusCode, '
        'code: $code, '
        'message: $message'
        ')';
  }
}
