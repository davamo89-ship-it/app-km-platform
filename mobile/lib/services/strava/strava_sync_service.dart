import '../../models/strava_activity.dart';
import '../../models/strava_sync_result.dart';
import '../activity_processing_service.dart';
import 'strava_auth_service.dart';
import 'strava_repository.dart';
import 'strava_sync_exception.dart';

class StravaSyncService {
  StravaSyncService({
    required StravaRepository repository,
    required StravaAuthService authService,
    required ActivityProcessingService activityProcessingService,
    DateTime Function()? nowProvider,
  }) : _repository = repository,
       _authService = authService,
       _activityProcessingService = activityProcessingService,
       _nowProvider = nowProvider ?? DateTime.now;

  final StravaRepository _repository;
  final StravaAuthService _authService;
  final ActivityProcessingService _activityProcessingService;
  final DateTime Function() _nowProvider;

  bool _isSynchronizing = false;

  bool get isSynchronizing => _isSynchronizing;

  Future<StravaSyncResult> synchronizeToday({required String userId}) async {
    final now = _nowProvider();

    final startOfDay = DateTime(now.year, now.month, now.day);

    final endOfDay = startOfDay.add(const Duration(days: 1));

    return synchronizeRange(
      userId: userId,
      after: startOfDay,
      before: endOfDay,
    );
  }

  Future<StravaSyncResult> synchronizeRange({
    required String userId,
    required DateTime after,
    required DateTime before,
  }) async {
    if (_isSynchronizing) {
      throw const StravaSyncException(
        code: 'sync_in_progress',
        message: 'Ya existe una sincronización de Strava en proceso.',
      );
    }

    if (!after.isBefore(before)) {
      throw const StravaSyncException(
        code: 'invalid_date_range',
        message: 'La fecha inicial debe ser anterior a la fecha final.',
      );
    }

    _isSynchronizing = true;

    final startedAt = _nowProvider();

    try {
      final accessToken = await _authService.getValidAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const StravaSyncException(
          code: 'not_connected',
          message: 'La cuenta de Strava no está conectada.',
        );
      }

      final activities = await _downloadAllActivities(
        accessToken: accessToken,
        after: after,
        before: before,
      );

      final orderedActivities = List<StravaActivity>.from(activities)
        ..sort(
          (first, second) =>
              first.startDateLocal.compareTo(second.startDateLocal),
        );

      final processedResults = await _activityProcessingService
          .processAndSaveAll(activities: orderedActivities, userId: userId);

      return StravaSyncResult(
        downloadedActivities: activities.length,
        processedResults: processedResults,
        startedAt: startedAt,
        finishedAt: _nowProvider(),
      );
    } on StravaSyncException {
      rethrow;
    } catch (error) {
      throw StravaSyncException(
        code: 'sync_failed',
        message: 'No fue posible completar la sincronización con Strava.',
        cause: error,
      );
    } finally {
      _isSynchronizing = false;
    }
  }

  Future<List<StravaActivity>> _downloadAllActivities({
    required String accessToken,
    required DateTime after,
    required DateTime before,
  }) async {
    const perPage = 100;

    final activities = <StravaActivity>[];

    var page = 1;

    while (true) {
      final currentPage = await _repository.getActivities(
        accessToken: accessToken,
        after: after,
        before: before,
        page: page,
        perPage: perPage,
      );

      if (currentPage.isEmpty) {
        break;
      }

      activities.addAll(currentPage);

      page++;
    }

    return List.unmodifiable(activities);
  }
}
