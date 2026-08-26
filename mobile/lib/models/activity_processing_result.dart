import 'point_transaction.dart';
import 'validated_activity.dart';

class ActivityProcessingResult {
  const ActivityProcessingResult({
    required this.validatedActivity,
    this.pointTransaction,
  });

  final ValidatedActivity validatedActivity;

  final PointTransaction? pointTransaction;

  bool get isApproved => validatedActivity.isApproved;

  bool get isRejected => validatedActivity.isRejected;

  bool get requiresReview => validatedActivity.requiresReview;

  bool get generatedPoints =>
      pointTransaction != null && pointTransaction!.points > 0;
}
