import '../../domain/entities/cashier_session_entity.dart';

class CashierSessionModel extends CashierSessionEntity {
  const CashierSessionModel({
    required super.id,
    required super.outletId,
    required super.outletName,
    required super.userId,
    required super.userName,
    required super.openingTime,
    super.closingTime,
    required super.openingCash,
    required super.expectedCash,
    super.actualCash,
    super.variance,
    required super.status,
  });

  factory CashierSessionModel.fromJson(Map<String, dynamic> json) {
    return CashierSessionModel(
      id: json['id'] ?? '',
      outletId: json['outletId'] ?? '',
      outletName: json['outletName'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      openingTime: DateTime.parse(json['openingTime']),
      closingTime: json['closingTime'] != null
          ? DateTime.parse(json['closingTime'])
          : null,
      openingCash: (json['openingCash'] as num).toDouble(),
      expectedCash: (json['expectedCash'] as num).toDouble(),
      actualCash: json['actualCash'] != null
          ? (json['actualCash'] as num).toDouble()
          : null,
      variance: json['variance'] != null
          ? (json['variance'] as num).toDouble()
          : null,
      status: json['status'] ?? 'Open',
    );
  }
}
