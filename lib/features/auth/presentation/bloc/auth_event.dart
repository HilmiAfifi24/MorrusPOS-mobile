import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class OutletSelected extends AuthEvent {
  final String outletId;

  const OutletSelected(this.outletId);

  @override
  List<Object?> get props => [outletId];
}

class OutletSelectionRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}
