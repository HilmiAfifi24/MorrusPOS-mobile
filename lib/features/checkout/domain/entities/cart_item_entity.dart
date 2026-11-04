import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  final String productId;
  final String productName;
  final String sku;
  final double unitPrice;
  final double qty;
  final double discountAmount;
  final double availableStock;
  final String trackingMode;
  final Map<String, double> batchAllocations;
  final List<String> serialIds;

  const CartItemEntity({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitPrice,
    required this.qty,
    required this.discountAmount,
    required this.availableStock,
    this.trackingMode = 'quantity',
    this.batchAllocations = const {},
    this.serialIds = const [],
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
    String? trackingMode,
    Map<String, double>? batchAllocations,
    List<String>? serialIds,
  }) {
    return CartItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      unitPrice: unitPrice ?? this.unitPrice,
      qty: qty ?? this.qty,
      discountAmount: discountAmount ?? this.discountAmount,
      availableStock: availableStock ?? this.availableStock,
      trackingMode: trackingMode ?? this.trackingMode,
      batchAllocations: batchAllocations ?? this.batchAllocations,
      serialIds: serialIds ?? this.serialIds,
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
    trackingMode,
    batchAllocations,
    serialIds,
  ];
}
