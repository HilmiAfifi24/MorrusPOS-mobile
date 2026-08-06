import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.outletId,
    required super.permissions,
    required super.accessToken,
    required super.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      outletId: json['outletId'],
      permissions: List<String>.from(json['permissions'] ?? []),
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'name': name,
      'email': email,
      'role': role,
      'outletId': outletId,
      'permissions': permissions,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
