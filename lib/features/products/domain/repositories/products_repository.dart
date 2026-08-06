import '../entities/product_entity.dart';

abstract class ProductsRepository {
  Future<List<ProductEntity>> getProducts(String outletId);
}
