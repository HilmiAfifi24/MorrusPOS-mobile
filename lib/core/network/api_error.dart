import 'dart:convert';
import 'package:http/http.dart' as http;
import '../error/failures.dart';

Failure failureFromResponse(http.Response response, String fallbackMessage) {
  try {
    final payload = jsonDecode(response.body);
    if (payload is Map<String, dynamic>) {
      final code = payload['code']?.toString();
      final trackingMessage = <String, String>{
        'TRACKING_MODE_INVALID': 'Mode tracking produk tidak valid.',
        'BATCH_REQUIRED': 'Pilih batch sebelum melanjutkan.',
        'BATCH_NOT_FOUND': 'Batch tidak ditemukan.',
        'BATCH_STOCK_INSUFFICIENT': 'Stok batch tidak mencukupi.',
        'SERIAL_REQUIRED': 'Pilih serial/IMEI sebelum melanjutkan.',
        'SERIAL_DUPLICATE': 'Serial/IMEI tidak boleh duplikat.',
        'SERIAL_NOT_AVAILABLE': 'Serial/IMEI sudah tidak tersedia.',
        'TRACKING_ALLOCATION_MISMATCH':
            'Jumlah batch atau serial tidak cocok dengan qty.',
      }[code];
      final message =
          payload['message']?.toString() ?? trackingMessage ?? fallbackMessage;
      if (response.statusCode == 403 &&
          payload['code'] == 'CAPABILITY_DISABLED') {
        return CapabilityDisabledFailure(
          payload['capability']?.toString() ?? '',
          message,
        );
      }
      if (trackingMessage != null && code != null) {
        return TrackingFailure(code, message);
      }
      return ServerFailure(message);
    }
  } catch (_) {}
  return ServerFailure(fallbackMessage);
}
