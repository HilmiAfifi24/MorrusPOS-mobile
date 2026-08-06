import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
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
        throw ServerFailure('Gagal memuat produk dari server.');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal memuat produk: koneksi bermasalah.');
    }
  }
}
