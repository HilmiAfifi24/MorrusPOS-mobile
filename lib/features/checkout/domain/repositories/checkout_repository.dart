abstract class CheckoutRepository {
  Future<Map<String, dynamic>> checkout({
    required String outletId,
    required String cashierSessionId,
    required double subtotal,
    required double discountTotal,
    required double taxTotal,
    required double grandTotal,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> payments,
  });
  Future<List<Map<String, dynamic>>> getRecentTransactions(String outletId);
  Future<void> voidTransaction(String id, String reason);
}
