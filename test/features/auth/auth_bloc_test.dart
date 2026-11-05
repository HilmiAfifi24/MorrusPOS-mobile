import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos/features/auth/domain/entities/user_entity.dart';
import 'package:mobile_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile_pos/features/auth/presentation/bloc/auth_bloc.dart';

const user = UserEntity(
  id: 'user-1',
  name: 'Kasir Test',
  email: 'kasir@example.test',
  role: 'Kasir',
  outletId: 'outlet-1',
  permissions: ['transaction.create'],
  accessToken: 'access',
  refreshToken: 'refresh',
);

void main() {
  test('app started memulihkan user dan outlet tersimpan', () async {
    final repository = _AuthRepository(
      cachedUser: user,
      selectedOutletId: 'outlet-1',
    );
    final bloc = AuthBloc(authRepository: repository);
    addTearDown(bloc.close);

    bloc.add(AppStarted());
    final state =
        await bloc.stream.firstWhere((state) => state is Authenticated)
            as Authenticated;

    expect(state.user, user);
    expect(state.selectedOutletId, 'outlet-1');
  });

  test('login gagal tidak meninggalkan state authenticated', () async {
    final bloc = AuthBloc(
      authRepository: _AuthRepository(
        loginError: Exception('Email atau password salah.'),
      ),
    );
    addTearDown(bloc.close);

    final statesFuture = bloc.stream.take(3).toList();
    bloc.add(
      const LoginSubmitted(email: 'wrong@example.test', password: 'wrong'),
    );
    final states = await statesFuture;
    final failure = states[1] as AuthFailure;

    expect(failure.message, contains('Email atau password salah'));
    expect(states[2], isA<Unauthenticated>());
  });

  test('pemilihan outlet disimpan pada repository', () async {
    final repository = _AuthRepository(cachedUser: user);
    final bloc = AuthBloc(authRepository: repository);
    addTearDown(bloc.close);
    bloc.add(AppStarted());
    await bloc.stream.firstWhere((state) => state is Authenticated);

    bloc.add(const OutletSelected('outlet-2'));
    final state = await bloc.stream.firstWhere(
      (state) => state is Authenticated && state.selectedOutletId == 'outlet-2',
    );

    expect(state, isA<Authenticated>());
    expect(repository.savedOutletId, 'outlet-2');
  });
}

class _AuthRepository implements AuthRepository {
  final UserEntity? cachedUser;
  final String? selectedOutletId;
  final Object? loginError;
  String? savedOutletId;

  _AuthRepository({this.cachedUser, this.selectedOutletId, this.loginError});

  @override
  Future<UserEntity?> getCachedUser() async => cachedUser;
  @override
  Future<String?> getSelectedOutletId() async => selectedOutletId;
  @override
  Future<UserEntity> login(String email, String password) async {
    if (loginError != null) throw loginError!;
    return user;
  }

  @override
  Future<void> saveSelectedOutletId(String outletId) async =>
      savedOutletId = outletId;
  @override
  Future<void> clearSelectedOutletId() async => savedOutletId = null;
  @override
  Future<void> logout() async {}
  @override
  Future<List<Map<String, dynamic>>> getOutlets() async => [];
}
