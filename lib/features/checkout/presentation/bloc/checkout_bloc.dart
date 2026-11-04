import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/checkout_repository.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

export 'checkout_event.dart';
export 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final CheckoutRepository repository;

  CheckoutBloc({required this.repository}) : super(CheckoutInitial()) {
    on<SubmitCheckout>(_onSubmitCheckout);
    on<LoadHistory>(_onLoadHistory);
    on<VoidTransactionEvent>(_onVoidTransaction);
  }

  Future<void> _onSubmitCheckout(
    SubmitCheckout event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    try {
      for (final item in event.items) {
        if (item.trackingMode == 'batch' &&
            item.batchAllocations.values.fold<double>(
                  0,
                  (sum, qty) => sum + qty,
                ) !=
                item.qty) {
          throw Exception('Jumlah alokasi batch tidak cocok dengan qty.');
        }
        if (item.trackingMode == 'serial' &&
            (item.qty != item.qty.truncateToDouble() ||
                item.serialIds.length != item.qty)) {
          throw Exception('Jumlah serial/IMEI tidak cocok dengan qty.');
        }
      }
      final List<Map<String, dynamic>> itemsPayload = event.items
          .map(
            (item) => {
              'productId': item.productId,
              'qty': item.qty,
              'unitPrice': item.unitPrice,
              'discountAmount': item.discountAmount,
              if (item.batchAllocations.isNotEmpty)
                'batchAllocations': item.batchAllocations.entries
                    .map(
                      (entry) => {
                        'productBatchId': entry.key,
                        'qty': entry.value,
                      },
                    )
                    .toList(),
              if (item.serialIds.isNotEmpty) 'serialIds': item.serialIds,
            },
          )
          .toList();

      final pricing = await repository.previewPricing(
        outletId: event.outletId,
        items: itemsPayload,
        voucherCode: event.voucherCode,
      );

      final double subtotal = (pricing['subtotal'] as num?)?.toDouble() ?? 0.0;
      final double manualDiscountTotal =
          (pricing['manualDiscountTotal'] as num?)?.toDouble() ?? 0.0;
      final double promoDiscountTotal =
          (pricing['promoDiscountTotal'] as num?)?.toDouble() ?? 0.0;
      final double voucherDiscountTotal =
          (pricing['voucherDiscountTotal'] as num?)?.toDouble() ?? 0.0;
      final double taxTotal = (pricing['taxTotal'] as num?)?.toDouble() ?? 0.0;
      final double grandTotal =
          (pricing['grandTotal'] as num?)?.toDouble() ?? 0.0;
      final String? appliedPromoCode =
          (pricing['appliedPromo'] as Map<String, dynamic>?)?['code']
              as String?;
      final double discountTotal =
          manualDiscountTotal + promoDiscountTotal + voucherDiscountTotal;

      final List<Map<String, dynamic>> paymentsPayload = [
        {
          'method': event.paymentMethod,
          'amount': event.paymentAmount,
          'referenceNumber': event.referenceNumber ?? '',
        },
      ];

      final result = await repository.checkout(
        outletId: event.outletId,
        cashierSessionId: event.cashierSessionId,
        subtotal: subtotal,
        discountTotal: discountTotal,
        taxTotal: taxTotal,
        grandTotal: grandTotal,
        items: itemsPayload,
        payments: paymentsPayload,
        voucherCode: event.voucherCode,
        appliedPromoCode: appliedPromoCode,
      );

      emit(CheckoutSuccess(result));
    } catch (e) {
      emit(
        CheckoutFailure(
          e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('ServerFailure: ', ''),
        ),
      );
    }
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    try {
      final transactions = await repository.getRecentTransactions(
        event.outletId,
      );
      emit(HistoryLoaded(transactions));
    } catch (e) {
      emit(
        CheckoutFailure(
          e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('ServerFailure: ', ''),
        ),
      );
    }
  }

  Future<void> _onVoidTransaction(
    VoidTransactionEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    try {
      await repository.voidTransaction(event.transactionId, event.reason);
      final transactions = await repository.getRecentTransactions(
        event.outletId,
      );
      emit(HistoryLoaded(transactions));
    } catch (e) {
      emit(
        CheckoutFailure(
          e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('ServerFailure: ', ''),
        ),
      );
    }
  }
}
