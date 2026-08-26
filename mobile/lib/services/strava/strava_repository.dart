import '../../models/strava_activity.dart';
import '../../models/strava_auth_result.dart';
import '../../models/strava_token.dart';
import 'strava_api_client.dart';

class StravaRepository {
  const StravaRepository({
    required StravaApiClient apiClient,
  }) : _apiClient = apiClient;

  final StravaApiClient _apiClient;

  Future<StravaAuthResult> exchangeCode({
    required String authorizationCode,
  }) {
    return _apiClient.exchangeCode(
      authorizationCode: authorizationCode,
    );
  }

  Future<StravaToken> refreshToken({
    required String refreshToken,
  }) {
    return _apiClient.refreshToken(
      refreshToken: refreshToken,
    );
  }

  Future<StravaAthlete> getAthlete({
    required String accessToken,
  }) {
    return _apiClient.getAthlete(
      accessToken: accessToken,
    );
  }

  Future<List<StravaActivity>> getActivities({
    required String accessToken,
    DateTime? after,
    DateTime? before,
    int page = 1,
    int perPage = 30,
  }) {
    return _apiClient.getActivities(
      accessToken: accessToken,
      after: after,
      before: before,
      page: page,
      perPage: perPage,
    );
  }
}