class AppRules {
  AppRules._();

  //--------------------------------------------------
  // Rule Engine
  //--------------------------------------------------

  static const String ruleEngineVersion = '1.0.0';

  //--------------------------------------------------
  // Deportes permitidos
  //--------------------------------------------------

  static const allowedSports = {
    'running',
    'walking',
    'cycling',
    'swimming',
    'gym',
  };

  //--------------------------------------------------
  // Puntos
  //--------------------------------------------------

  static const int runningPointsPerKm = 10;

  static const int walkingPointsPerKm = 8;

  static const int cyclingPointsPerKm = 4;

  static const int swimmingPointsPerKm = 10;

  static const int gymPointsPerMinute = 1;

  //--------------------------------------------------
  // Distancias máximas
  //--------------------------------------------------

  static const double maxRunningKm = 43;

  static const double maxWalkingKm = 25;

  static const double maxCyclingKm = 185;

  static const double maxSwimmingKm = 10;

  static const int maxGymMinutes = 120;

  //--------------------------------------------------
  // Distancias mínimas
  //--------------------------------------------------

  static const double minRunningKm = 1;

  static const double minWalkingKm = 1;

  static const double minCyclingKm = 1;

  static const double minSwimmingKm = 0.25;

  static const int minGymMinutes = 20;

  //--------------------------------------------------
  // Velocidades máximas
  //--------------------------------------------------

  static const double maxRunningSpeed = 25;

  static const double maxWalkingSpeed = 8;

  static const double maxCyclingSpeed = 60;

  static const double maxSwimmingSpeed = 8;

  //--------------------------------------------------
  // Actividades
  //--------------------------------------------------

  static const int maxActivitiesPerSportPerDay = 1;

  //--------------------------------------------------
  // Confidence Score
  //--------------------------------------------------

  static const int defaultConfidence = 100;

  static const int pendingConfidence = 80;

  static const int rejectedConfidence = 0;
}