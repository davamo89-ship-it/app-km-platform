import 'dart:convert';

import '../../core/config/api_config.dart';
import '../../models/athletes/current_athlete.dart';
import '../../models/athletes/athlete_dashboard.dart';
import '../api/authenticated_api_client.dart';

class AthleteApiException implements Exception {
  const AthleteApiException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AthleteApiService {
  AthleteApiService({
    AuthenticatedApiClient? client,
  }) : _client =
            client ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _client;

  Future<CurrentAthlete> getCurrentAthlete() async {
    final uri = ApiConfig.athletesUri(
      '/api/v1/athletes/me',
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final json =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      return CurrentAthlete.fromJson(json);
    }

    if (response.statusCode == 401) {
      throw const AthleteApiException(
        'La sesión no está autorizada.',
        statusCode: 401,
      );
    }

    if (response.statusCode == 400) {
      throw const AthleteApiException(
        'No fue posible obtener el perfil del atleta.',
        statusCode: 400,
      );
    }

    throw AthleteApiException(
      'Error al consultar el perfil del atleta.',
      statusCode: response.statusCode,
    );
  }
    Future<AthleteDashboard> getDashboard() async {
        final uri = ApiConfig.athletesUri('/api/v1/athletes/dashboard');

        final response = await _client.get(uri);

        if (response.statusCode == 200) {
            final json = jsonDecode(response.body) as Map<String, dynamic>;
            return AthleteDashboard.fromJson(json);
        }

        if (response.statusCode == 401) {
            throw const AthleteApiException(
            'La sesión no está autorizada.',
            statusCode: 401,
            );
        }

        if (response.statusCode == 400) {
            throw const AthleteApiException(
            'No fue posible obtener el dashboard del atleta.',
            statusCode: 400,
            );
        }

        throw AthleteApiException(
            'Error al consultar el dashboard del atleta.',
            statusCode: response.statusCode,
        );
        }

  void dispose() {
    _client.dispose();
  }
}