import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;

  const SettingsScreen({super.key, required this.storageService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.storageService.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await widget.storageService.setBaseUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server URL berhasil diubah ke: $url')),
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi MorrusPOS?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close settings screen
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    String name = 'Kasir';
    String email = 'cashier@morruspos.com';
    String role = 'Kasir';
    if (authState is Authenticated) {
      name = authState.user.name;
      email = authState.user.email;
      role = authState.user.role;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(fontSize: 12, color: Colors.white38)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(color: theme.colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Konfigurasi Koneksi Server', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Base URL API Backend',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_outlined),
                  onPressed: _saveUrl,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ganti URL ini jika backend dideploy di komputer lain dalam satu jaringan WiFi local (misal: http://192.168.1.15:5100).',
              style: TextStyle(fontSize: 11, color: Colors.white30),
            ),
            const SizedBox(height: 48),
            // Actions
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Keluar dari Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.9),
                shadowColor: Colors.redAccent.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
