import 'dart:convert';

import '../../core/config/api_config.dart';
import '../../models/redemptions/pending_redemption_confirmation.dart';
import '../api/authenticated_api_client.dart';

class PendingRedemptionsBackendApiException
    implements Exception {
  const PendingRedemptionsBackendApiException(
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

class PendingRedemptionsBackendApiService {
  PendingRedemptionsBackendApiService({
    AuthenticatedApiClient? apiClient,
  }) : _apiClient =
            apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<List<PendingRedemptionConfirmation>>
      getPendingConfirmations() async {
    final response = await _apiClient.get(
      ApiConfig.athletesUri(
        '/api/v1/athletes/redemptions/pending-confirmations',
      ),
    );

    final body = utf8.decode(response.bodyBytes);

    dynamic decoded;

    if (body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        if (response.statusCode >= 200 &&
            response.statusCode < 300) {
          throw const PendingRedemptionsBackendApiException(
            'La respuesta del servidor no es válida.',
          );
        }
      }
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (decoded is! List<dynamic>) {
        throw const PendingRedemptionsBackendApiException(
          'La respuesta del servidor no tiene el formato esperado.',
        );
      }

      return decoded
          .map(
            (item) =>
                PendingRedemptionConfirmation.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    var message =
        'No fue posible consultar los canjes pendientes.';
    String? code;

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

    throw PendingRedemptionsBackendApiException(
      message,
      statusCode: response.statusCode,
      code: code,
    );
  }

  void dispose() {
    _apiClient.dispose();
  }
}
