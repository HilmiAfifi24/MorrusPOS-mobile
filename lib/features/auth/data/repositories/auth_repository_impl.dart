import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/storage_service.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final StorageService storageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  Future<UserEntity> login(String email, String password) async {
    final userModel = await remoteDataSource.login(email, password);
    await storageService.setToken(userModel.accessToken);
    await storageService.setRefreshToken(userModel.refreshToken);
    await storageService.saveUser(userModel.toJson());
    if (userModel.outletId != null) {
      await storageService.setSelectedOutletId(userModel.outletId!);
    } else {
      await storageService.clearSelectedOutletId();
    }
    return userModel;
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final cachedJson = storageService.getUser();
    if (cachedJson != null) {
      return UserModel.fromJson(cachedJson);
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await storageService.clearAuth();
  }

  @override
  Future<String?> getSelectedOutletId() async {
    return storageService.selectedOutletId;
  }

  @override
  Future<void> saveSelectedOutletId(String outletId) async {
    await storageService.setSelectedOutletId(outletId);
  }

  @override
  Future<void> clearSelectedOutletId() async {
    await storageService.clearSelectedOutletId();
  }

  @override
  Future<List<Map<String, dynamic>>> getOutlets() async {
    return await remoteDataSource.getOutlets();
  }
}
