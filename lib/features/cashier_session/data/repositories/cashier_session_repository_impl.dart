import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/cashier_session_repository.dart';
import '../../domain/entities/cashier_session_entity.dart';
import '../models/cashier_session_model.dart';

class CashierSessionRepositoryImpl implements CashierSessionRepository {
  final ApiClient apiClient;

  CashierSessionRepositoryImpl({required this.apiClient});

  @override
  Future<CashierSessionEntity?> getActiveSession(String outletId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.currentSession,
        queryParams: {'outletId': outletId},
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') {
          return null;
        }
        final data = jsonDecode(response.body);
        if (data == null) return null;
        return CashierSessionModel.fromJson(data);
      } else {
        String errMsg = 'Gagal memeriksa sesi kasir aktif.';
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
        throw ServerFailure(errMsg);
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal memeriksa sesi: koneksi bermasalah.');
    }
  }

  @override
  Future<CashierSessionEntity> openSession(String outletId, double openingCash) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.openSession,
        body: {
          'openingCash': openingCash,
          'outletId': outletId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CashierSessionModel.fromJson(data);
      } else {
        String errMsg = 'Gagal membuka sesi kasir.';
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
        throw ServerFailure(errMsg);
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal membuka sesi: koneksi bermasalah.');
    }
  }

  @override
  Future<CashierSessionEntity> closeSession(String sessionId, double actualCash) async {
    try {
      final response = await apiClient.post(
        '${ApiEndpoints.closeSession}/$sessionId',
        body: {
          'actualCash': actualCash,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CashierSessionModel.fromJson(data);
      } else {
        String errMsg = 'Gagal menutup sesi kasir.';
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
        throw ServerFailure(errMsg);
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal menutup sesi: koneksi bermasalah.');
    }
  }
}
