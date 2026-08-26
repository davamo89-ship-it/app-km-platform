import 'package:flutter_test/flutter_test.dart';

import 'package:app_km_prototipo1/models/strava_activity.dart';
import 'package:app_km_prototipo1/models/strava_auth_result.dart';
import 'package:app_km_prototipo1/models/strava_token.dart';
import 'package:app_km_prototipo1/services/strava/in_memory_strava_token_store.dart';
import 'package:app_km_prototipo1/services/strava/strava_api_client.dart';
import 'package:app_km_prototipo1/services/strava/strava_auth_exception.dart';
import 'package:app_km_prototipo1/services/strava/strava_auth_service.dart';
import 'package:app_km_prototipo1/services/strava/strava_repository.dart';

void main() {
  late FakeStravaApiClient apiClient;
  late InMemoryStravaTokenStore tokenStore;
  late StravaAuthService authService;

  setUp(() {
    apiClient = FakeStravaApiClient();
    tokenStore = InMemoryStravaTokenStore();

    authService = StravaAuthService(
      repository: StravaRepository(apiClient: apiClient),
      tokenStore: tokenStore,
      stateGenerator: () => 'secure-state-test',
      authorizationUriBuilder: ({String? state}) {
        return Uri.parse(
          'https://example.test/authorize',
        ).replace(queryParameters: {'state': state ?? ''});
      },
    );
  });

  group('StravaAuthService', () {
    test('genera la URL con un state verificable', () {
      final uri = authService.createAuthorizationUri();

      expect(uri.queryParameters['state'], 'secure-state-test');
    });

    test('procesa un callback válido y guarda la sesión', () async {
      final authorizationUri = authService.createAuthorizationUri();

      final state = authorizationUri.queryParameters['state'];

      final result = await authService.handleCallback(
        Uri.parse(
          'appkm://strava-callback'
          '?code=authorization-code'
          '&state=$state',
        ),
      );

      final storedToken = await tokenStore.readToken();

      final storedAthlete = await tokenStore.readAthlete();

      expect(apiClient.receivedAuthorizationCode, 'authorization-code');

      expect(result.athlete.fullName, 'Ana Atleta');

      expect(storedToken?.accessToken, 'access-token-initial');

      expect(storedAthlete?.id, 101);

      expect(result.canReadActivities, isTrue);
    });

    test('rechaza un callback con state diferente', () async {
      authService.createAuthorizationUri();

      expect(
        () => authService.handleCallback(
          Uri.parse(
            'appkm://strava-callback'
            '?code=authorization-code'
            '&state=incorrect-state',
          ),
        ),
        throwsA(
          isA<StravaAuthException>().having(
            (error) => error.code,
            'code',
            'invalid_state',
          ),
        ),
      );
    });

    test('renueva y guarda un token expirado', () async {
      final expiredToken = StravaToken(
        accessToken: 'expired-access-token',
        refreshToken: 'old-refresh-token',
        expiresAt:
            DateTime.now()
                .toUtc()
                .subtract(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
        tokenType: 'Bearer',
      );

      await tokenStore.saveSession(
        token: expiredToken,
        athlete: const StravaAthlete(
          id: 101,
          firstName: 'Ana',
          lastName: 'Atleta',
        ),
        grantedScopes: {'read', 'activity:read_all'},
      );

      final refreshedToken = await authService.getValidToken();

      final storedToken = await tokenStore.readToken();

      expect(apiClient.receivedRefreshToken, 'old-refresh-token');

      expect(refreshedToken?.accessToken, 'access-token-refreshed');

      expect(storedToken?.refreshToken, 'new-refresh-token');
    });

    test('disconnect elimina la sesión almacenada', () async {
      await tokenStore.saveSession(
        token: apiClient.authResult.token,
        athlete: apiClient.authResult.athlete,
        grantedScopes: apiClient.authResult.grantedScopes,
      );

      await authService.disconnect();

      expect(await tokenStore.readToken(), isNull);

      expect(await tokenStore.readAthlete(), isNull);
    });
  });
}

class FakeStravaApiClient extends StravaApiClient {
  String? receivedAuthorizationCode;
  String? receivedRefreshToken;

  StravaAuthResult get authResult {
    return StravaAuthResult(
      token: StravaToken(
        accessToken: 'access-token-initial',
        refreshToken: 'refresh-token-initial',
        expiresAt:
            DateTime.now()
                .toUtc()
                .add(const Duration(hours: 6))
                .millisecondsSinceEpoch ~/
            1000,
        tokenType: 'Bearer',
      ),
      athlete: const StravaAthlete(
        id: 101,
        firstName: 'Ana',
        lastName: 'Atleta',
      ),
      grantedScopes: const {'read', 'activity:read_all'},
    );
  }

  @override
  Future<StravaAuthResult> exchangeCode({
    required String authorizationCode,
  }) async {
    receivedAuthorizationCode = authorizationCode;

    return authResult;
  }

  @override
  Future<StravaToken> refreshToken({required String refreshToken}) async {
    receivedRefreshToken = refreshToken;

    return StravaToken(
      accessToken: 'access-token-refreshed',
      refreshToken: 'new-refresh-token',
      expiresAt:
          DateTime.now()
              .toUtc()
              .add(const Duration(hours: 6))
              .millisecondsSinceEpoch ~/
          1000,
      tokenType: 'Bearer',
    );
  }

  @override
  Future<StravaAthlete> getAthlete({required String accessToken}) async {
    return authResult.athlete;
  }

  @override
  Future<List<StravaActivity>> getActivities({
    required String accessToken,
    DateTime? after,
    DateTime? before,
    int page = 1,
    int perPage = 30,
  }) async {
    return const [];
  }
}
