import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos/core/network/api_client.dart';
import 'package:mobile_pos/core/utils/storage_service.dart';
import 'package:mobile_pos/features/inventory_transfer/data/repositories/stock_transfer_repository.dart';
import 'package:mobile_pos/features/inventory_transfer/domain/entities/stock_transfer_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('transfer parser keeps sent, received, and difference quantities', () {
    final transfer = StockTransferEntity.fromJson({
      'id': 'transfer-1',
      'transferNumber': 'TRF-001',
      'status': 'received_with_variance',
      'fromStockLocationName': 'Gudang',
      'toStockLocationName': 'Outlet',
      'createdAt': '2026-11-11T00:00:00Z',
      'items': [
        {
          'id': 'item-1',
          'productId': 'product-1',
          'productName': 'Kopi',
          'sku': 'KOPI',
          'sentQty': 10,
          'receivedQty': 8,
          'differenceQty': -2,
        },
      ],
    });
    expect(transfer.items.single.sentQty, 10);
    expect(transfer.items.single.receivedQty, 8);
    expect(transfer.items.single.differenceQty, -2);
  });

  test('send forwards the request ID as idempotency header', () async {
    SharedPreferences.setMockInitialValues({
      'server_base_url': 'https://example.test',
      'auth_token': 'token',
    });
    final storage = StorageService(await SharedPreferences.getInstance());
    String? header;
    final repository = StockTransferRepository(
      ApiClient(
        MockClient((request) async {
          header = request.headers['Idempotency-Key'];
          return http.Response(
            jsonEncode({'id': 'transfer-1'}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
        storage,
      ),
    );
    await repository.send({
      'requestId': '1a829c30-faf3-4d1a-b593-7abf595f18f8',
      'items': [],
    });
    expect(header, '1a829c30-faf3-4d1a-b593-7abf595f18f8');
  });
}
