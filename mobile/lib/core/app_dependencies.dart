import '../repositories/in_memory_activity_repository.dart';
import '../repositories/in_memory_point_transaction_repository.dart';
import '../services/activity_processing_service.dart';
import '../services/activity_service.dart';
import '../services/dashboard_service.dart';
import '../services/points_service.dart';
import '../services/strava/http_strava_api_client.dart';
import '../services/strava/in_memory_strava_token_store.dart';
import '../services/strava/strava_auth_service.dart';
import '../services/strava/strava_connection_controller.dart';
import '../services/strava/strava_deep_link_service.dart';
import '../services/strava/strava_oauth_launcher.dart';
import '../services/strava/strava_repository.dart';
import '../services/strava/strava_sync_controller.dart';
import '../services/strava/strava_sync_service.dart';
import '../services/validation_service.dart';

class AppDependencies {
  AppDependencies._();

  static final AppDependencies instance = AppDependencies._();

  late final InMemoryActivityRepository activityRepository;

  late final InMemoryPointTransactionRepository pointTransactionRepository;

  late final HttpStravaApiClient stravaApiClient;

  late final StravaRepository stravaRepository;

  late final InMemoryStravaTokenStore stravaTokenStore;

  late final StravaAuthService stravaAuthService;

  late final ValidationService validationService;

  late final PointsService pointsService;

  late final ActivityService activityService;

  late final ActivityProcessingService activityProcessingService;

  late final DashboardService dashboardService;

  late final StravaSyncService stravaSyncService;

  late final StravaSyncController stravaSyncController;

  late final StravaConnectionController stravaConnectionController;

  late final StravaOAuthLauncher stravaOAuthLauncher;

  late final StravaDeepLinkService stravaDeepLinkService;

  bool _initialized = false;

  bool get isInitialized => _initialized;

  void initialize() {
    if (_initialized) {
      return;
    }

    activityRepository = InMemoryActivityRepository();

    pointTransactionRepository = InMemoryPointTransactionRepository();

    stravaApiClient = HttpStravaApiClient();

    stravaRepository = StravaRepository(apiClient: stravaApiClient);

    stravaTokenStore = InMemoryStravaTokenStore();

    // Debe crearse antes del StravaConnectionController.
    stravaAuthService = StravaAuthService(
      repository: stravaRepository,
      tokenStore: stravaTokenStore,
    );

    stravaConnectionController = StravaConnectionController(
      authService: stravaAuthService,
    );

    stravaOAuthLauncher = const StravaOAuthLauncher();

    stravaDeepLinkService = StravaDeepLinkService(
      connectionController: stravaConnectionController,
    );

    validationService = ValidationService();

    pointsService = const PointsService();

    activityService = ActivityService(
      validationService: validationService,
      pointsService: pointsService,
    );

    activityProcessingService = ActivityProcessingService(
      activityRepository: activityRepository,
      pointTransactionRepository: pointTransactionRepository,
      activityService: activityService,
    );

    dashboardService = DashboardService(
      activityRepository: activityRepository,
      pointTransactionRepository: pointTransactionRepository,
    );

    stravaSyncService = StravaSyncService(
      repository: stravaRepository,
      authService: stravaAuthService,
      activityProcessingService: activityProcessingService,
    );

    stravaSyncController = StravaSyncController(syncService: stravaSyncService);

    stravaConnectionController.initialize();
    stravaDeepLinkService.initialize();

    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }

    await stravaDeepLinkService.dispose();

    stravaSyncController.dispose();
    stravaConnectionController.dispose();
    stravaApiClient.close();

    _initialized = false;
  }
}
