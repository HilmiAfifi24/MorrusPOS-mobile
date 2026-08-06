import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.sku,
    super.barcode,
    required super.basePrice,
    required super.qtyOnHand,
    super.categoryId,
    super.categoryName,
    super.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      barcode: json['barcode'],
      basePrice: (json['basePrice'] as num).toDouble(),
      qtyOnHand: (json['qtyOnHand'] as num).toDouble(),
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      imageUrl: json['imageUrl'],
    );
  }
}
