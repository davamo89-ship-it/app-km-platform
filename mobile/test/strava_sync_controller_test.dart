import 'package:flutter_test/flutter_test.dart';

import 'package:app_km_prototipo1/models/strava_activity.dart';
import 'package:app_km_prototipo1/models/strava_auth_result.dart';
import 'package:app_km_prototipo1/models/strava_token.dart';
import 'package:app_km_prototipo1/repositories/in_memory_activity_repository.dart';
import 'package:app_km_prototipo1/repositories/in_memory_point_transaction_repository.dart';
import 'package:app_km_prototipo1/services/activity_processing_service.dart';
import 'package:app_km_prototipo1/services/activity_service.dart';
import 'package:app_km_prototipo1/services/strava/in_memory_strava_token_store.dart';
import 'package:app_km_prototipo1/services/strava/strava_api_client.dart';
import 'package:app_km_prototipo1/services/strava/strava_auth_service.dart';
import 'package:app_km_prototipo1/services/strava/strava_repository.dart';
import 'package:app_km_prototipo1/services/strava/strava_sync_controller.dart';
import 'package:app_km_prototipo1/services/strava/strava_sync_service.dart';
import 'package:app_km_prototipo1/services/validation_service.dart';

void main() {
  const userId = 'controller-user-test';

  final fixedNow = DateTime(2026, 7, 18, 12);

  late StravaSyncController controller;

  setUp(() async {
    final apiClient = FakeControllerStravaApiClient();

    final stravaRepository = StravaRepository(apiClient: apiClient);

    final tokenStore = InMemoryStravaTokenStore();

    await tokenStore.saveSession(
      token: StravaToken(
        accessToken: 'valid-access-token',
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
        id: 500,
        firstName: 'Usuario',
        lastName: 'Prueba',
      ),
      grantedScopes: const {'read', 'activity:read_all'},
    );

    final authService = StravaAuthService(
      repository: stravaRepository,
      tokenStore: tokenStore,
    );

    final validationService = ValidationService(nowProvider: () => fixedNow);

    final activityService = ActivityService(
      validationService: validationService,
      transactionIdGenerator: () {
        return 'controller-transaction-1';
      },
    );

    final processingService = ActivityProcessingService(
      activityRepository: InMemoryActivityRepository(),
      pointTransactionRepository: InMemoryPointTransactionRepository(),
      activityService: activityService,
    );

    final syncService = StravaSyncService(
      repository: stravaRepository,
      authService: authService,
      activityProcessingService: processingService,
      nowProvider: () => fixedNow,
    );

    controller = StravaSyncController(syncService: syncService);
  });

  test('inicia en estado idle', () {
    expect(controller.status, StravaSyncStatus.idle);

    expect(controller.isSynchronizing, isFalse);
    expect(controller.lastResult, isNull);
    expect(controller.errorMessage, isNull);
  });

  test('sincroniza y conserva el resultado', () async {
    final statuses = <StravaSyncStatus>[];

    controller.addListener(() {
      statuses.add(controller.status);
    });

    final result = await controller.synchronizeToday(userId: userId);

    expect(result, isNotNull);

    expect(controller.status, StravaSyncStatus.success);

    expect(controller.hasResult, isTrue);
    expect(controller.hasError, isFalse);

    expect(controller.lastResult?.downloadedActivities, 1);

    expect(controller.lastResult?.approvedCount, 1);

    expect(controller.lastResult?.totalPointsAwarded, 50);

    expect(
      statuses,
      containsAllInOrder([
        StravaSyncStatus.synchronizing,
        StravaSyncStatus.success,
      ]),
    );
  });

  test('clearResult devuelve el controlador a idle', () async {
    await controller.synchronizeToday(userId: userId);

    controller.clearResult();

    expect(controller.status, StravaSyncStatus.idle);

    expect(controller.lastResult, isNull);
    expect(controller.errorMessage, isNull);
    expect(controller.errorCode, isNull);
  });
}

class FakeControllerStravaApiClient extends StravaApiClient {
  @override
  Future<List<StravaActivity>> getActivities({
    required String accessToken,
    DateTime? after,
    DateTime? before,
    int page = 1,
    int perPage = 30,
  }) async {
    if (page > 1) {
      return const [];
    }

    final date = DateTime(2026, 7, 18, 6);

    return [
      StravaActivity(
        stravaId: 'controller-running-1',
        name: 'Carrera del controlador',
        sportType: SportType.running,
        distanceMeters: 5000,
        movingTimeSeconds: 1800,
        elapsedTimeSeconds: 1800,
        averageSpeed: 2.8,
        maxSpeed: 4.5,
        startDate: date.toUtc(),
        startDateLocal: date,
        timezone: 'America/Costa_Rica',
        isManual: false,
        isFlagged: false,
        hasGps: true,
        elevationGain: 20,
        averageHeartRate: 140,
        maxHeartRate: 170,
        deviceName: 'Test Device',
      ),
    ];
  }

  @override
  Future<StravaAuthResult> exchangeCode({required String authorizationCode}) {
    throw UnimplementedError();
  }

  @override
  Future<StravaToken> refreshToken({required String refreshToken}) {
    throw UnimplementedError();
  }

  @override
  Future<StravaAthlete> getAthlete({required String accessToken}) {
    throw UnimplementedError();
  }
}
