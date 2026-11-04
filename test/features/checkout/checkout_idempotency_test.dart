import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/core/error/failures.dart';
import 'package:mobile_pos/core/network/api_error.dart';
import 'package:mobile_pos/features/checkout/domain/entities/cart_item_entity.dart';
import 'package:mobile_pos/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:mobile_pos/features/checkout/presentation/bloc/checkout_bloc.dart';

class DelayedCheckoutRepository implements CheckoutRepository {
  final previewCompleter = Completer<Map<String, dynamic>>();
  int checkoutCalls = 0;
  String? requestId;
  String? paymentId;

  @override
  Future<Map<String, dynamic>> previewPricing({required String outletId, required List<Map<String, dynamic>> items, String? voucherCode}) => previewCompleter.future;

  @override
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
  }) async {
    checkoutCalls++;
    this.requestId = requestId;
    this.paymentId = paymentId;
    return {'id': requestId};
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentTransactions(String outletId) async => [];
  @override
  Future<Map<String, dynamic>> getTransactionById(String id) async => {'id': id};
  @override
  Future<void> voidTransaction(String id, String reason) async {}
  @override
  Map<String, dynamic>? getPendingCheckout() => null;
  @override
  Future<Map<String, dynamic>> retryPendingCheckout() async => {'id': requestId};
}

void main() {
  test('idempotency errors keep their structured code', () {
    final failure = failureFromResponse(
      http.Response('{"code":"IDEMPOTENCY_IN_PROGRESS"}', 409),
      'fallback',
    );
    expect(failure, isA<IdempotencyFailure>());
    expect((failure as IdempotencyFailure).code, 'IDEMPOTENCY_IN_PROGRESS');
  });

  test('checkout bloc ignores concurrent submit and preserves request IDs', () async {
    final repository = DelayedCheckoutRepository();
    final bloc = CheckoutBloc(repository: repository);
    const item = CartItemEntity(
      productId: 'product-1',
      productName: 'Product',
      sku: 'SKU-1',
      unitPrice: 10000,
      qty: 1,
      discountAmount: 0,
      availableStock: 10,
    );
    const event = SubmitCheckout(
      requestId: '11111111-1111-4111-8111-111111111111',
      paymentId: '22222222-2222-4222-8222-222222222222',
      items: [item],
      paymentMethod: 'cash',
      paymentAmount: 10000,
      outletId: 'outlet-1',
      cashierSessionId: 'session-1',
    );

    bloc.add(event);
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
    repository.previewCompleter.complete({
      'subtotal': 10000,
      'manualDiscountTotal': 0,
      'promoDiscountTotal': 0,
      'voucherDiscountTotal': 0,
      'taxTotal': 0,
      'grandTotal': 10000,
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.checkoutCalls, 1);
    expect(repository.requestId, event.requestId);
    expect(repository.paymentId, event.paymentId);
    await bloc.close();
  });
}
