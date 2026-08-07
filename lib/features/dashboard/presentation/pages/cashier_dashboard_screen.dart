import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/repositories/dashboard_repository.dart';

class CashierDashboardScreen extends StatefulWidget {
  const CashierDashboardScreen({super.key});

  @override
  State<CashierDashboardScreen> createState() => _CashierDashboardScreenState();
}

class _CashierDashboardScreenState extends State<CashierDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  CashierDashboardData? _data;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final outletId = authState.selectedOutletId ?? '';
        if (outletId.isNotEmpty) {
          final repo = context.read<DashboardRepository>();
          final result = await repo.getCashierDashboard(outletId);
          setState(() {
            _data = result;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Outlet belum dipilih.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Pengguna tidak terautentikasi.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '').replaceAll('ServerFailure: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              )
            ],
          ),
        ),
      );
    }

    if (_data == null || !_data!.activeSession) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 72, color: theme.colorScheme.primary.withOpacity(0.5)),
              const SizedBox(height: 20),
              const Text(
                'Sesi Kasir Belum Dibuka',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Buka sesi kasir di menu Sesi terlebih dahulu untuk melihat dashboard ringkasan shift hari ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final d = _data!;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill, color: Colors.green, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sesi Kasir Aktif',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${d.sessionId?.substring(0, 8) ?? ""}',
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'OPEN',
                      style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // KPI Grid
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    theme: theme,
                    title: 'Modal Awal',
                    value: CurrencyFormatter.format(d.openingCash),
                    icon: Icons.money,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    theme: theme,
                    title: 'Total Omzet',
                    value: CurrencyFormatter.format(d.totalSalesThisSession),
                    icon: Icons.point_of_sale,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildKpiCard(
              theme: theme,
              title: 'Jumlah Transaksi',
              value: '${d.totalTransactionsThisSession} Struk',
              icon: Icons.receipt_long,
              color: Colors.teal,
            ),
            const SizedBox(height: 24),

            // Payment Methods Breakdown
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (d.paymentMethods.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada transaksi terproses.',
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: d.paymentMethods.map((pm) {
                    final percentage = d.totalSalesThisSession > 0
                        ? pm.amount / d.totalSalesThisSession
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pm.method.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '${CurrencyFormatter.format(pm.amount)} (${pm.count}x)',
                                style: const TextStyle(fontSize: 13, color: Colors.white70),
                              )
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getPaymentMethodColor(pm.method, theme),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 24),

            // Recent Transactions List
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (d.recentTransactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada riwayat transaksi.',
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: d.recentTransactions.length,
                itemBuilder: (context, index) {
                  final tx = d.recentTransactions[index];
                  final formattedTime = '${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        tx.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        '$formattedTime • ${tx.paymentMethod.toUpperCase()}',
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                      trailing: Text(
                        CurrencyFormatter.format(tx.grandTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.greenAccent),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(String method, ThemeData theme) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'qris':
        return Colors.blue;
      case 'edc':
        return Colors.purple;
      default:
        return theme.colorScheme.primary;
    }
  }
}
