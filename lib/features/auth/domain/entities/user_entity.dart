import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? outletId;
  final List<String> permissions;
  final String accessToken;
  final String refreshToken;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.outletId,
    required this.permissions,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    outletId,
    permissions,
    accessToken,
    refreshToken,
  ];
}
