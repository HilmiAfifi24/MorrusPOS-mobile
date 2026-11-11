import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../domain/entities/capability_snapshot_entity.dart';
import '../../domain/repositories/capability_repository.dart';
import '../models/capability_snapshot_model.dart';

class CapabilityRepositoryImpl implements CapabilityRepository {
  final ApiClient apiClient;

  CapabilityRepositoryImpl({required this.apiClient});

  @override
  Future<CapabilitySnapshotEntity> getEffective(String? outletId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.effectiveCapabilities,
        queryParams: {if (outletId?.isNotEmpty == true) 'outletId': outletId!},
      );
      if (response.statusCode != 200) {
        throw failureFromResponse(response, 'Gagal memuat capability outlet.');
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Snapshot capability tidak valid.');
      }
      return CapabilitySnapshotModel.fromJson(payload);
    } catch (error) {
      if (error is Failure) rethrow;
      throw const ServerFailure('Gagal memuat capability outlet.');
    }
  }
}
