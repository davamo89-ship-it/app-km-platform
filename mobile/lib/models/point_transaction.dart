import 'strava_activity.dart';
import 'validated_activity.dart';

enum PointTransactionType { earned, redeemed, adjustment, expired, pending }

class PointTransaction {
  const PointTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    required this.description,
    required this.createdAt,
    this.activityId,
  });

  final String id;

  final String userId;

  /// Positivos o negativos.
  final int points;

  final PointTransactionType type;

  final String description;

  /// Relación opcional con una actividad validada.
  final String? activityId;

  final DateTime createdAt;

  factory PointTransaction.fromActivity({
    required String id,
    required String userId,
    required ValidatedActivity validatedActivity,
  }) {
    return PointTransaction(
      id: id,
      userId: userId,
      points: validatedActivity.pointsAwarded,
      type: PointTransactionType.earned,
      description:
          'Puntos obtenidos por ${validatedActivity.activity.sportType.displayName}.',
      activityId: validatedActivity.activity.stravaId,
      createdAt: validatedActivity.processedAt,
    );
  }

  factory PointTransaction.redemption({
    required String id,
    required String userId,
    required int points,
    required String description,
  }) {
    return PointTransaction(
      id: id,
      userId: userId,
      points: -points.abs(),
      type: PointTransactionType.redeemed,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  factory PointTransaction.adjustment({
    required String id,
    required String userId,
    required int points,
    required String description,
  }) {
    return PointTransaction(
      id: id,
      userId: userId,
      points: points,
      type: PointTransactionType.adjustment,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  bool get isCredit => points > 0;

  bool get isDebit => points < 0;
}
