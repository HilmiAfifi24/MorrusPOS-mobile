import 'package:equatable/equatable.dart';

abstract class CashierSessionEvent extends Equatable {
  const CashierSessionEvent();

  @override
  List<Object?> get props => [];
}

class CheckActiveSession extends CashierSessionEvent {
  final String outletId;

  const CheckActiveSession(this.outletId);

  @override
  List<Object?> get props => [outletId];
}

class OpenSessionSubmitted extends CashierSessionEvent {
  final String outletId;
  final double openingCash;

  const OpenSessionSubmitted({
    required this.outletId,
    required this.openingCash,
  });

  @override
  List<Object?> get props => [outletId, openingCash];
}

class CloseSessionSubmitted extends CashierSessionEvent {
  final String sessionId;
  final double actualCash;

  const CloseSessionSubmitted({
    required this.sessionId,
    required this.actualCash,
  });

  @override
  List<Object?> get props => [sessionId, actualCash];
}
