import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/cashier_session_repository.dart';
import 'cashier_session_event.dart';
import 'cashier_session_state.dart';

export 'cashier_session_event.dart';
export 'cashier_session_state.dart';

class CashierSessionBloc
    extends Bloc<CashierSessionEvent, CashierSessionState> {
  final CashierSessionRepository repository;

  CashierSessionBloc({required this.repository})
    : super(CashierSessionInitial()) {
    on<CheckActiveSession>(_onCheckActiveSession);
    on<OpenSessionSubmitted>(_onOpenSessionSubmitted);
    on<CloseSessionSubmitted>(_onCloseSessionSubmitted);
  }

  Future<void> _onCheckActiveSession(
    CheckActiveSession event,
    Emitter<CashierSessionState> emit,
  ) async {
    emit(CashierSessionLoading());
    try {
      final session = await repository.getActiveSession(event.outletId);
      if (session != null) {
        emit(ActiveSessionOpen(session));
      } else {
        emit(NoActiveSession());
      }
    } catch (e) {
      emit(
        CashierSessionFailure(
          e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('ServerFailure: ', ''),
        ),
      );
    }
  }

  Future<void> _onOpenSessionSubmitted(
    OpenSessionSubmitted event,
    Emitter<CashierSessionState> emit,
  ) async {
    emit(CashierSessionLoading());
    try {
      final session = await repository.openSession(
        event.outletId,
        event.openingCash,
      );
      emit(ActiveSessionOpen(session));
    } catch (e) {
      emit(
        CashierSessionFailure(
          e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('ServerFailure: ', ''),
        ),
      );
      emit(NoActiveSession());
    }
  }

  Future<void> _onCloseSessionSubmitted(
    CloseSessionSubmitted event,
    Emitter<CashierSessionState> emit,
  ) async {
    emit(CashierSessionLoading());
    try {
      await repository.closeSession(event.sessionId, event.actualCash);
      emit(NoActiveSession());
    } catch (e) {
      emit(
        CashierSessionFailure(
          e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('ServerFailure: ', ''),
        ),
      );
    }
  }
}
