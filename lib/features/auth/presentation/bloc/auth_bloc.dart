import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<OutletSelected>(_onOutletSelected);
    on<OutletSelectionRequested>(_onOutletSelectionRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.getCachedUser();
      if (user != null) {
        final selectedOutletId = await authRepository.getSelectedOutletId();
        emit(Authenticated(user: user, selectedOutletId: selectedOutletId));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      final selectedOutletId = user.outletId;
      emit(Authenticated(user: user, selectedOutletId: selectedOutletId));
    } catch (e) {
      final message = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ServerFailure: ', '');
      emit(AuthFailure(message));
      emit(Unauthenticated());
    }
  }

  Future<void> _onOutletSelected(
    OutletSelected event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is Authenticated) {
      await authRepository.saveSelectedOutletId(event.outletId);
      emit(
        Authenticated(
          user: currentState.user,
          selectedOutletId: event.outletId,
        ),
      );
    }
  }

  Future<void> _onOutletSelectionRequested(
    OutletSelectionRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is Authenticated) {
      await authRepository.clearSelectedOutletId();
      emit(Authenticated(user: currentState.user));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await authRepository.logout();
    emit(Unauthenticated());
  }
}
