import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/checkout_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cashier_session/presentation/bloc/cashier_session_bloc.dart';
import 'success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'cash';
  final _amountPaidController = TextEditingController();
  final _referenceController = TextEditingController();
  final _voucherController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPreviewLoading = false;
  String? _previewError;
  Map<String, dynamic>? _preview;

  @override
  void initState() {
    super.initState();
    _refreshPreview();
  }

  @override
  void dispose() {
    _amountPaidController.dispose();
    _referenceController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  double get _change {
    final paid = double.tryParse(_amountPaidController.text) ?? 0.0;
    final total = ((_preview?['grandTotal'] as num?)?.toDouble()) ?? context.read<CartBloc>().state.grandTotal;
    final value = paid - total;
    return value < 0 ? 0.0 : value;
  }

  void _setAmountPaid(double val) {
    setState(() {
      _amountPaidController.text = val.toInt().toString();
    });
  }

  Future<void> _refreshPreview() async {
    final cartState = context.read<CartBloc>().state;
    final authState = context.read<AuthBloc>().state;
    String outletId = '';
    if (authState is Authenticated) {
      outletId = authState.selectedOutletId ?? '';
    }
    if (outletId.isEmpty || cartState.items.isEmpty) {
      return;
    }

    setState(() {
      _isPreviewLoading = true;
      _previewError = null;
    });

    try {
      final itemsPayload = cartState.items.map((item) => {
        'productId': item.productId,
        'qty': item.qty,
        'unitPrice': item.unitPrice,
        'discountAmount': item.discountAmount,
      }).toList();
      final result = await context.read<CheckoutBloc>().repository.previewPricing(
        outletId: outletId,
        items: itemsPayload,
        voucherCode: _voucherController.text.trim().isEmpty ? null : _voucherController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _preview = result;
        _amountPaidController.text = (((result['grandTotal'] as num?)?.toDouble()) ?? cartState.grandTotal).toInt().toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e.toString().replaceAll('Exception: ', '').replaceAll('ServerFailure: ', '');
        _preview = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final cartState = context.read<CartBloc>().state;
      final authState = context.read<AuthBloc>().state;
      final sessionState = context.read<CashierSessionBloc>().state;

      String outletId = '';
      if (authState is Authenticated) {
        outletId = authState.selectedOutletId ?? '';
      }

      String sessionId = '';
      if (sessionState is ActiveSessionOpen) {
        sessionId = sessionState.session.id;
      }

      final amount = double.tryParse(_amountPaidController.text) ?? cartState.grandTotal;
      final grandTotal = ((_preview?['grandTotal'] as num?)?.toDouble()) ?? cartState.grandTotal;

      if (_selectedPaymentMethod == 'cash' && amount < grandTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uang yang dibayarkan kurang!'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }

      context.read<CheckoutBloc>().add(SubmitCheckout(
            items: cartState.items,
            paymentMethod: _selectedPaymentMethod,
            paymentAmount: _selectedPaymentMethod == 'cash' ? grandTotal : amount,
            referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
            voucherCode: _voucherController.text.trim().isEmpty ? null : _voucherController.text.trim(),
            outletId: outletId,
            cashierSessionId: sessionId,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartState = context.watch<CartBloc>().state;
    final subtotal = ((_preview?['subtotal'] as num?)?.toDouble()) ?? cartState.subtotal;
    final manualDiscount = ((_preview?['manualDiscountTotal'] as num?)?.toDouble()) ?? cartState.discountTotal;
    final promoDiscount = ((_preview?['promoDiscountTotal'] as num?)?.toDouble()) ?? 0.0;
    final voucherDiscount = ((_preview?['voucherDiscountTotal'] as num?)?.toDouble()) ?? 0.0;
    final serviceChargeTotal = ((_preview?['serviceChargeTotal'] as num?)?.toDouble()) ?? 0.0;
    final taxTotal = ((_preview?['taxTotal'] as num?)?.toDouble()) ?? 0.0;
    final grandTotal = ((_preview?['grandTotal'] as num?)?.toDouble()) ?? cartState.grandTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Penjualan')),
      body: BlocListener<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutSuccess) {
            context.read<CartBloc>().add(ClearCart());
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SuccessScreen(transaction: state.transaction)),
            );
          } else if (state is CheckoutFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ringkasan Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(height: 24, color: Colors.white10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text(CurrencyFormatter.format(subtotal)),
                        ],
                      ),
                      if (manualDiscount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Diskon Item'),
                            Text('- ${CurrencyFormatter.format(manualDiscount)}', style: const TextStyle(color: Colors.amber)),
                          ],
                        ),
                      ],
                      if (promoDiscount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Promo'),
                            Text('- ${CurrencyFormatter.format(promoDiscount)}', style: const TextStyle(color: Colors.lightBlueAccent)),
                          ],
                        ),
                      ],
                      if (voucherDiscount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Voucher'),
                            Text('- ${CurrencyFormatter.format(voucherDiscount)}', style: const TextStyle(color: Colors.greenAccent)),
                          ],
                        ),
                      ],
                      if (serviceChargeTotal > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Service Charge'),
                            Text(CurrencyFormatter.format(serviceChargeTotal)),
                          ],
                        ),
                      ],
                      if (taxTotal > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pajak'),
                            Text(CurrencyFormatter.format(taxTotal)),
                          ],
                        ),
                      ],
                      const Divider(height: 24, color: Colors.white10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total yang Harus Dibayar', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            CurrencyFormatter.format(grandTotal),
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _voucherController,
                        decoration: const InputDecoration(
                          labelText: 'Kode Voucher',
                          prefixIcon: Icon(Icons.local_offer_outlined),
                        ),
                        onChanged: (_) {
                          _refreshPreview();
                        },
                      ),
                      if (_isPreviewLoading) ...[
                        const SizedBox(height: 8),
                        const Text('Menghitung pricing terbaru...', style: TextStyle(fontSize: 12, color: Colors.white60)),
                      ],
                      if (_previewError != null) ...[
                        const SizedBox(height: 8),
                        Text(_previewError!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                // Payment Method Selector
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildPaymentMethodCard('cash', 'Tunai / Cash', Icons.payments_outlined, theme),
                    _buildPaymentMethodCard('qris', 'QRIS', Icons.qr_code_scanner_outlined, theme),
                    _buildPaymentMethodCard('edc', 'Kartu Debit / EDC', Icons.credit_card_outlined, theme),
                    _buildPaymentMethodCard('transfer', 'Transfer Bank', Icons.account_balance_outlined, theme),
                  ],
                ),
                const SizedBox(height: 28),
                if (_selectedPaymentMethod == 'cash') ...[
                  // Cash inputs
                  const Text('Uang Diterima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountPaidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      labelText: 'Nominal Pembayaran',
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Masukkan jumlah uang diterima';
                      if (double.tryParse(val) == null) return 'Uang tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Quick Cash Shortcuts
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickCashButton('Uang Pas', grandTotal),
                      _buildQuickCashButton('Rp 50.000', 50000),
                      _buildQuickCashButton('Rp 100.000', 100000),
                      _buildQuickCashButton('Rp 200.000', 200000),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Change Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          CurrencyFormatter.format(_change),
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Non-cash reference inputs
                  const Text('Nomor Referensi Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Kode Ref / ID Transaksi',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                      hintText: 'Misal: REF-QRIS-100293',
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                BlocBuilder<CheckoutBloc, CheckoutState>(
                  builder: (context, state) {
                    final isLoading = state is CheckoutLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Proses Checkout & Cetak Struk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String key, String title, IconData icon, ThemeData theme) {
    final isSelected = _selectedPaymentMethod == key;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = key;
          if (key != 'cash') {
            _amountPaidController.text = context.read<CartBloc>().state.grandTotal.toInt().toString();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.12) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.white60, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCashButton(String text, double value) {
    return ActionChip(
      label: Text(text),
      onPressed: () => _setAmountPaid(value),
      backgroundColor: Colors.white10,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
    );
  }
}
