import '../entities/cashier_session_entity.dart';

abstract class CashierSessionRepository {
  Future<CashierSessionEntity?> getActiveSession(String outletId);
  Future<CashierSessionEntity> openSession(String outletId, double openingCash);
  Future<CashierSessionEntity> closeSession(
    String sessionId,
    double actualCash,
  );
}
