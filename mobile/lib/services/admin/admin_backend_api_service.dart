import 'dart:convert';

import '../../core/config/api_config.dart';
import '../../models/admin/admin_athlete_item.dart';
import '../../models/admin/admin_merchant_item.dart';
import '../api/authenticated_api_client.dart';

class AdminBackendApiException implements Exception {
  const AdminBackendApiException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AdminBackendApiService {
  AdminBackendApiService({
    AuthenticatedApiClient? client,
  }) : _client = client ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _client;

  Future<List<AdminAthleteItem>> getAthletes() async {
    final response = await _client.get(
      ApiConfig.identityUri('/api/v1/admin/athletes'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! List<dynamic>) {
        throw AdminBackendApiException(
          'La respuesta de atletas no tiene el formato esperado.',
          statusCode: response.statusCode,
        );
      }

      return decoded
          .map(
            (item) => AdminAthleteItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    _throwRequestError(
      response.statusCode,
      fallbackMessage: 'No fue posible cargar los atletas.',
    );
  }

  Future<List<AdminMerchantItem>> getMerchants() async {
    final response = await _client.get(
      ApiConfig.identityUri('/api/v1/admin/merchants'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! List<dynamic>) {
        throw AdminBackendApiException(
          'La respuesta de comercios no tiene el formato esperado.',
          statusCode: response.statusCode,
        );
      }

      return decoded
          .map(
            (item) => AdminMerchantItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    _throwRequestError(
      response.statusCode,
      fallbackMessage: 'No fue posible cargar los comercios.',
    );
  }

  Never _throwRequestError(
    int statusCode, {
    required String fallbackMessage,
  }) {
    if (statusCode == 401) {
      throw const AdminBackendApiException(
        'La sesión ha expirado.',
        statusCode: 401,
      );
    }

    if (statusCode == 403) {
      throw const AdminBackendApiException(
        'Esta cuenta no tiene acceso al módulo de administración.',
        statusCode: 403,
      );
    }

    throw AdminBackendApiException(
      fallbackMessage,
      statusCode: statusCode,
    );
  }

  void dispose() {
    _client.dispose();
  }
}
