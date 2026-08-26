import '../models/point_transaction.dart';
import 'point_transaction_repository.dart';

class InMemoryPointTransactionRepository extends PointTransactionRepository {
  final List<PointTransaction> _transactions = [];

  @override
  Future<void> saveTransaction(PointTransaction transaction) async {
    final existingIndex = _transactions.indexWhere(
      (item) => item.id == transaction.id,
    );

    if (existingIndex >= 0) {
      _transactions[existingIndex] = transaction;
      return;
    }

    _transactions.add(transaction);
  }

  @override
  Future<List<PointTransaction>> getTransactions({
    required String userId,
  }) async {
    final results = _transactions
        .where((item) => item.userId == userId)
        .toList();

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return List.unmodifiable(results);
  }

  @override
  Future<List<PointTransaction>> getTransactionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = _transactions.where((item) {
      final belongsToUser = item.userId == userId;

      final isAfterOrEqual = !item.createdAt.isBefore(startDate);

      final isBeforeOrEqual = !item.createdAt.isAfter(endDate);

      return belongsToUser && isAfterOrEqual && isBeforeOrEqual;
    }).toList();

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return List.unmodifiable(results);
  }

  @override
  Future<PointTransaction?> findById({required String transactionId}) async {
    for (final transaction in _transactions) {
      if (transaction.id == transactionId) {
        return transaction;
      }
    }

    return null;
  }

  @override
  Future<PointTransaction?> findByActivityId({
    required String userId,
    required String activityId,
  }) async {
    for (final transaction in _transactions) {
      if (transaction.userId == userId &&
          transaction.activityId == activityId) {
        return transaction;
      }
    }

    return null;
  }

  @override
  Future<int> getCurrentBalance({required String userId}) async {
    return _transactions
        .where((item) => item.userId == userId)
        .fold<int>(0, (balance, item) => balance + item.points);
  }

  void clear() {
    _transactions.clear();
  }
}
