import 'dart:convert';
import 'dart:math';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/checkout_repository.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final ApiClient apiClient;

  CheckoutRepositoryImpl({required this.apiClient});

  String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Set version to 4 (random)
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant to 10xx
    values[8] = (values[8] & 0x3f) | 0x80;
    
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  @override
  Future<Map<String, dynamic>> checkout({
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
      final transactionId = _generateUuid();
      final body = {
        'id': transactionId,
        'outletId': outletId,
        'cashierSessionId': cashierSessionId,
        'channel': 'pos',
        'subtotal': subtotal,
        'discountTotal': discountTotal,
        'taxTotal': taxTotal,
        'grandTotal': grandTotal,
        'items': items,
        'payments': payments,
        'voucherCode': voucherCode,
        'appliedPromoCode': appliedPromoCode,
      };

      final response = await apiClient.post(ApiEndpoints.checkout, body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        String errMsg = 'Gagal memproses checkout.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errMsg = errorData['message'];
          }
        } catch (_) {}
        throw ServerFailure(errMsg);
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

      String errMsg = 'Gagal menghitung pricing checkout.';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['message'] != null) {
          errMsg = errorData['message'];
        }
      } catch (_) {}
      throw ServerFailure(errMsg);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal memuat pricing checkout: koneksi bermasalah.');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentTransactions(String outletId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.transactions,
        queryParams: {'outletId': outletId, 'take': '40'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((x) => x as Map<String, dynamic>).toList();
      } else {
        throw ServerFailure('Gagal mengambil histori transaksi.');
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
        throw ServerFailure('Gagal mengambil detail transaksi.');
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
        String errMsg = 'Gagal membatalkan transaksi.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errMsg = errorData['message'];
          }
        } catch (_) {}
        throw ServerFailure(errMsg);
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Gagal membatalkan transaksi: koneksi bermasalah.');
    }
  }
}
