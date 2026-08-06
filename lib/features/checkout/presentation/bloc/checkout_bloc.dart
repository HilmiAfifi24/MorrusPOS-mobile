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

  Future<void> _onSubmitCheckout(SubmitCheckout event, Emitter<CheckoutState> emit) async {
    emit(CheckoutLoading());
    try {
      final double subtotal = event.items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.qty));
      final double discountTotal = event.items.fold(0.0, (sum, item) => sum + (item.discountAmount * item.qty));
      final double taxTotal = 0.0;
      final double grandTotal = subtotal - discountTotal + taxTotal;

      final List<Map<String, dynamic>> itemsPayload = event.items.map((item) => {
        'productId': item.productId,
        'qty': item.qty,
        'unitPrice': item.unitPrice,
        'discountAmount': item.discountAmount,
      }).toList();

      final List<Map<String, dynamic>> paymentsPayload = [
        {
          'method': event.paymentMethod,
          'amount': event.paymentAmount,
          'referenceNumber': event.referenceNumber ?? '',
        }
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
      );

      emit(CheckoutSuccess(result));
    } catch (e) {
      emit(CheckoutFailure(e.toString().replaceAll('Exception: ', '').replaceAll('ServerFailure: ', '')));
    }
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<CheckoutState> emit) async {
    emit(CheckoutLoading());
    try {
      final transactions = await repository.getRecentTransactions(event.outletId);
      emit(HistoryLoaded(transactions));
    } catch (e) {
      emit(CheckoutFailure(e.toString().replaceAll('Exception: ', '').replaceAll('ServerFailure: ', '')));
    }
  }

  Future<void> _onVoidTransaction(VoidTransactionEvent event, Emitter<CheckoutState> emit) async {
    emit(CheckoutLoading());
    try {
      await repository.voidTransaction(event.transactionId, event.reason);
      final transactions = await repository.getRecentTransactions(event.outletId);
      emit(HistoryLoaded(transactions));
    } catch (e) {
      emit(CheckoutFailure(e.toString().replaceAll('Exception: ', '').replaceAll('ServerFailure: ', '')));
    }
  }
}
