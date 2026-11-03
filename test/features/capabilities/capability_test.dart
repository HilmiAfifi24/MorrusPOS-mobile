import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pos/core/network/api_client.dart';
import 'package:mobile_pos/core/utils/storage_service.dart';
import 'package:mobile_pos/features/capabilities/data/models/capability_snapshot_model.dart';
import 'package:mobile_pos/features/capabilities/data/repositories/capability_repository_impl.dart';
import 'package:mobile_pos/features/capabilities/domain/entities/capability_snapshot_entity.dart';
import 'package:mobile_pos/features/capabilities/domain/repositories/capability_repository.dart';
import 'package:mobile_pos/features/capabilities/presentation/bloc/capability_bloc.dart';
import 'package:mobile_pos/features/capabilities/presentation/widgets/capability_gate.dart';
import 'package:mobile_pos/features/auth/domain/access_policy.dart';
import 'package:mobile_pos/features/auth/domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('snapshot only enables known entries marked true', () {
    final snapshot = CapabilitySnapshotModel.fromJson({
      'outletId': 'outlet-1',
      'revision': 4,
      'capabilities': [
        {'code': 'sales.pos', 'enabled': true},
        {'code': 'sales.transactions', 'enabled': false},
      ],
    });

    expect(snapshot.has('sales.pos'), isTrue);
    expect(snapshot.has('sales.transactions'), isFalse);
    expect(snapshot.has('unknown.capability'), isFalse);
  });

  test('mobile menu still requires role or permission', () {
    const warehouseUser = UserEntity(
      id: 'user-1',
      name: 'Gudang',
      email: 'gudang@example.test',
      role: 'Gudang',
      permissions: [],
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    const customUser = UserEntity(
      id: 'user-2',
      name: 'Custom',
      email: 'custom@example.test',
      role: 'Custom',
      permissions: ['transaction.create'],
      accessToken: 'access',
      refreshToken: 'refresh',
    );

    expect(canCreateTransactions(warehouseUser), isFalse);
    expect(canReadTransactions(warehouseUser), isFalse);
    expect(canCreateTransactions(customUser), isTrue);
  });

  test(
    'repository requests effective capabilities for selected outlet',
    () async {
      SharedPreferences.setMockInitialValues({
        'server_base_url': 'https://example.test',
        'auth_token': 'token',
      });
      final storage = StorageService(await SharedPreferences.getInstance());
      late Uri requestedUri;
      final client = ApiClient(
        MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'outletId': 'outlet-1',
              'revision': 1,
              'capabilities': [
                {'code': 'sales.pos', 'enabled': true},
              ],
            }),
            200,
          );
        }),
        storage,
      );

      final snapshot = await CapabilityRepositoryImpl(
        apiClient: client,
      ).getEffective('outlet-1');

      expect(requestedUri.path, '/api/capabilities/effective');
      expect(requestedUri.queryParameters['outletId'], 'outlet-1');
      expect(snapshot.has('sales.pos'), isTrue);
    },
  );

  test(
    'api client marks capability snapshot stale after structured 403',
    () async {
      SharedPreferences.setMockInitialValues({
        'server_base_url': 'https://example.test',
        'auth_token': 'token',
      });
      final storage = StorageService(await SharedPreferences.getInstance());
      final client = ApiClient(
        MockClient(
          (request) async => http.Response(
            jsonEncode({
              'code': 'CAPABILITY_DISABLED',
              'capability': 'sales.transactions',
              'message': 'Fitur nonaktif',
            }),
            403,
          ),
        ),
        storage,
      );
      String? staleCapability;
      client.onCapabilityDisabled = (code) => staleCapability = code;

      await client.get('/api/transactions');

      expect(staleCapability, 'sales.transactions');
    },
  );

  test('bloc fails closed when capability request fails', () async {
    final bloc = CapabilityBloc(repository: _FailingCapabilityRepository());
    addTearDown(bloc.close);

    bloc.add(const LoadCapabilities('outlet-1'));
    final state = await bloc.stream.firstWhere(
      (state) => state is CapabilityFailure,
    );

    expect(state, isA<CapabilityFailure>());
  });

  testWidgets('gate renders child only when every capability is enabled', (
    tester,
  ) async {
    final bloc = CapabilityBloc(
      repository: _StaticCapabilityRepository(
        const CapabilitySnapshotEntity(
          outletId: 'outlet-1',
          revision: 1,
          enabledCodes: {'sales.pos'},
        ),
      ),
    );
    addTearDown(bloc.close);
    bloc.add(const LoadCapabilities('outlet-1'));
    await bloc.stream.firstWhere((state) => state is CapabilityLoaded);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: const CapabilityGate(
            requiredCapabilities: ['sales.pos', 'catalog.products'],
            child: Text('POS aktif'),
          ),
        ),
      ),
    );

    expect(find.text('POS aktif'), findsNothing);
    expect(find.text('Fitur belum aktif'), findsOneWidget);
  });
}

class _StaticCapabilityRepository implements CapabilityRepository {
  final CapabilitySnapshotEntity snapshot;

  _StaticCapabilityRepository(this.snapshot);

  @override
  Future<CapabilitySnapshotEntity> getEffective(String outletId) async =>
      snapshot;
}

class _FailingCapabilityRepository implements CapabilityRepository {
  @override
  Future<CapabilitySnapshotEntity> getEffective(String outletId) {
    throw Exception('offline');
  }
}
