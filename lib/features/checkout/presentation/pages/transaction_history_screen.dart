import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_event.dart';
import '../bloc/checkout_state.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _outletId = '';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _outletId = authState.selectedOutletId ?? '';
      if (_outletId.isNotEmpty) {
        context.read<CheckoutBloc>().add(LoadHistory(_outletId));
      }
    }
  }

  Future<void> _openTransactionDetails(
    Map<String, dynamic> trx,
    ThemeData theme,
    String userRole,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detail = await context
          .read<CheckoutBloc>()
          .repository
          .getTransactionById(trx['id'].toString());
      if (!mounted) return;
      Navigator.of(context).pop();
      _showTransactionDetails(detail, theme, userRole);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceAll('Exception: ', '')
                .replaceAll('ServerFailure: ', ''),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showTransactionDetails(
    Map<String, dynamic> trx,
    ThemeData theme,
    String userRole,
  ) {
    final bool isVoided = trx['status']?.toString().toLowerCase() == 'void';
    final items = trx['items'] as List<dynamic>? ?? [];
    final payments = trx['payments'] as List<dynamic>? ?? [];
    final formattedDate = trx['createdAt'] != null
        ? DateFormat(
            'dd MMM yyyy, HH:mm',
          ).format(DateTime.parse(trx['createdAt']).toLocal())
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trx['transactionNumber'] ?? 'Detail Transaksi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isVoided
                            ? Colors.red.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isVoided ? 'VOIDED' : 'PAID',
                        style: TextStyle(
                          color: isVoided
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
                const Divider(height: 24, color: Colors.white10),
                const Text(
                  'Item Pembelian:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Items List
                ...items.map((item) {
                  final qty = (item['qty'] as num?)?.toDouble() ?? 1.0;
                  final price = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
                  final discount =
                      (item['discountAmount'] as num?)?.toDouble() ?? 0.0;
                  final total = (price - discount) * qty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['productName'] ?? 'Item'} (x${qty.toInt()})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(total),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24, color: Colors.white10),
                // Payments Summary
                if (payments.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pembayaran (${payments.first['method']?.toString().toUpperCase()})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(
                          (payments.first['amount'] as num).toDouble(),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Transaksi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(
                        (trx['grandTotal'] as num).toDouble(),
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Void option for authorized roles
                if (!isVoided &&
                    (userRole == 'Owner' || userRole == 'Admin')) ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showVoidConfirmDialog(trx['id']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shadowColor: Colors.redAccent.withOpacity(0.4),
                    ),
                    child: const Text(
                      'Batalkan Transaksi (Void)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVoidConfirmDialog(String transactionId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alasan pembatalan transaksi ini:',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Alasan Void'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<CheckoutBloc>().add(
                  VoidTransactionEvent(
                    transactionId: transactionId,
                    reason: controller.text.trim(),
                    outletId: _outletId,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Void'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    String userRole = '';
    if (authState is Authenticated) {
      userRole = authState.user.role;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Histori Penjualan')),
      body: BlocConsumer<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CheckoutLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryLoaded) {
            final transactions = state.transactions;
            if (transactions.isEmpty) {
              return const Center(
                child: Text('Belum ada transaksi di sesi ini.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trx = transactions[index];
                final String code = trx['transactionNumber'] ?? 'TRX';
                final double total =
                    (trx['grandTotal'] as num?)?.toDouble() ?? 0.0;
                final bool isVoided =
                    trx['status']?.toString().toLowerCase() == 'void';
                final String time = trx['createdAt'] != null
                    ? DateTime.parse(
                        trx['createdAt'],
                      ).toLocal().toString().substring(11, 16)
                    : '';

                return ListTile(
                  onTap: () => _openTransactionDetails(trx, theme, userRole),
                  tileColor: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isVoided
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVoided ? Icons.close : Icons.shopping_bag_outlined,
                      color: isVoided ? Colors.redAccent : Colors.greenAccent,
                    ),
                  ),
                  title: Text(
                    code,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Jam: $time  •  POS Channel',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(total),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isVoided
                              ? Colors.white30
                              : theme.colorScheme.secondary,
                          decoration: isVoided
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isVoided ? 'VOIDED' : 'PAID',
                        style: TextStyle(
                          fontSize: 9,
                          color: isVoided
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
