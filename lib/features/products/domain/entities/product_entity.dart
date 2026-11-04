import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  static const validTrackingModes = {'none', 'quantity', 'batch', 'serial'};

  static String parseTrackingMode(dynamic value) {
    final mode = (value ?? 'quantity').toString().trim().toLowerCase();
    return validTrackingModes.contains(mode) ? mode : 'invalid';
  }

  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final double basePrice;
  final double qtyOnHand;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final String trackingMode;

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
    this.trackingMode = 'quantity',
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
    String? trackingMode,
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
      trackingMode: trackingMode ?? this.trackingMode,
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
    trackingMode,
  ];
}

class ProductBatchOption {
  final String id;
  final String batchNumber;
  final String? expiryDate;
  final double qtyRemaining;

  const ProductBatchOption(
    this.id,
    this.batchNumber,
    this.expiryDate,
    this.qtyRemaining,
  );
}

class ProductSerialOption {
  final String id;
  final String serialNumber;

  const ProductSerialOption(this.id, this.serialNumber);
}

class ProductTrackingOptions {
  final String trackingMode;
  final List<ProductBatchOption> batches;
  final List<ProductSerialOption> serials;

  const ProductTrackingOptions(this.trackingMode, this.batches, this.serials);
}
