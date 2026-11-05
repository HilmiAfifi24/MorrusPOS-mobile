import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos/features/cashier_session/domain/entities/cashier_session_entity.dart';
import 'package:mobile_pos/features/cashier_session/domain/repositories/cashier_session_repository.dart';
import 'package:mobile_pos/features/cashier_session/presentation/bloc/cashier_session_bloc.dart';

final session = CashierSessionEntity(
  id: 'session-1',
  outletId: 'outlet-1',
  outletName: 'Outlet Utama',
  userId: 'user-1',
  userName: 'Kasir Test',
  openingTime: DateTime.utc(2026, 11, 5),
  openingCash: 100000,
  expectedCash: 100000,
  status: 'open',
);

void main() {
  test('membuka sesi mengirim outlet dan kas awal', () async {
    final repository = _CashierRepository();
    final bloc = CashierSessionBloc(repository: repository);
    addTearDown(bloc.close);

    bloc.add(
      const OpenSessionSubmitted(outletId: 'outlet-1', openingCash: 100000),
    );
    final state = await bloc.stream.firstWhere(
      (state) => state is ActiveSessionOpen,
    );

    expect(state, ActiveSessionOpen(session));
    expect(repository.openedOutletId, 'outlet-1');
    expect(repository.openingCash, 100000);
  });

  test('kegagalan membuka sesi berakhir tanpa sesi aktif', () async {
    final bloc = CashierSessionBloc(
      repository: _CashierRepository(openError: Exception('Sesi masih aktif')),
    );
    addTearDown(bloc.close);

    final statesFuture = bloc.stream.take(3).toList();
    bloc.add(
      const OpenSessionSubmitted(outletId: 'outlet-1', openingCash: 100000),
    );
    final states = await statesFuture;
    final failure = states[1] as CashierSessionFailure;

    expect(failure.message, contains('Sesi masih aktif'));
    expect(states[2], isA<NoActiveSession>());
  });
}

class _CashierRepository implements CashierSessionRepository {
  final Object? openError;
  String? openedOutletId;
  double? openingCash;

  _CashierRepository({this.openError});

  @override
  Future<CashierSessionEntity?> getActiveSession(String outletId) async => null;
  @override
  Future<CashierSessionEntity> openSession(
    String outletId,
    double openingCash,
  ) async {
    if (openError != null) throw openError!;
    openedOutletId = outletId;
    this.openingCash = openingCash;
    return session;
  }

  @override
  Future<CashierSessionEntity> closeSession(
    String sessionId,
    double actualCash,
  ) async => session;
}
