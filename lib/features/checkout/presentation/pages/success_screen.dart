import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

class SuccessScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const SuccessScreen({super.key, required this.transaction});

  void _simulatePrint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Menghubungkan ke printer & mencetak struk...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String trxNum = transaction['transactionNumber'] ?? '';
    final double subtotal = (transaction['subtotal'] as num?)?.toDouble() ?? 0.0;
    final double discount = (transaction['discountTotal'] as num?)?.toDouble() ?? 0.0;
    final double grandTotal = (transaction['grandTotal'] as num?)?.toDouble() ?? 0.0;
    final String dateStr = transaction['createdAt'] != null
        ? DateTime.parse(transaction['createdAt']).toLocal().toString().substring(0, 16)
        : '';
    final List<dynamic> items = transaction['items'] ?? [];
    final List<dynamic> payments = transaction['payments'] ?? [];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: const Icon(Icons.check, size: 48, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Transaksi Berhasil!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent),
              ),
              const SizedBox(height: 8),
              Text(
                'No. Transaksi: $trxNum',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 32),
              // Thermal Receipt Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.black87, fontFamily: 'monospace', fontSize: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'MORRUS POS TENT',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        ),
                      ),
                      const Center(
                        child: Text('Kwitansi Pembelian Resmi'),
                      ),
                      const Center(
                        child: Text('--------------------------------'),
                      ),
                      Text('Tanggal: $dateStr'),
                      Text('Nomor  : $trxNum'),
                      Text('Kasir  : ${transaction['userName'] ?? 'Kasir'}'),
                      const Text('--------------------------------'),
                      // Receipt Items
                      ...items.map((item) {
                        final String name = item['productName'] ?? 'Item';
                        final double qty = (item['qty'] as num?)?.toDouble() ?? 1.0;
                        final double price = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
                        final double lineDisc = (item['discountAmount'] as num?)?.toDouble() ?? 0.0;
                        final double lineTotal = (price - lineDisc) * qty;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${qty.toInt()} x ${CurrencyFormatter.format(price).replaceAll('Rp ', '')}'),
                                  Text(CurrencyFormatter.format(lineTotal).replaceAll('Rp ', '')),
                                ],
                              ),
                              if (lineDisc > 0)
                                Text(
                                  '  Diskon: -${CurrencyFormatter.format(lineDisc * qty).replaceAll('Rp ', '')}',
                                  style: const TextStyle(color: Colors.red, fontSize: 11),
                                ),
                            ],
                          ),
                        );
                      }),
                      const Text('--------------------------------'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text(CurrencyFormatter.format(subtotal).replaceAll('Rp ', '')),
                        ],
                      ),
                      if (discount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Diskon'),
                            Text('-${CurrencyFormatter.format(discount).replaceAll('Rp ', '')}'),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          Text(
                            CurrencyFormatter.format(grandTotal).replaceAll('Rp ', ''),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                          ),
                        ],
                      ),
                      const Text('--------------------------------'),
                      // Payments
                      ...payments.map((p) {
                        final String method = p['method'] ?? 'cash';
                        final double amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Bayar (${method.toUpperCase()})'),
                            Text(CurrencyFormatter.format(amt).replaceAll('Rp ', '')),
                          ],
                        );
                      }),
                      if (payments.isNotEmpty && payments.first['method'] == 'cash')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kembalian'),
                            Text(CurrencyFormatter.format(payments.first['amount'] - grandTotal).replaceAll('Rp ', '')),
                          ],
                        ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'TERIMA KASIH ATAS KUNJUNGANNYA',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Buttons
              ElevatedButton.icon(
                onPressed: () => _simulatePrint(context),
                icon: const Icon(Icons.print),
                label: const Text('Cetak Struk', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Transaksi Baru', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
