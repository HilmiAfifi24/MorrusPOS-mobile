import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity?> getCachedUser();
  Future<void> logout();
  Future<String?> getSelectedOutletId();
  Future<void> saveSelectedOutletId(String outletId);
  Future<List<Map<String, dynamic>>> getOutlets();
}
