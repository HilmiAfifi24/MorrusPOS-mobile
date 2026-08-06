import 'package:equatable/equatable.dart';
import '../../domain/entities/cashier_session_entity.dart';

abstract class CashierSessionState extends Equatable {
  const CashierSessionState();

  @override
  List<Object?> get props => [];
}

class CashierSessionInitial extends CashierSessionState {}

class CashierSessionLoading extends CashierSessionState {}

class NoActiveSession extends CashierSessionState {}

class ActiveSessionOpen extends CashierSessionState {
  final CashierSessionEntity session;

  const ActiveSessionOpen(this.session);

  @override
  List<Object?> get props => [session];
}

class CashierSessionFailure extends CashierSessionState {
  final String message;

  const CashierSessionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
