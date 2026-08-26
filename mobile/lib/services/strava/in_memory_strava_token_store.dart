import '../../models/strava_auth_result.dart';
import '../../models/strava_token.dart';
import 'strava_token_store.dart';

class InMemoryStravaTokenStore extends StravaTokenStore {
  StravaToken? _token;
  StravaAthlete? _athlete;
  Set<String> _grantedScopes = {};

  @override
  Future<void> saveSession({
    required StravaToken token,
    required StravaAthlete athlete,
    required Set<String> grantedScopes,
  }) async {
    _token = token;
    _athlete = athlete;
    _grantedScopes = Set.unmodifiable(grantedScopes);
  }

  @override
  Future<StravaToken?> readToken() async {
    return _token;
  }

  @override
  Future<StravaAthlete?> readAthlete() async {
    return _athlete;
  }

  @override
  Future<Set<String>> readGrantedScopes() async {
    return Set.unmodifiable(_grantedScopes);
  }

  @override
  Future<void> clear() async {
    _token = null;
    _athlete = null;
    _grantedScopes = {};
  }
}
