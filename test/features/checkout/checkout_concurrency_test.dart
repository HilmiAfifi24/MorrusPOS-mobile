import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos/core/error/failures.dart';
import 'package:mobile_pos/features/checkout/domain/entities/cart_item_entity.dart';
import 'package:mobile_pos/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:mobile_pos/features/checkout/presentation/bloc/checkout_bloc.dart';

void main() {
  test(
    'stok yang dimenangkan kasir lain menghasilkan checkout failure',
    () async {
      final repository = _StockConflictRepository();
      final bloc = CheckoutBloc(repository: repository);
      addTearDown(bloc.close);
      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(
        const SubmitCheckout(
          requestId: '11111111-1111-4111-8111-111111111111',
          paymentId: '22222222-2222-4222-8222-222222222222',
          items: [
            CartItemEntity(
              productId: 'product-1',
              productName: 'Unit Terakhir',
              sku: 'LAST-1',
              unitPrice: 10000,
              qty: 1,
              discountAmount: 0,
              availableStock: 1,
            ),
          ],
          paymentMethod: 'cash',
          paymentAmount: 10000,
          outletId: 'outlet-1',
          cashierSessionId: 'session-1',
        ),
      );

      final states = await statesFuture;
      expect(states.first, isA<CheckoutLoading>());
      expect(states.last, isA<CheckoutFailure>());
      expect(
        (states.last as CheckoutFailure).message,
        'Stok baru saja habis karena transaksi kasir lain.',
      );
      expect(repository.checkoutCalls, 1);
    },
  );
}

class _StockConflictRepository implements CheckoutRepository {
  int checkoutCalls = 0;

  @override
  Future<Map<String, dynamic>> previewPricing({
    required String outletId,
    required List<Map<String, dynamic>> items,
    String? voucherCode,
  }) async => {
    'subtotal': 10000,
    'manualDiscountTotal': 0,
    'promoDiscountTotal': 0,
    'voucherDiscountTotal': 0,
    'taxTotal': 0,
    'grandTotal': 10000,
  };

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
    checkoutCalls += 1;
    throw const ServerFailure(
      'Stok baru saja habis karena transaksi kasir lain.',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentTransactions(
    String outletId,
  ) async => [];
  @override
  Future<Map<String, dynamic>> getTransactionById(String id) async => {
    'id': id,
  };
  @override
  Future<void> voidTransaction(String id, String reason) async {}
  @override
  Map<String, dynamic>? getPendingCheckout() => null;
  @override
  Future<Map<String, dynamic>> retryPendingCheckout() => checkout(
    requestId: 'retry',
    paymentId: 'retry',
    outletId: 'outlet-1',
    cashierSessionId: 'session-1',
    subtotal: 10000,
    discountTotal: 0,
    taxTotal: 0,
    grandTotal: 10000,
    items: [],
    payments: [],
  );
}
