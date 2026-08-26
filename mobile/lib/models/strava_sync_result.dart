import 'activity_processing_result.dart';

class StravaSyncResult {
  const StravaSyncResult({
    required this.downloadedActivities,
    required this.processedResults,
    required this.startedAt,
    required this.finishedAt,
  });

  /// Cantidad total de actividades descargadas desde Strava.
  final int downloadedActivities;

  /// Resultados generados por el motor de App KM.
  final List<ActivityProcessingResult> processedResults;

  final DateTime startedAt;
  final DateTime finishedAt;

  int get approvedCount {
    return processedResults.where((result) => result.isApproved).length;
  }

  int get rejectedCount {
    return processedResults.where((result) => result.isRejected).length;
  }

  int get pendingReviewCount {
    return processedResults.where((result) => result.requiresReview).length;
  }

  int get generatedTransactionsCount {
    return processedResults
        .where((result) => result.pointTransaction != null)
        .length;
  }

  int get totalPointsAwarded {
    return processedResults.fold<int>(
      0,
      (total, result) => total + result.validatedActivity.pointsAwarded,
    );
  }

  Duration get duration {
    return finishedAt.difference(startedAt);
  }

  bool get hasResults => processedResults.isNotEmpty;
}
