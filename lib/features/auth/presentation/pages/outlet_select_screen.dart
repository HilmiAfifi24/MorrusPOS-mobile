import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class OutletSelectScreen extends StatefulWidget {
  const OutletSelectScreen({super.key});

  @override
  State<OutletSelectScreen> createState() => _OutletSelectScreenState();
}

class _OutletSelectScreenState extends State<OutletSelectScreen> {
  List<Map<String, dynamic>> _outlets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOutlets();
  }

  Future<void> _loadOutlets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = context.read<AuthBloc>().authRepository;
      final outletsList = await authRepo.getOutlets();
      setState(() {
        _outlets = outletsList.where((o) => o['isActive'] == true).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ServerFailure: ', '');
        _isLoading = false;
      });
    }
  }

  void _selectOutlet(String outletId) {
    context.read<AuthBloc>().add(OutletSelected(outletId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Outlet Kerja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat Datang',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Akun Anda memiliki akses multi-outlet. Silakan pilih salah satu outlet untuk mulai bertransaksi.',
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _buildContent(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.redAccent.shade200),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOutlets,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
            ),
          ],
        ),
      );
    }

    if (_outlets.isEmpty) {
      return const Center(
        child: Text('Tidak ada outlet aktif yang tersedia.'),
      );
    }

    return ListView.separated(
      itemCount: _outlets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final outlet = _outlets[index];
        final String name = outlet['name'] ?? 'Outlet';
        final String code = outlet['code'] ?? '';
        final String phone = outlet['phone'] ?? '-';
        final String id = outlet['id'] ?? '';

        return InkWell(
          onTap: () => _selectOutlet(id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.storefront, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kode: $code  •  Tlp: $phone',
                        style: const TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        );
      },
    );
  }
}
