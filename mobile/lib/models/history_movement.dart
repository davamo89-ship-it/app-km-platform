import 'activity.dart';
import 'point_transaction.dart';

class HistoryMovement {
  const HistoryMovement({
    required this.transaction,
    this.activity,
  });

  final PointTransaction transaction;
  final Activity? activity;

  bool get hasActivity => activity != null;

  bool get isPending {
    return transaction.type == PointTransactionType.pending;
  }

  bool get isAdjustment {
    return transaction.type ==
        PointTransactionType.adjustment;
  }

  bool get isEarned {
    return transaction.type ==
        PointTransactionType.earned;
  }
}