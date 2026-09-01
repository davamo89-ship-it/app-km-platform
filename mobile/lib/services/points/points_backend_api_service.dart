import 'dart:convert';

import '../../core/config/api_config.dart';
import '../../models/points/expire_points_result.dart';
import '../../models/points/point_history_item.dart';
import '../../models/points/upcoming_point_expiration.dart';
import '../api/authenticated_api_client.dart';

class PointsBackendApiException implements Exception {
  const PointsBackendApiException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PointsBackendApiService {
  PointsBackendApiService({
    AuthenticatedApiClient? apiClient,
  }) : _apiClient = apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<int> getBalance() async {
    final response = await _apiClient.get(
      ApiConfig.athletesUri(
        '/api/v1/athletes/points/balance',
      ),
    );

    final json = _decodeObject(
      response.statusCode,
      response.bodyBytes,
    );

    return (json['balance'] as num?)?.toInt() ?? 0;
  }

  Future<List<PointHistoryItem>> getHistory() async {
    final response = await _apiClient.get(
      ApiConfig.athletesUri(
        '/api/v1/athletes/points/history',
      ),
    );

    final json = _decodeList(
      response.statusCode,
      response.bodyBytes,
    );

    return json
        .map(
          (item) => PointHistoryItem.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<UpcomingPointExpiration>>
      getExpirations() async {
    final response = await _apiClient.get(
      ApiConfig.athletesUri(
        '/api/v1/athletes/points/expirations',
      ),
    );

    final json = _decodeList(
      response.statusCode,
      response.bodyBytes,
    );

    return json
        .map(
          (item) => UpcomingPointExpiration.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<ExpirePointsResult> expirePoints() async {
    final response = await _apiClient.post(
      ApiConfig.athletesUri(
        '/api/v1/athletes/points/expire',
      ),
    );

    final json = _decodeObject(
      response.statusCode,
      response.bodyBytes,
    );

    return ExpirePointsResult.fromJson(json);
  }

  Map<String, dynamic> _decodeObject(
    int statusCode,
    List<int> bodyBytes,
  ) {
    final decoded = _decodeResponse(
      statusCode,
      bodyBytes,
    );

    if (decoded is! Map<String, dynamic>) {
      throw const PointsBackendApiException(
        'La respuesta del servidor no tiene el formato esperado.',
      );
    }

    return decoded;
  }

  List<dynamic> _decodeList(
    int statusCode,
    List<int> bodyBytes,
  ) {
    final decoded = _decodeResponse(
      statusCode,
      bodyBytes,
    );

    if (decoded is! List<dynamic>) {
      throw const PointsBackendApiException(
        'La respuesta del servidor no tiene el formato esperado.',
      );
    }

    return decoded;
  }

  dynamic _decodeResponse(
    int statusCode,
    List<int> bodyBytes,
  ) {
    final body = utf8.decode(bodyBytes);

    dynamic decoded;

    if (body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        if (statusCode >= 200 && statusCode < 300) {
          throw const PointsBackendApiException(
            'La respuesta del servidor no es válida.',
          );
        }
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    var message = 'No fue posible consultar los puntos.';

    if (decoded is Map<String, dynamic>) {
      final serverMessage = decoded['message'];
      if (serverMessage is String &&
          serverMessage.trim().isNotEmpty) {
        message = serverMessage;
      }
    }

    throw PointsBackendApiException(
      message,
      statusCode: statusCode,
    );
  }

  void dispose() {
    _apiClient.dispose();
  }
}
