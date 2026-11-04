import 'package:equatable/equatable.dart';

class CashierSessionEntity extends Equatable {
  final String id;
  final String outletId;
  final String outletName;
  final String userId;
  final String userName;
  final DateTime openingTime;
  final DateTime? closingTime;
  final double openingCash;
  final double expectedCash;
  final double? actualCash;
  final double? variance;
  final String status; // 'Open' or 'Closed'

  const CashierSessionEntity({
    required this.id,
    required this.outletId,
    required this.outletName,
    required this.userId,
    required this.userName,
    required this.openingTime,
    this.closingTime,
    required this.openingCash,
    required this.expectedCash,
    this.actualCash,
    this.variance,
    required this.status,
  });

  @override
  List<Object?> get props => [
    id,
    outletId,
    outletName,
    userId,
    userName,
    openingTime,
    closingTime,
    openingCash,
    expectedCash,
    actualCash,
    variance,
    status,
  ];
}
