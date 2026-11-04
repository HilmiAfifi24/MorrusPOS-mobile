import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';

class ProductsState extends Equatable {
  final List<ProductEntity> allProducts;
  final List<ProductEntity> filteredProducts;
  final List<String> categories; // Category IDs
  final Map<String, String> categoryIdToName;
  final String? selectedCategoryId;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const ProductsState({
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.categories = const [],
    this.categoryIdToName = const {},
    this.selectedCategoryId,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  ProductsState copyWith({
    List<ProductEntity>? allProducts,
    List<ProductEntity>? filteredProducts,
    List<String>? categories,
    Map<String, String>? categoryIdToName,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProductsState(
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      categories: categories ?? this.categories,
      categoryIdToName: categoryIdToName ?? this.categoryIdToName,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    allProducts,
    filteredProducts,
    categories,
    categoryIdToName,
    selectedCategoryId,
    searchQuery,
    isLoading,
    errorMessage,
  ];
}
