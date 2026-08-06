import 'package:equatable/equatable.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {
  final Map<String, dynamic> transaction;

  const CheckoutSuccess(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class HistoryLoaded extends CheckoutState {
  final List<Map<String, dynamic>> transactions;

  const HistoryLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class CheckoutFailure extends CheckoutState {
  final String message;

  const CheckoutFailure(this.message);

  @override
  List<Object?> get props => [message];
}
