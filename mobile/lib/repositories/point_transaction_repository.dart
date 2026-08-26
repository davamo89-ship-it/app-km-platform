import '../models/point_transaction.dart';

abstract class PointTransactionRepository {
  const PointTransactionRepository();

  /// Guarda una transacción de puntos.
  Future<void> saveTransaction(PointTransaction transaction);

  /// Obtiene todas las transacciones de un usuario.
  Future<List<PointTransaction>> getTransactions({required String userId});

  /// Obtiene las transacciones dentro de un rango de fechas.
  Future<List<PointTransaction>> getTransactionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtiene una transacción por su identificador.
  Future<PointTransaction?> findById({required String transactionId});

  /// Busca una transacción relacionada con una actividad de Strava.
  Future<PointTransaction?> findByActivityId({
    required String userId,
    required String activityId,
  });

  /// Calcula el saldo actual a partir del libro contable de puntos.
  Future<int> getCurrentBalance({required String userId});
}
