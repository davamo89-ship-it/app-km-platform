import 'package:flutter_test/flutter_test.dart';

import 'package:app_km_prototipo1/models/strava_activity.dart';
import 'package:app_km_prototipo1/models/strava_auth_result.dart';
import 'package:app_km_prototipo1/models/strava_token.dart';
import 'package:app_km_prototipo1/services/strava/in_memory_strava_token_store.dart';
import 'package:app_km_prototipo1/services/strava/strava_api_client.dart';
import 'package:app_km_prototipo1/services/strava/strava_auth_service.dart';
import 'package:app_km_prototipo1/services/strava/strava_connection_controller.dart';
import 'package:app_km_prototipo1/services/strava/strava_repository.dart';

void main() {
  late FakeConnectionStravaApiClient apiClient;
  late InMemoryStravaTokenStore tokenStore;
  late StravaConnectionController controller;

  setUp(() {
    apiClient = FakeConnectionStravaApiClient();
    tokenStore = InMemoryStravaTokenStore();

    final authService = StravaAuthService(
      repository: StravaRepository(apiClient: apiClient),
      tokenStore: tokenStore,
      stateGenerator: () => 'connection-state-test',
      authorizationUriBuilder: ({String? state}) {
        return Uri.parse(
          'https://example.test/authorize',
        ).replace(queryParameters: {'state': state ?? ''});
      },
    );

    controller = StravaConnectionController(authService: authService);
  });

  test('inicializa desconectado cuando no existe sesión', () async {
    await controller.initialize();

    expect(controller.status, StravaConnectionStatus.disconnected);

    expect(controller.isConnected, isFalse);
    expect(controller.athlete, isNull);
  });

  test('inicia autorización y conserva la URL', () {
    final uri = controller.beginAuthorization();

    expect(controller.status, StravaConnectionStatus.authorizing);

    expect(uri.queryParameters['state'], 'connection-state-test');

    expect(controller.authorizationUri, uri);
  });

  test('procesa el callback y queda conectado', () async {
    final authorizationUri = controller.beginAuthorization();

    final state = authorizationUri.queryParameters['state'];

    final connected = await controller.handleCallback(
      Uri.parse(
        'appkm://strava-callback'
        '?code=valid-code'
        '&state=$state',
      ),
    );

    expect(connected, isTrue);

    expect(controller.status, StravaConnectionStatus.connected);

    expect(controller.isConnected, isTrue);

    expect(controller.athlete?.fullName, 'Ana Atleta');

    expect(apiClient.receivedAuthorizationCode, 'valid-code');
  });

  test('disconnect elimina la sesión', () async {
    final authorizationUri = controller.beginAuthorization();

    final state = authorizationUri.queryParameters['state'];

    await controller.handleCallback(
      Uri.parse(
        'appkm://strava-callback'
        '?code=valid-code'
        '&state=$state',
      ),
    );

    await controller.disconnect();

    expect(controller.status, StravaConnectionStatus.disconnected);

    expect(controller.athlete, isNull);

    expect(await tokenStore.readToken(), isNull);
  });
}

class FakeConnectionStravaApiClient extends StravaApiClient {
  String? receivedAuthorizationCode;

  @override
  Future<StravaAuthResult> exchangeCode({
    required String authorizationCode,
  }) async {
    receivedAuthorizationCode = authorizationCode;

    return StravaAuthResult(
      token: StravaToken(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
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
  Future<StravaToken> refreshToken({required String refreshToken}) {
    throw UnimplementedError();
  }

  @override
  Future<StravaAthlete> getAthlete({required String accessToken}) {
    throw UnimplementedError();
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
