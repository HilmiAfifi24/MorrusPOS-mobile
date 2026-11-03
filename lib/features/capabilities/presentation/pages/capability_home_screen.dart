import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/capability_codes.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/access_policy.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../auth/presentation/pages/outlet_select_screen.dart';
import '../../../checkout/presentation/pages/settings_screen.dart';
import '../../../checkout/presentation/pages/transaction_history_screen.dart';
import '../../../products/presentation/pages/pos_screen.dart';
import '../bloc/capability_bloc.dart';
import '../widgets/capability_gate.dart';

class CapabilityHomeScreen extends StatefulWidget {
  final StorageService storageService;

  const CapabilityHomeScreen({super.key, required this.storageService});

  @override
  State<CapabilityHomeScreen> createState() => _CapabilityHomeScreenState();
}

class _CapabilityHomeScreenState extends State<CapabilityHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() {
    if (!mounted) return;
    final auth = context.read<AuthBloc>().state;
    if (auth is Authenticated && auth.selectedOutletId?.isNotEmpty == true) {
      context.read<CapabilityBloc>().add(
        LoadCapabilities(auth.selectedOutletId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.read<CapabilityBloc>().add(const ClearCapabilities());
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LoginScreen(storageService: widget.storageService),
            ),
            (_) => false,
          );
        } else if (state is Authenticated && state.selectedOutletId == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OutletSelectScreen(storageService: widget.storageService),
            ),
          );
        }
      },
      child: BlocBuilder<CapabilityBloc, CapabilityState>(
        builder: (context, state) {
          if (state is CapabilityFailure) {
            return _LoadFailure(message: state.message, onRetry: _reload);
          }
          if (state is! CapabilityLoaded) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memeriksa fitur outlet...'),
                  ],
                ),
              ),
            );
          }

          final auth = context.read<AuthBloc>().state;
          final user = auth is Authenticated ? auth.user : null;
          final posEnabled =
              state.has(CapabilityCodes.salesPos) &&
              state.has(CapabilityCodes.catalogProducts);
          final canUsePos =
              user != null && canCreateTransactions(user) && posEnabled;
          if (canUsePos) {
            return PosScreen(storageService: widget.storageService);
          }
          return _LimitedHome(
            storageService: widget.storageService,
            posEnabled: posEnabled,
            canViewTransactions:
                user != null &&
                canReadTransactions(user) &&
                state.has(CapabilityCodes.salesTransactions),
          );
        },
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadFailure({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MorrusPOS')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat akses fitur',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(OutletSelectionRequested()),
                child: const Text('Ganti Outlet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LimitedHome extends StatelessWidget {
  final StorageService storageService;
  final bool posEnabled;
  final bool canViewTransactions;

  const _LimitedHome({
    required this.storageService,
    required this.posEnabled,
    required this.canViewTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MorrusPOS Mobile'),
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(storageService: storageService),
              ),
            );
            if (context.mounted) {
              context.read<CapabilityBloc>().add(const CapabilitiesStale());
            }
          },
        ),
        actions: [
          if (canViewTransactions)
            IconButton(
              tooltip: 'Riwayat transaksi',
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CapabilityGate(
                    requiredCapabilities: [CapabilityCodes.salesTransactions],
                    child: TransactionHistoryScreen(),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.point_of_sale_outlined,
                size: 72,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 20),
              Text(
                posEnabled ? 'Akses POS dibatasi' : 'POS belum aktif',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                posEnabled
                    ? 'Role atau permission akun ini tidak memiliki akses POS.'
                    : 'POS atau katalog produk belum diaktifkan untuk outlet ini.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(OutletSelectionRequested()),
                child: const Text('Ganti Outlet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
