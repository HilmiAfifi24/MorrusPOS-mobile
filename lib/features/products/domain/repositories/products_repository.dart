import '../entities/product_entity.dart';

abstract class ProductsRepository {
  Future<List<ProductEntity>> getProducts(String outletId);
  Future<ProductTrackingOptions> getTrackingOptions(
    String productId,
    String outletId, {
    String? search,
  });
}
