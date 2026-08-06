import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../bloc/cashier_session_bloc.dart';
import '../bloc/cashier_session_event.dart';
import '../bloc/cashier_session_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class CashierSessionScreen extends StatefulWidget {
  const CashierSessionScreen({super.key});

  @override
  State<CashierSessionScreen> createState() => _CashierSessionScreenState();
}

class _CashierSessionScreenState extends State<CashierSessionScreen> {
  final _openingCashController = TextEditingController(text: '0');
  final _actualCashController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _openingCashController.dispose();
    _actualCashController.dispose();
    super.dispose();
  }

  void _openSession(String outletId) {
    if (_formKey.currentState!.validate()) {
      final cash = double.tryParse(_openingCashController.text) ?? 0.0;
      context.read<CashierSessionBloc>().add(
            OpenSessionSubmitted(outletId: outletId, openingCash: cash),
          );
    }
  }

  void _closeSession(String sessionId) {
    if (_formKey.currentState!.validate()) {
      final cash = double.tryParse(_actualCashController.text) ?? 0.0;
      context.read<CashierSessionBloc>().add(
            CloseSessionSubmitted(sessionId: sessionId, actualCash: cash),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    String outletId = '';
    if (authState is Authenticated) {
      outletId = authState.selectedOutletId ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesi Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (outletId.isNotEmpty) {
                context.read<CashierSessionBloc>().add(CheckActiveSession(outletId));
              }
            },
          )
        ],
      ),
      body: BlocConsumer<CashierSessionBloc, CashierSessionState>(
        listener: (context, state) {
          if (state is CashierSessionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          if (state is CashierSessionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ActiveSessionOpen) {
            return _buildCloseSessionView(theme, state.session);
          }

          return _buildOpenSessionView(theme, outletId);
        },
      ),
    );
  }

  Widget _buildOpenSessionView(ThemeData theme, String outletId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(Icons.lock_open, size: 64, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Buka Sesi Kasir Baru',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Masukkan jumlah uang tunai di laci mesin kasir (kas awal) sebelum melayani penjualan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _openingCashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Uang Kas Awal (Rp)',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kas awal wajib diisi';
                }
                if (double.tryParse(value) == null || double.parse(value) < 0) {
                  return 'Nominal uang tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _openSession(outletId),
              child: const Text('Buka Sesi Jualan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseSessionView(ThemeData theme, session) {
    final timeFormat = DateFormat('dd MMM yyyy, HH:mm');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sesi Kasir Aktif',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'OPEN',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 24, color: Colors.white10),
                  _buildDetailRow('Nama Kasir', session.userName),
                  _buildDetailRow('Outlet', session.outletName),
                  _buildDetailRow('Waktu Buka', timeFormat.format(session.openingTime.toLocal())),
                  _buildDetailRow('Modal Kas Awal', CurrencyFormatter.format(session.openingCash)),
                  _buildDetailRow('Ekspektasi Kas Laci', CurrencyFormatter.format(session.expectedCash), isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tutup Sesi Kasir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hitung uang fisik di laci kasir dan masukkan jumlah aktualnya di bawah ini.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _actualCashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Kas Aktual Fisik (Rp)',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.calculate_outlined),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kas aktual wajib diisi';
                }
                if (double.tryParse(value) == null || double.parse(value) < 0) {
                  return 'Nominal uang tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _closeSession(session.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shadowColor: Colors.redAccent.withOpacity(0.4),
              ),
              child: const Text('Tutup Sesi Kasir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 15 : 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.greenAccent : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
