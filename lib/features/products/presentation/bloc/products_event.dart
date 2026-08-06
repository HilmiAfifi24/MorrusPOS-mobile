import 'package:equatable/equatable.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductsEvent {
  final String outletId;

  const LoadProducts(this.outletId);

  @override
  List<Object?> get props => [outletId];
}

class SearchProducts extends ProductsEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterCategorySelected extends ProductsEvent {
  final String? categoryId;

  const FilterCategorySelected(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}
