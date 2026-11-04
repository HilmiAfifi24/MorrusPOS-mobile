import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/products_repository.dart';
import '../../domain/entities/product_entity.dart';
import '../models/product_model.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ApiClient apiClient;

  ProductsRepositoryImpl({required this.apiClient});

  @override
  Future<List<ProductEntity>> getProducts(String outletId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.products,
        queryParams: {'outletId': outletId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw failureFromResponse(response, 'Gagal memuat produk dari server.');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal memuat produk: koneksi bermasalah.');
    }
  }

  @override
  Future<ProductTrackingOptions> getTrackingOptions(
    String productId,
    String outletId, {
    String? search,
  }) async {
    try {
      final response = await apiClient.get(
        '${ApiEndpoints.products}/$productId/stock-tracking',
        queryParams: {
          'outletId': outletId,
          'take': '100',
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      if (response.statusCode != 200) {
        throw failureFromResponse(
          response,
          'Gagal memuat batch atau serial produk.',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final trackingMode = ProductEntity.parseTrackingMode(
        json['trackingMode'],
      );
      if (trackingMode == 'invalid') {
        throw const ServerFailure(
          'Mode tracking produk tidak dikenali. Perbarui aplikasi atau hubungi admin.',
        );
      }
      return ProductTrackingOptions(
        trackingMode,
        ((json['batches'] as List?) ?? const []).map((item) {
          final value = item as Map<String, dynamic>;
          return ProductBatchOption(
            value['id'] ?? '',
            value['batchNumber'] ?? '',
            value['expiryDate'],
            (value['qtyRemaining'] as num?)?.toDouble() ?? 0,
          );
        }).toList(),
        ((json['serials'] as List?) ?? const []).map((item) {
          final value = item as Map<String, dynamic>;
          return ProductSerialOption(
            value['id'] ?? '',
            value['serialNumber'] ?? '',
          );
        }).toList(),
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(
        'Gagal memuat batch atau serial: koneksi bermasalah.',
      );
    }
  }
}
