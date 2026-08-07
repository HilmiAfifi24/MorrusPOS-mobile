import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/failures.dart';

class PaymentMethodDistribution {
  final String method;
  final double amount;
  final int count;

  PaymentMethodDistribution({
    required this.method,
    required this.amount,
    required this.count,
  });

  factory PaymentMethodDistribution.fromJson(Map<String, dynamic> json) {
    return PaymentMethodDistribution(
      method: json['method'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] ?? 0,
    );
  }
}

class RecentTransaction {
  final String transactionId;
  final String invoiceNumber;
  final DateTime createdAt;
  final double grandTotal;
  final String paymentMethod;

  RecentTransaction({
    required this.transactionId,
    required this.invoiceNumber,
    required this.createdAt,
    required this.grandTotal,
    required this.paymentMethod,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    return RecentTransaction(
      transactionId: json['transactionId'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 'cash',
    );
  }
}

class CashierDashboardData {
  final bool activeSession;
  final String? sessionId;
  final double openingCash;
  final double totalSalesThisSession;
  final int totalTransactionsThisSession;
  final List<PaymentMethodDistribution> paymentMethods;
  final List<RecentTransaction> recentTransactions;

  CashierDashboardData({
    required this.activeSession,
    this.sessionId,
    required this.openingCash,
    required this.totalSalesThisSession,
    required this.totalTransactionsThisSession,
    required this.paymentMethods,
    required this.recentTransactions,
  });

  factory CashierDashboardData.fromJson(Map<String, dynamic> json) {
    var pms = (json['paymentMethodsThisSession'] as List?)
        ?.map((x) => PaymentMethodDistribution.fromJson(x))
        .toList() ?? [];
    var rtxs = (json['recentTransactions'] as List?)
        ?.map((x) => RecentTransaction.fromJson(x))
        .toList() ?? [];

    return CashierDashboardData(
      activeSession: json['activeSession'] ?? false,
      sessionId: json['sessionId'],
      openingCash: (json['openingCash'] as num?)?.toDouble() ?? 0.0,
      totalSalesThisSession: (json['totalSalesThisSession'] as num?)?.toDouble() ?? 0.0,
      totalTransactionsThisSession: json['totalTransactionsThisSession'] ?? 0,
      paymentMethods: pms,
      recentTransactions: rtxs,
    );
  }
}

class DashboardRepository {
  final ApiClient apiClient;

  DashboardRepository({required this.apiClient});

  Future<CashierDashboardData> getCashierDashboard(String outletId) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final endDate = now.toUtc().toIso8601String();

      final response = await apiClient.get(
        '/api/dashboard/role-summary',
        queryParams: {
          'outletId': outletId,
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final kasirData = data['kasirData'];
        if (kasirData == null) {
          throw ServerFailure('Data kasir tidak ditemukan di dashboard.');
        }
        return CashierDashboardData.fromJson(kasirData);
      } else {
        throw ServerFailure('Gagal memuat dashboard kasir mobile.');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Koneksi internet bermasalah.');
    }
  }
}
