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
