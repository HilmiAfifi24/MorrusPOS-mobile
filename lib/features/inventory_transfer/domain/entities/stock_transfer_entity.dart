import 'package:equatable/equatable.dart';

class StockLocationEntity extends Equatable {
  final String id;
  final String name;
  final String type;
  final bool isActive;
  const StockLocationEntity(this.id, this.name, this.type, this.isActive);
  @override
  List<Object?> get props => [id, name, type, isActive];
}

class TransferItemEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final double sentQty;
  final double? receivedQty;
  final double? differenceQty;
  final String? productBatchId;
  final String? batchNumber;
  final String? productSerialId;
  final String? serialNumber;
  const TransferItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.sentQty,
    this.receivedQty,
    this.differenceQty,
    this.productBatchId,
    this.batchNumber,
    this.productSerialId,
    this.serialNumber,
  });
  factory TransferItemEntity.fromJson(Map<String, dynamic> json) =>
      TransferItemEntity(
        id: json['id']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? '',
        sku: json['sku']?.toString() ?? '',
        sentQty: ((json['sentQty'] ?? json['qty']) as num?)?.toDouble() ?? 0,
        receivedQty: (json['receivedQty'] as num?)?.toDouble(),
        differenceQty: (json['differenceQty'] as num?)?.toDouble(),
        productBatchId: json['productBatchId']?.toString(),
        batchNumber: json['batchNumber']?.toString(),
        productSerialId: json['productSerialId']?.toString(),
        serialNumber: json['serialNumber']?.toString(),
      );
  @override
  List<Object?> get props => [id, sentQty, receivedQty, differenceQty];
}

class StockTransferEntity extends Equatable {
  final String id;
  final String transferNumber;
  final String status;
  final String fromLocationName;
  final String toLocationName;
  final DateTime sentAt;
  final List<TransferItemEntity> items;
  const StockTransferEntity({
    required this.id,
    required this.transferNumber,
    required this.status,
    required this.fromLocationName,
    required this.toLocationName,
    required this.sentAt,
    required this.items,
  });
  factory StockTransferEntity.fromJson(Map<String, dynamic> json) =>
      StockTransferEntity(
        id: json['id']?.toString() ?? '',
        transferNumber: json['transferNumber']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        fromLocationName: json['fromStockLocationName']?.toString() ?? '',
        toLocationName: json['toStockLocationName']?.toString() ?? '',
        sentAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        items: ((json['items'] as List?) ?? const [])
            .map((x) => TransferItemEntity.fromJson(x as Map<String, dynamic>))
            .toList(),
      );
  bool get canReceive => status == 'in_transit' || status == 'pending';
  @override
  List<Object?> get props => [id, status, items];
}

class TransferInventoryItem {
  final String productId;
  final String? productVariantId;
  final String name;
  final String sku;
  final double qty;
  final String trackingMode;
  const TransferInventoryItem(
    this.productId,
    this.productVariantId,
    this.name,
    this.sku,
    this.qty,
    this.trackingMode,
  );
  factory TransferInventoryItem.fromJson(Map<String, dynamic> json) =>
      TransferInventoryItem(
        json['productId']?.toString() ?? '',
        json['productVariantId']?.toString(),
        json['productName']?.toString() ?? '',
        json['sku']?.toString() ?? '',
        (json['qtyOnHand'] as num?)?.toDouble() ?? 0,
        json['trackingMode']?.toString() ?? 'quantity',
      );
}
