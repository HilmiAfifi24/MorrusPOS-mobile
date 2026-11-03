import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/storage_service.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'core/network/realtime_service.dart';

import 'features/cashier_session/data/repositories/cashier_session_repository_impl.dart';
import 'features/cashier_session/domain/repositories/cashier_session_repository.dart';
import 'features/cashier_session/presentation/bloc/cashier_session_bloc.dart';

import 'features/products/data/repositories/products_repository_impl.dart';
import 'features/products/domain/repositories/products_repository.dart';
import 'features/products/presentation/bloc/products_bloc.dart';

import 'features/checkout/data/repositories/checkout_repository_impl.dart';
import 'features/checkout/domain/repositories/checkout_repository.dart';
import 'features/checkout/presentation/bloc/cart_bloc.dart';
import 'features/checkout/presentation/bloc/checkout_bloc.dart';
import 'features/dashboard/data/repositories/dashboard_repository.dart';
import 'features/capabilities/data/repositories/capability_repository_impl.dart';
import 'features/capabilities/domain/repositories/capability_repository.dart';
import 'features/capabilities/presentation/bloc/capability_bloc.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  
  final httpClient = http.Client();
  final apiClient = ApiClient(httpClient, storageService);

  // Initialize repositories
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(apiClient),
    storageService: storageService,
  );

  final cashierSessionRepository = CashierSessionRepositoryImpl(
    apiClient: apiClient,
  );

  final productsRepository = ProductsRepositoryImpl(
    apiClient: apiClient,
  );

  final checkoutRepository = CheckoutRepositoryImpl(
    apiClient: apiClient,
  );

  final realtimeService = RealtimeService(
    storageService: storageService,
  );

  final dashboardRepository = DashboardRepository(apiClient: apiClient);
  final capabilityRepository = CapabilityRepositoryImpl(apiClient: apiClient);
  final capabilityBloc = CapabilityBloc(repository: capabilityRepository);
  apiClient.onCapabilityDisabled = (_) => capabilityBloc.add(const CapabilitiesStale());

  runApp(MorrusPOSApp(
    storageService: storageService,
    authRepository: authRepository,
    cashierSessionRepository: cashierSessionRepository,
    productsRepository: productsRepository,
    checkoutRepository: checkoutRepository,
    realtimeService: realtimeService,
    dashboardRepository: dashboardRepository,
    capabilityRepository: capabilityRepository,
    capabilityBloc: capabilityBloc,
  ));
}

class MorrusPOSApp extends StatelessWidget {
  final StorageService storageService;
  final AuthRepository authRepository;
  final CashierSessionRepository cashierSessionRepository;
  final ProductsRepository productsRepository;
  final CheckoutRepository checkoutRepository;
  final RealtimeService realtimeService;
  final DashboardRepository dashboardRepository;
  final CapabilityRepository capabilityRepository;
  final CapabilityBloc capabilityBloc;

  const MorrusPOSApp({
    super.key,
    required this.storageService,
    required this.authRepository,
    required this.cashierSessionRepository,
    required this.productsRepository,
    required this.checkoutRepository,
    required this.realtimeService,
    required this.dashboardRepository,
    required this.capabilityRepository,
    required this.capabilityBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<CashierSessionRepository>.value(value: cashierSessionRepository),
        RepositoryProvider<ProductsRepository>.value(value: productsRepository),
        RepositoryProvider<CheckoutRepository>.value(value: checkoutRepository),
        RepositoryProvider<RealtimeService>.value(value: realtimeService),
        RepositoryProvider<DashboardRepository>.value(value: dashboardRepository),
        RepositoryProvider<CapabilityRepository>.value(value: capabilityRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(authRepository: authRepository),
          ),
          BlocProvider<CashierSessionBloc>(
            create: (context) => CashierSessionBloc(repository: cashierSessionRepository),
          ),
          BlocProvider<ProductsBloc>(
            create: (context) => ProductsBloc(repository: productsRepository),
          ),
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(),
          ),
          BlocProvider<CheckoutBloc>(
            create: (context) => CheckoutBloc(repository: checkoutRepository),
          ),
          BlocProvider<CapabilityBloc>.value(value: capabilityBloc),
        ],
        child: MaterialApp(
          title: 'MorrusPOS Mobile',
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: SplashScreen(storageService: storageService),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
