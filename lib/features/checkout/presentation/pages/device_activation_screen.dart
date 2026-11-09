import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/storage_service.dart';

class DeviceActivationScreen extends StatefulWidget {
  final ApiClient apiClient;
  final StorageService storageService;

  const DeviceActivationScreen({
    super.key,
    required this.apiClient,
    required this.storageService,
  });

  @override
  State<DeviceActivationScreen> createState() => _DeviceActivationScreenState();
}

class _DeviceActivationScreenState extends State<DeviceActivationScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController(text: 'MorrusPOS Mobile');
  bool _loading = false;
  String? _deviceId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBinding();
  }

  Future<void> _loadBinding() async {
    final deviceId = await widget.storageService.posDeviceId;
    if (mounted) setState(() => _deviceId = deviceId);
  }

  Future<void> _activate() async {
    if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final response = await widget.apiClient.post(
        '/api/pos-devices/pair',
        body: {
          'code': _code.text.trim().toUpperCase(),
          'installationId': await widget.storageService.getOrCreateInstallationId(),
          'name': _name.text.trim(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'appVersion': null,
        },
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(body['message']?.toString() ?? 'Aktivasi perangkat gagal.');
      }
      await widget.storageService.savePosDeviceBinding(
        body['deviceId'].toString(),
        body['token'].toString(),
      );
      if (mounted) {
        setState(() { _deviceId = body['deviceId'].toString(); _code.clear(); });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clear() async {
    await widget.storageService.clearPosDeviceBinding();
    if (mounted) setState(() => _deviceId = null);
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivasi Perangkat POS')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_deviceId != null) ...[
            const Icon(Icons.verified_outlined, size: 72, color: Colors.greenAccent),
            const SizedBox(height: 16),
            const Text('Perangkat aktif', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(_deviceId!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(onPressed: _clear, icon: const Icon(Icons.delete_outline), label: const Text('Hapus binding lokal')),
          ] else ...[
            const Text('Masukkan kode pairing sekali pakai dari Owner/Admin.'),
            const SizedBox(height: 20),
            TextField(controller: _code, textCapitalization: TextCapitalization.characters, maxLength: 8, decoration: const InputDecoration(labelText: 'Kode pairing')),
            const SizedBox(height: 12),
            TextField(controller: _name, maxLength: 100, decoration: const InputDecoration(labelText: 'Nama perangkat')),
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
            ElevatedButton.icon(
              onPressed: _loading ? null : _activate,
              icon: const Icon(Icons.phonelink_setup),
              label: Text(_loading ? 'Mengaktifkan...' : 'Aktifkan perangkat'),
            ),
          ],
        ],
      ),
    );
  }
}
