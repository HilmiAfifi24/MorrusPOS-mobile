import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/checkout_repository.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final ApiClient apiClient;

  CheckoutRepositoryImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> checkout({
    required String requestId,
    required String paymentId,
    required String outletId,
    required String cashierSessionId,
    required double subtotal,
    required double discountTotal,
    required double taxTotal,
    required double grandTotal,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> payments,
    String? voucherCode,
    String? appliedPromoCode,
  }) async {
    try {
      final body = {
        'id': requestId,
        'outletId': outletId,
        'cashierSessionId': cashierSessionId,
        'channel': 'pos',
        'subtotal': subtotal,
        'discountTotal': discountTotal,
        'taxTotal': taxTotal,
        'grandTotal': grandTotal,
        'items': items,
        'payments': payments.map((payment) => {...payment, 'id': paymentId}).toList(),
        'voucherCode': voucherCode,
        'appliedPromoCode': appliedPromoCode,
      };

      await apiClient.savePendingCheckout(body);
      final response = await apiClient.post(
        ApiEndpoints.checkout,
        body: body,
        headers: {'Idempotency-Key': requestId},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await apiClient.clearPendingCheckout();
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw failureFromResponse(response, 'Gagal memproses checkout.');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal melakukan checkout: koneksi bermasalah.');
    }
  }

  @override
  Future<Map<String, dynamic>> previewPricing({
    required String outletId,
    required List<Map<String, dynamic>> items,
    String? voucherCode,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiEndpoints.transactions}/pricing-preview',
        body: {
          'outletId': outletId,
          'channel': 'pos',
          'voucherCode': voucherCode,
          'items': items,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw failureFromResponse(response, 'Gagal menghitung pricing checkout.');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal memuat pricing checkout: koneksi bermasalah.');
    }
  }

  @override
  Map<String, dynamic>? getPendingCheckout() => apiClient.getPendingCheckout();

  @override
  Future<Map<String, dynamic>> retryPendingCheckout() async {
    final body = apiClient.getPendingCheckout();
    if (body == null || body['id'] == null) {
      throw const ServerFailure('Tidak ada checkout tertunda.');
    }
    final response = await apiClient.post(
      ApiEndpoints.checkout,
      body: body,
      headers: {'Idempotency-Key': body['id'].toString()},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      await apiClient.clearPendingCheckout();
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw failureFromResponse(response, 'Gagal mengulang checkout tertunda.');
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentTransactions(
    String outletId,
  ) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.transactions,
        queryParams: {'outletId': outletId, 'take': '40'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((x) => x as Map<String, dynamic>).toList();
      } else {
        throw failureFromResponse(
          response,
          'Gagal mengambil histori transaksi.',
        );
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal memuat transaksi: koneksi bermasalah.');
    }
  }

  @override
  Future<Map<String, dynamic>> getTransactionById(String id) async {
    try {
      final response = await apiClient.get('${ApiEndpoints.transactions}/$id');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw failureFromResponse(
          response,
          'Gagal mengambil detail transaksi.',
        );
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal memuat detail transaksi: koneksi bermasalah.');
    }
  }

  @override
  Future<void> voidTransaction(String id, String reason) async {
    try {
      final response = await apiClient.post(
        '${ApiEndpoints.transactions}/$id/void',
        body: {'reason': reason},
      );

      if (response.statusCode != 200) {
        throw failureFromResponse(response, 'Gagal membatalkan transaksi.');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal membatalkan transaksi: koneksi bermasalah.');
    }
  }
}
