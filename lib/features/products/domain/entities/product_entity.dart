import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final double basePrice;
  final double qtyOnHand;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    required this.basePrice,
    required this.qtyOnHand,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
  });

  ProductEntity copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    double? basePrice,
    double? qtyOnHand,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      basePrice: basePrice ?? this.basePrice,
      qtyOnHand: qtyOnHand ?? this.qtyOnHand,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        sku,
        barcode,
        basePrice,
        qtyOnHand,
        categoryId,
        categoryName,
        imageUrl,
      ];
}
