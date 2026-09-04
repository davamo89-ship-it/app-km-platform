import 'dart:convert';

import '../../core/config/api_config.dart';
import '../../models/admin/admin_athlete_item.dart';
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
  }) : _client =
            client ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _client;

  Future<List<AdminAthleteItem>> getAthletes() async {
    final response = await _client.get(
      ApiConfig.identityUri(
        '/api/v1/admin/athletes',
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

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

    if (response.statusCode == 401) {
      throw const AdminBackendApiException(
        'La sesión ha expirado.',
        statusCode: 401,
      );
    }

    if (response.statusCode == 403) {
      throw const AdminBackendApiException(
        'Esta cuenta no tiene acceso al módulo de administración.',
        statusCode: 403,
      );
    }

    throw AdminBackendApiException(
      'No fue posible cargar los atletas.',
      statusCode: response.statusCode,
    );
  }

  void dispose() {
    _client.dispose();
  }
}
