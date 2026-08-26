import '../../models/strava_auth_result.dart';
import '../../models/strava_token.dart';
import '../../models/strava_activity.dart';

abstract class StravaApiClient {
  const StravaApiClient();

  /// Intercambia el Authorization Code por un Access Token.
  Future<StravaAuthResult> exchangeCode({
    required String authorizationCode,
  });

  /// Renueva el Access Token.
  Future<StravaToken> refreshToken({
    required String refreshToken,
  });

  /// Obtiene el atleta autenticado.
  Future<StravaAthlete> getAthlete({
    required String accessToken,
  });

  /// Descarga actividades.
  Future<List<StravaActivity>> getActivities({
    required String accessToken,
    DateTime? after,
    DateTime? before,
    int page = 1,
    int perPage = 30,
  });
}