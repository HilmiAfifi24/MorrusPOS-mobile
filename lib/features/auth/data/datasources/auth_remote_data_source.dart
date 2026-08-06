import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<List<Map<String, dynamic>>> getOutlets();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        String errMsg = 'Email atau password salah.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errMsg = errorData['error'];
          } else if (errorData['message'] != null) {
            errMsg = errorData['message'];
          } else if (errorData['errors'] != null) {
            errMsg = errorData['errors'].toString();
          }
        } catch (_) {}
        throw ServerFailure('$errMsg (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Tidak dapat terhubung ke server. Pastikan URL server benar.');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOutlets() async {
    try {
      final response = await apiClient.get(ApiEndpoints.outlets);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((x) => x as Map<String, dynamic>).toList();
      } else {
        throw ServerFailure('Gagal memuat daftar outlet dari server.');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal memuat outlet: koneksi bermasalah.');
    }
  }
}
