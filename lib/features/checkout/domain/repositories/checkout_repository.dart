abstract class CheckoutRepository {
  Future<Map<String, dynamic>> checkout({
    required String requestId,
    required String paymentId,
    required String outletId,
    required String cashierSessionId,
    required double subtotal,
    required double discountTotal,
    required double taxTotal,
    required double grandTotal,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> payments,
    String? voucherCode,
    String? appliedPromoCode,
  });
  Future<Map<String, dynamic>> previewPricing({
    required String outletId,
    required List<Map<String, dynamic>> items,
    String? voucherCode,
  });
  Future<List<Map<String, dynamic>>> getRecentTransactions(String outletId);
  Future<Map<String, dynamic>> getTransactionById(String id);
  Future<void> voidTransaction(String id, String reason);
  Map<String, dynamic>? getPendingCheckout();
  Future<Map<String, dynamic>> retryPendingCheckout();
}
