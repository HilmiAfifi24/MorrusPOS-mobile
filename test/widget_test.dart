import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos/core/utils/storage_service.dart';
import 'package:mobile_pos/features/auth/domain/entities/user_entity.dart';
import 'package:mobile_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile_pos/features/auth/presentation/pages/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('guest melewati splash dan melihat login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    final bloc = AuthBloc(authRepository: _GuestAuthRepository());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(home: SplashScreen(storageService: storage)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MorrusPOS Mobile'), findsOneWidget);
    expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
  });
}

class _GuestAuthRepository implements AuthRepository {
  @override
  Future<UserEntity?> getCachedUser() async => null;
  @override
  Future<String?> getSelectedOutletId() async => null;
  @override
  Future<UserEntity> login(String email, String password) =>
      throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<void> saveSelectedOutletId(String outletId) async {}
  @override
  Future<void> clearSelectedOutletId() async {}
  @override
  Future<List<Map<String, dynamic>>> getOutlets() async => [];
}
