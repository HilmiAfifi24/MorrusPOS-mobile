import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../domain/entities/stock_transfer_entity.dart';

class StockTransferRepository {
  final ApiClient apiClient;
  StockTransferRepository(this.apiClient);

  Future<List<StockLocationEntity>> getLocations() async {
    final response = await apiClient.get(
      ApiEndpoints.stockLocations,
      queryParams: {'includeInactive': 'false'},
    );
    if (response.statusCode != 200) {
      throw failureFromResponse(response, 'Gagal memuat lokasi stok.');
    }
    return (jsonDecode(response.body) as List).map((x) {
      final j = x as Map<String, dynamic>;
      return StockLocationEntity(
        j['id'].toString(),
        j['name']?.toString() ?? '',
        j['type']?.toString() ?? '',
        j['isActive'] == true,
      );
    }).toList();
  }

  Future<List<StockTransferEntity>> getTransfers(
    String locationId, {
    required bool incoming,
  }) async {
    final response = await apiClient.get(
      '${ApiEndpoints.stockTransfers}/${incoming ? 'incoming' : 'outgoing'}',
      queryParams: {'stockLocationId': locationId},
    );
    if (response.statusCode != 200) {
      throw failureFromResponse(response, 'Gagal memuat transfer stok.');
    }
    return (jsonDecode(response.body) as List)
        .map((x) => StockTransferEntity.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<List<TransferInventoryItem>> getInventory(String locationId) async {
    final response = await apiClient.get(
      ApiEndpoints.inventory,
      queryParams: {'stockLocationId': locationId, 'includeZeroStock': 'false'},
    );
    if (response.statusCode != 200) {
      throw failureFromResponse(response, 'Gagal memuat stok sumber.');
    }
    return (jsonDecode(response.body) as List)
        .map((x) => TransferInventoryItem.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getTracking(
    TransferInventoryItem item,
    String locationId,
  ) async {
    final response = await apiClient.get(
      '${ApiEndpoints.products}/${item.productId}/stock-tracking',
      queryParams: {
        'stockLocationId': locationId,
        if (item.productVariantId != null)
          'productVariantId': item.productVariantId!,
        'take': '100',
      },
    );
    if (response.statusCode != 200) {
      throw failureFromResponse(response, 'Gagal memuat batch atau serial.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> send(Map<String, dynamic> payload) async {
    final key = payload['requestId'].toString();
    final response = await apiClient.post(
      ApiEndpoints.stockTransfers,
      body: payload,
      headers: {'Idempotency-Key': key},
    );
    if (response.statusCode != 201) {
      throw failureFromResponse(response, 'Gagal mengirim transfer stok.');
    }
  }

  Future<void> receive(String id, Map<String, dynamic> payload) async {
    final key = payload['requestId'].toString();
    final response = await apiClient.post(
      '${ApiEndpoints.stockTransfers}/$id/receive',
      body: payload,
      headers: {'Idempotency-Key': key},
    );
    if (response.statusCode != 200) {
      throw failureFromResponse(response, 'Gagal menerima transfer stok.');
    }
  }

  String message(Object error) =>
      error is Failure ? error.message : 'Koneksi bermasalah. Coba lagi.';
}
