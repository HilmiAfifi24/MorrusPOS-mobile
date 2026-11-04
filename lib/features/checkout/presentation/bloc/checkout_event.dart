import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item_entity.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class SubmitCheckout extends CheckoutEvent {
  final String requestId;
  final String paymentId;
  final List<CartItemEntity> items;
  final String paymentMethod;
  final double paymentAmount;
  final String? referenceNumber;
  final String? voucherCode;
  final String outletId;
  final String cashierSessionId;

  const SubmitCheckout({
    required this.requestId,
    required this.paymentId,
    required this.items,
    required this.paymentMethod,
    required this.paymentAmount,
    this.referenceNumber,
    this.voucherCode,
    required this.outletId,
    required this.cashierSessionId,
  });

  @override
  List<Object?> get props => [
    requestId,
    paymentId,
    items,
    paymentMethod,
    paymentAmount,
    referenceNumber,
    voucherCode,
    outletId,
    cashierSessionId,
  ];
}

class LoadHistory extends CheckoutEvent {
  final String outletId;

  const LoadHistory(this.outletId);

  @override
  List<Object?> get props => [outletId];
}

class RetryPendingCheckout extends CheckoutEvent {
  const RetryPendingCheckout();
}

class VoidTransactionEvent extends CheckoutEvent {
  final String transactionId;
  final String reason;
  final String outletId;

  const VoidTransactionEvent({
    required this.transactionId,
    required this.reason,
    required this.outletId,
  });

  @override
  List<Object?> get props => [transactionId, reason, outletId];
}
