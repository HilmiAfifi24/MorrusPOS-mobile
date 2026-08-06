import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  final String productId;
  final String productName;
  final String sku;
  final double unitPrice;
  final double qty;
  final double discountAmount;
  final double availableStock;

  const CartItemEntity({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitPrice,
    required this.qty,
    required this.discountAmount,
    required this.availableStock,
  });

  double get lineTotal => (unitPrice - discountAmount) * qty;

  CartItemEntity copyWith({
    String? productId,
    String? productName,
    String? sku,
    double? unitPrice,
    double? qty,
    double? discountAmount,
    double? availableStock,
  }) {
    return CartItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      unitPrice: unitPrice ?? this.unitPrice,
      qty: qty ?? this.qty,
      discountAmount: discountAmount ?? this.discountAmount,
      availableStock: availableStock ?? this.availableStock,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        sku,
        unitPrice,
        qty,
        discountAmount,
        availableStock,
      ];
}
