import 'package:flutter_test/flutter_test.dart';

import 'package:app_km_prototipo1/models/strava_activity.dart';
import 'package:app_km_prototipo1/models/validated_activity.dart';
import 'package:app_km_prototipo1/repositories/in_memory_activity_repository.dart';
import 'package:app_km_prototipo1/repositories/in_memory_point_transaction_repository.dart';
import 'package:app_km_prototipo1/services/activity_processing_service.dart';
import 'package:app_km_prototipo1/services/activity_service.dart';

void main() {
  const userId = 'user-test-1';

  late InMemoryActivityRepository activityRepository;
  late InMemoryPointTransactionRepository pointTransactionRepository;
  late ActivityProcessingService processingService;

  var transactionCounter = 0;

  setUp(() {
    activityRepository = InMemoryActivityRepository();

    pointTransactionRepository = InMemoryPointTransactionRepository();

    transactionCounter = 0;

    final activityService = ActivityService(
      transactionIdGenerator: () {
        transactionCounter++;
        return 'transaction-$transactionCounter';
      },
    );

    processingService = ActivityProcessingService(
      activityRepository: activityRepository,
      pointTransactionRepository: pointTransactionRepository,
      activityService: activityService,
    );
  });

  group('ActivityProcessingService', () {
    test(
      'aprueba una carrera válida, asigna puntos y actualiza el saldo',
      () async {
        final activity = _createRunningActivity(
          stravaId: 'running-001',
          distanceMeters: 5000,
        );

        final result = await processingService.processAndSave(
          activity: activity,
          userId: userId,
        );

        final balance = await processingService.getCurrentBalance(
          userId: userId,
        );

        final transactions = await pointTransactionRepository.getTransactions(
          userId: userId,
        );

        expect(result.validatedActivity.status, ValidationStatus.approved);

        expect(result.validatedActivity.pointsAwarded, 50);

        expect(result.pointTransaction, isNotNull);

        expect(result.pointTransaction!.points, 50);

        expect(balance, 50);

        expect(transactions, hasLength(1));

        expect(transactions.first.activityId, 'running-001');
      },
    );

    test(
      'rechaza una actividad duplicada y no vuelve a sumar puntos',
      () async {
        final activity = _createRunningActivity(
          stravaId: 'running-duplicate',
          distanceMeters: 5000,
        );

        final firstResult = await processingService.processAndSave(
          activity: activity,
          userId: userId,
        );

        final secondResult = await processingService.processAndSave(
          activity: activity,
          userId: userId,
        );

        final balance = await processingService.getCurrentBalance(
          userId: userId,
        );

        final transactions = await pointTransactionRepository.getTransactions(
          userId: userId,
        );

        expect(firstResult.isApproved, isTrue);

        expect(secondResult.isRejected, isTrue);

        expect(
          secondResult.validatedActivity.validationReason,
          contains('procesada anteriormente'),
        );

        expect(secondResult.pointTransaction, isNull);

        expect(balance, 50);

        expect(transactions, hasLength(1));
      },
    );

    test(
      'rechaza una segunda actividad del mismo deporte durante el día',
      () async {
        final firstActivity = _createRunningActivity(
          stravaId: 'running-first',
          distanceMeters: 5000,
        );

        final secondActivity = _createRunningActivity(
          stravaId: 'running-second',
          distanceMeters: 3000,
        );

        final firstResult = await processingService.processAndSave(
          activity: firstActivity,
          userId: userId,
        );

        final secondResult = await processingService.processAndSave(
          activity: secondActivity,
          userId: userId,
        );

        final balance = await processingService.getCurrentBalance(
          userId: userId,
        );

        expect(firstResult.isApproved, isTrue);

        expect(secondResult.isRejected, isTrue);

        expect(
          secondResult.validatedActivity.validationReason,
          contains('Ya existe una actividad'),
        );

        expect(secondResult.pointTransaction, isNull);

        expect(balance, 50);
      },
    );

    test('rechaza una actividad manual y mantiene el saldo en cero', () async {
      final activity = _createRunningActivity(
        stravaId: 'running-manual',
        distanceMeters: 5000,
        isManual: true,
      );

      final result = await processingService.processAndSave(
        activity: activity,
        userId: userId,
      );

      final balance = await processingService.getCurrentBalance(userId: userId);

      expect(result.isRejected, isTrue);

      expect(
        result.validatedActivity.validationReason,
        contains('manualmente'),
      );

      expect(result.validatedActivity.pointsAwarded, 0);

      expect(result.pointTransaction, isNull);

      expect(balance, 0);
    });

    test('permite dos deportes diferentes durante el mismo día', () async {
      final runningActivity = _createRunningActivity(
        stravaId: 'running-valid',
        distanceMeters: 5000,
      );

      final cyclingActivity = _createCyclingActivity(
        stravaId: 'cycling-valid',
        distanceMeters: 10000,
      );

      final runningResult = await processingService.processAndSave(
        activity: runningActivity,
        userId: userId,
      );

      final cyclingResult = await processingService.processAndSave(
        activity: cyclingActivity,
        userId: userId,
      );

      final balance = await processingService.getCurrentBalance(userId: userId);

      expect(runningResult.isApproved, isTrue);

      expect(cyclingResult.isApproved, isTrue);

      expect(runningResult.validatedActivity.pointsAwarded, 50);

      expect(cyclingResult.validatedActivity.pointsAwarded, 40);

      expect(balance, 90);
    });
  });
}

StravaActivity _createRunningActivity({
  required String stravaId,
  required double distanceMeters,
  bool isManual = false,
}) {
  final now = DateTime.now();

  return StravaActivity(
    stravaId: stravaId,
    name: 'Carrera de prueba',
    sportType: SportType.running,
    distanceMeters: distanceMeters,
    movingTimeSeconds: 1800,
    elapsedTimeSeconds: 1800,
    averageSpeed: 2.8,
    maxSpeed: 4.5,
    startDate: now.toUtc(),
    startDateLocal: now,
    timezone: 'America/Costa_Rica',
    isManual: isManual,
    isFlagged: false,
    hasGps: true,
    elevationGain: 20,
    averageHeartRate: 145,
    maxHeartRate: 175,
    deviceName: 'Test Device',
  );
}

StravaActivity _createCyclingActivity({
  required String stravaId,
  required double distanceMeters,
}) {
  final now = DateTime.now();

  return StravaActivity(
    stravaId: stravaId,
    name: 'Ciclismo de prueba',
    sportType: SportType.cycling,
    distanceMeters: distanceMeters,
    movingTimeSeconds: 1800,
    elapsedTimeSeconds: 1800,
    averageSpeed: 5.6,
    maxSpeed: 10,
    startDate: now.toUtc(),
    startDateLocal: now,
    timezone: 'America/Costa_Rica',
    isManual: false,
    isFlagged: false,
    hasGps: true,
    elevationGain: 50,
    averageHeartRate: 135,
    maxHeartRate: 165,
    deviceName: 'Test Device',
  );
}
