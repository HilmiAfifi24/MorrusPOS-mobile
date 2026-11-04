import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../bloc/cashier_session_bloc.dart';
import '../bloc/cashier_session_event.dart';
import '../bloc/cashier_session_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../dashboard/data/repositories/dashboard_repository.dart';

class CashierSessionScreen extends StatefulWidget {
  const CashierSessionScreen({super.key});

  @override
  State<CashierSessionScreen> createState() => _CashierSessionScreenState();
}

class _CashierSessionScreenState extends State<CashierSessionScreen> {
  final _openingCashController = TextEditingController(text: '0');
  final _actualCashController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoadingDashboard = false;
  String? _dashboardError;
  CashierDashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final outletId = authState.selectedOutletId;
        if (outletId != null && outletId.isNotEmpty) {
          context.read<CashierSessionBloc>().add(CheckActiveSession(outletId));

          final sessionState = context.read<CashierSessionBloc>().state;
          if (sessionState is ActiveSessionOpen) {
            _loadDashboardData(outletId);
          }
        }
      }
    });
  }

  Future<void> _loadDashboardData(String outletId) async {
    if (_isLoadingDashboard) return;
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });
    try {
      final repo = context.read<DashboardRepository>();
      final data = await repo.getCashierDashboard(outletId);
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dashboardError = e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('ServerFailure: ', '');
          _isLoadingDashboard = false;
        });
      }
    }
  }

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
                context.read<CashierSessionBloc>().add(
                  CheckActiveSession(outletId),
                );
                _loadDashboardData(outletId);
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<CashierSessionBloc, CashierSessionState>(
        listener: (context, state) {
          if (state is CashierSessionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          } else if (state is ActiveSessionOpen) {
            _loadDashboardData(state.session.outletId);
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
                child: Icon(
                  Icons.lock_open,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
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
              child: const Text(
                'Buka Sesi Jualan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseSessionView(ThemeData theme, session) {
    final timeFormat = DateFormat('dd MMM yyyy, HH:mm');
    final d = _dashboardData;

    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(session.outletId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. General Active Session Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sesi Kasir Aktif',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'OPEN',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Colors.white10),
                    _buildDetailRow('Nama Kasir', session.userName),
                    _buildDetailRow('Outlet', session.outletName),
                    _buildDetailRow(
                      'Waktu Buka',
                      timeFormat.format(session.openingTime.toLocal()),
                    ),
                    _buildDetailRow(
                      'Modal Kas Awal',
                      CurrencyFormatter.format(session.openingCash),
                    ),
                    _buildDetailRow(
                      'Ekspektasi Kas Laci',
                      CurrencyFormatter.format(session.expectedCash),
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Dashboard Integration
              if (_isLoadingDashboard)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_dashboardError != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _dashboardError!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _loadDashboardData(session.outletId),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (d != null) ...[
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
                        value: CurrencyFormatter.format(
                          d.totalSalesThisSession,
                        ),
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pm.method.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${CurrencyFormatter.format(pm.amount)} (${pm.count}x)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
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
                              ),
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
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
                      final formattedTime =
                          '${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}';
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '$formattedTime • ${tx.paymentMethod.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(tx.grandTotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
              ],

              // 3. Tutup Sesi Form
              const Divider(height: 32, color: Colors.white10),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kas aktual wajib diisi';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) < 0) {
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
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text(
                  'Tutup Sesi Kasir',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
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
