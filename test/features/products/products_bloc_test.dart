import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos/features/products/domain/entities/product_entity.dart';
import 'package:mobile_pos/features/products/domain/repositories/products_repository.dart';
import 'package:mobile_pos/features/products/presentation/bloc/products_bloc.dart';

const products = [
  ProductEntity(
    id: 'product-1',
    name: 'Kopi Susu',
    sku: 'KOPI-1',
    barcode: '899001',
    basePrice: 18000,
    qtyOnHand: 10,
    categoryId: 'drink',
    categoryName: 'Minuman',
  ),
  ProductEntity(
    id: 'product-2',
    name: 'Roti Bakar',
    sku: 'ROTI-1',
    basePrice: 15000,
    qtyOnHand: 5,
    categoryId: 'food',
    categoryName: 'Makanan',
  ),
];

void main() {
  test(
    'load, search, kategori, dan update stok menjaga filter aktif',
    () async {
      final bloc = ProductsBloc(repository: _ProductsRepository());
      addTearDown(bloc.close);

      bloc.add(const LoadProducts('outlet-1'));
      await bloc.stream.firstWhere(
        (state) => !state.isLoading && state.allProducts.length == 2,
      );

      bloc.add(const SearchProducts('kopi'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.filteredProducts.single.id, 'product-1');

      bloc.add(const FilterCategorySelected('drink'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const UpdateProductsStock([
          {'productId': 'product-1', 'qty': 7},
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.filteredProducts.single.qtyOnHand, 7);
      expect(bloc.state.selectedCategoryId, 'drink');
    },
  );
}

class _ProductsRepository implements ProductsRepository {
  @override
  Future<List<ProductEntity>> getProducts(String outletId) async => products;
  @override
  Future<ProductTrackingOptions> getTrackingOptions(
    String productId,
    String outletId, {
    String? search,
  }) async => const ProductTrackingOptions('quantity', [], []);
}
