import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_pos/core/error/failures.dart';
import 'package:mobile_pos/core/network/api_error.dart';
import 'package:mobile_pos/features/checkout/presentation/bloc/cart_bloc.dart';
import 'package:mobile_pos/features/products/data/models/product_model.dart';
import 'package:mobile_pos/features/products/domain/entities/product_entity.dart';

ProductEntity product(String trackingMode, {double stock = 10}) =>
    ProductEntity(
      id: 'product-1',
      name: 'Produk',
      sku: 'SKU-1',
      basePrice: 10000,
      qtyOnHand: stock,
      trackingMode: trackingMode,
    );

void main() {
  test('unknown tracking mode fails closed', () {
    final parsed = ProductModel.fromJson({
      'id': 'product-1',
      'name': 'Produk',
      'sku': 'SKU-1',
      'basePrice': 10000,
      'qtyOnHand': 10,
      'trackingMode': 'future-mode',
    });

    expect(parsed.trackingMode, 'invalid');
    expect(
      ProductEntity.validTrackingModes.contains(parsed.trackingMode),
      isFalse,
    );
  });

  test(
    'cart accepts FEFO batch split only when allocation matches qty',
    () async {
      final bloc = CartBloc();
      bloc.add(
        AddToCart(
          product('batch'),
          qty: 3,
          batchAllocations: const {'batch-a': 1, 'batch-b': 2},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.items.single.qty, 3);
      expect(bloc.state.items.single.batchAllocations, const {
        'batch-a': 1,
        'batch-b': 2,
      });

      bloc.add(
        AddToCart(
          product('batch'),
          qty: 2,
          batchAllocations: const {'batch-a': 1},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.items.single.qty, 3);
      await bloc.close();
    },
  );

  test('cart rejects duplicate serials', () async {
    final bloc = CartBloc();
    bloc.add(
      AddToCart(
        product('serial'),
        qty: 2,
        serialIds: const ['serial-a', 'serial-b'],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    bloc.add(AddToCart(product('serial'), serialIds: const ['serial-b']));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.items.single.qty, 2);
    expect(bloc.state.items.single.serialIds, const ['serial-a', 'serial-b']);
    await bloc.close();
  });

  test('tracking API codes remain structured and user friendly', () {
    final failure = failureFromResponse(
      http.Response('{"code":"SERIAL_DUPLICATE"}', 400),
      'fallback',
    );

    expect(failure, isA<TrackingFailure>());
    expect((failure as TrackingFailure).code, 'SERIAL_DUPLICATE');
    expect(failure.message, 'Serial/IMEI tidak boleh duplikat.');
  });
}
