import '../../models/strava_auth_result.dart';
import '../../models/strava_token.dart';

abstract class StravaTokenStore {
  const StravaTokenStore();

  Future<void> saveSession({
    required StravaToken token,
    required StravaAthlete athlete,
    required Set<String> grantedScopes,
  });

  Future<StravaToken?> readToken();

  Future<StravaAthlete?> readAthlete();

  Future<Set<String>> readGrantedScopes();

  Future<void> clear();
}
