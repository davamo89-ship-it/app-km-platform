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
import 'package:app_km_prototipo1/services/strava/strava_sync_service.dart';
import 'package:app_km_prototipo1/services/validation_service.dart';

void main() {
  const userId = 'user-sync-test';

  final fixedNow = DateTime(2026, 7, 18, 12);

  late FakeSyncStravaApiClient apiClient;
  late InMemoryStravaTokenStore tokenStore;
  late StravaAuthService authService;
  late StravaSyncService syncService;
  late InMemoryPointTransactionRepository transactionRepository;

  setUp(() async {
    apiClient = FakeSyncStravaApiClient();

    tokenStore = InMemoryStravaTokenStore();

    final stravaRepository = StravaRepository(apiClient: apiClient);

    authService = StravaAuthService(
      repository: stravaRepository,
      tokenStore: tokenStore,
    );

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
        id: 101,
        firstName: 'Ana',
        lastName: 'Atleta',
      ),
      grantedScopes: const {'read', 'activity:read_all'},
    );

    final activityRepository = InMemoryActivityRepository();

    transactionRepository = InMemoryPointTransactionRepository();

    final validationService = ValidationService(nowProvider: () => fixedNow);

    final activityService = ActivityService(
      validationService: validationService,
      transactionIdGenerator: _TransactionIdGenerator().generate,
    );

    final processingService = ActivityProcessingService(
      activityRepository: activityRepository,
      pointTransactionRepository: transactionRepository,
      activityService: activityService,
    );

    syncService = StravaSyncService(
      repository: stravaRepository,
      authService: authService,
      activityProcessingService: processingService,
      nowProvider: () => fixedNow,
    );
  });

  group('StravaSyncService', () {
    test('descarga, procesa y suma actividades válidas', () async {
      final result = await syncService.synchronizeToday(userId: userId);

      final balance = await transactionRepository.getCurrentBalance(
        userId: userId,
      );

      expect(result.downloadedActivities, 2);

      expect(result.approvedCount, 2);

      expect(result.rejectedCount, 0);

      expect(result.pendingReviewCount, 0);

      expect(result.totalPointsAwarded, 90);

      expect(result.generatedTransactionsCount, 2);

      expect(balance, 90);

      expect(apiClient.requestedPages, [1, 2]);
    });
  });
}

class FakeSyncStravaApiClient extends StravaApiClient {
  final List<int> requestedPages = [];

  @override
  Future<List<StravaActivity>> getActivities({
    required String accessToken,
    DateTime? after,
    DateTime? before,
    int page = 1,
    int perPage = 30,
  }) async {
    requestedPages.add(page);

    if (page > 1) {
      return const [];
    }

    return [
      _createActivity(
        stravaId: 'running-sync',
        sportType: SportType.running,
        distanceMeters: 5000,
        averageSpeed: 2.8,
        startHour: 6,
      ),
      _createActivity(
        stravaId: 'cycling-sync',
        sportType: SportType.cycling,
        distanceMeters: 10000,
        averageSpeed: 5.6,
        startHour: 8,
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

StravaActivity _createActivity({
  required String stravaId,
  required SportType sportType,
  required double distanceMeters,
  required double averageSpeed,
  required int startHour,
}) {
  final activityDate = DateTime(2026, 7, 18, startHour);

  return StravaActivity(
    stravaId: stravaId,
    name: 'Actividad de sincronización',
    sportType: sportType,
    distanceMeters: distanceMeters,
    movingTimeSeconds: 1800,
    elapsedTimeSeconds: 1800,
    averageSpeed: averageSpeed,
    maxSpeed: averageSpeed + 2,
    startDate: activityDate.toUtc(),
    startDateLocal: activityDate,
    timezone: 'America/Costa_Rica',
    isManual: false,
    isFlagged: false,
    hasGps: true,
    elevationGain: 20,
    averageHeartRate: 140,
    maxHeartRate: 170,
    deviceName: 'Test Device',
  );
}

class _TransactionIdGenerator {
  int _counter = 0;

  String generate() {
    _counter++;

    return 'sync-transaction-$_counter';
  }
}
