import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/products_repository.dart';
import '../../domain/entities/product_entity.dart';
import 'products_event.dart';
import 'products_state.dart';

export 'products_event.dart';
export 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductsRepository repository;

  ProductsBloc({required this.repository}) : super(const ProductsState()) {
    on<LoadProducts>(_onLoadProducts);
    on<SearchProducts>(_onSearchProducts);
    on<FilterCategorySelected>(_onFilterCategorySelected);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<ProductsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final products = await repository.getProducts(event.outletId);
      
      // Extract unique categories
      final Set<String> categoryIds = {};
      final Map<String, String> categoryIdToName = {};
      
      for (final p in products) {
        if (p.categoryId != null && p.categoryName != null) {
          categoryIds.add(p.categoryId!);
          categoryIdToName[p.categoryId!] = p.categoryName!;
        }
      }

      final categoriesList = categoryIds.toList();

      emit(state.copyWith(
        allProducts: products,
        filteredProducts: _filter(products, state.searchQuery, state.selectedCategoryId),
        categories: categoriesList,
        categoryIdToName: categoryIdToName,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('ServerFailure: ', ''),
      ));
    }
  }

  void _onSearchProducts(SearchProducts event, Emitter<ProductsState> emit) {
    emit(state.copyWith(
      searchQuery: event.query,
      filteredProducts: _filter(state.allProducts, event.query, state.selectedCategoryId),
    ));
  }

  void _onFilterCategorySelected(FilterCategorySelected event, Emitter<ProductsState> emit) {
    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      clearSelectedCategory: event.categoryId == null,
      filteredProducts: _filter(state.allProducts, state.searchQuery, event.categoryId),
    ));
  }

  List<ProductEntity> _filter(List<ProductEntity> products, String query, String? categoryId) {
    return products.where((product) {
      final matchesCategory = categoryId == null || product.categoryId == categoryId;
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.sku.toLowerCase().contains(query.toLowerCase()) ||
          (product.barcode ?? '').toLowerCase().contains(query.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }
}
