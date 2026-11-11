import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/stock_transfer_repository.dart';
import '../../domain/entities/stock_transfer_entity.dart';

String _requestId() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final h = bytes.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class StockTransferScreen extends StatefulWidget {
  final String? initialLocationId;
  const StockTransferScreen({super.key, this.initialLocationId});
  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  List<StockLocationEntity> locations = [];
  List<StockTransferEntity> outgoing = [];
  List<StockTransferEntity> incoming = [];
  String? locationId;
  bool loading = true;
  String? error;
  StockTransferRepository get repository =>
      context.read<StockTransferRepository>();

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      locations = await repository.getLocations();
      locationId =
          locations.any((x) => x.id == (locationId ?? widget.initialLocationId))
          ? (locationId ?? widget.initialLocationId)
          : (locations.isEmpty ? null : locations.first.id);
      if (locationId != null) {
        final results = await Future.wait([
          repository.getTransfers(locationId!, incoming: false),
          repository.getTransfers(locationId!, incoming: true),
        ]);
        outgoing = results[0];
        incoming = results[1];
      }
    } catch (e) {
      error = repository.message(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> openSend() async {
    if (locationId == null) return;
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => RepositoryProvider.value(
        value: repository,
        child: _SendTransferDialog(sourceId: locationId!, locations: locations),
      ),
    );
    if (sent == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer berhasil dikirim.')),
        );
      }
      await load();
    }
  }

  Future<void> openReceive(StockTransferEntity transfer) async {
    final received = await showDialog<bool>(
      context: context,
      builder: (_) => RepositoryProvider.value(
        value: repository,
        child: _ReceiveTransferDialog(transfer: transfer),
      ),
    );
    if (received == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penerimaan transfer berhasil disimpan.'),
          ),
        );
      }
      await load();
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Stok'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Keluar'),
            Tab(text: 'Masuk'),
          ],
        ),
      ),
      floatingActionButton: locationId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: openSend,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Kirim'),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: locationId,
              decoration: const InputDecoration(
                labelText: 'Lokasi stok aktif',
                border: OutlineInputBorder(),
              ),
              items: locations
                  .map(
                    (x) => DropdownMenuItem(
                      value: x.id,
                      child: Text(
                        '${x.name} · ${x.type == 'warehouse' ? 'Gudang' : 'Outlet'}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                locationId = value;
                load();
              },
            ),
          ),
          if (error != null)
            MaterialBanner(
              content: Text(error!),
              actions: [
                TextButton(onPressed: load, child: const Text('Coba lagi')),
              ],
            ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _TransferList(
                        items: outgoing,
                        incoming: false,
                        onReceive: openReceive,
                        onRefresh: load,
                      ),
                      _TransferList(
                        items: incoming,
                        incoming: true,
                        onReceive: openReceive,
                        onRefresh: load,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class _TransferList extends StatelessWidget {
  final List<StockTransferEntity> items;
  final bool incoming;
  final ValueChanged<StockTransferEntity> onReceive;
  final Future<void> Function() onRefresh;
  const _TransferList({
    required this.items,
    required this.incoming,
    required this.onReceive,
    required this.onRefresh,
  });
  String label(String value) => switch (value) {
    'in_transit' || 'pending' => 'Dalam perjalanan',
    'received' || 'approved' => 'Diterima',
    'received_with_variance' => 'Diterima dengan selisih',
    'returned' || 'rejected' => 'Dikembalikan',
    _ => value,
  };
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Center(child: Text('Belum ada transfer.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(
                incoming
                    ? Icons.move_to_inbox_outlined
                    : Icons.local_shipping_outlined,
              ),
              title: Text(item.transferNumber),
              subtitle: Text(
                '${incoming ? item.fromLocationName : item.toLocationName}\n${label(item.status)} · ${item.items.length} item',
              ),
              isThreeLine: true,
              trailing: incoming && item.canReceive
                  ? FilledButton(
                      onPressed: () => onReceive(item),
                      child: const Text('Terima'),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: incoming && item.canReceive ? () => onReceive(item) : null,
            ),
          );
        },
      ),
    );
  }
}

class _SendTransferDialog extends StatefulWidget {
  final String sourceId;
  final List<StockLocationEntity> locations;
  const _SendTransferDialog({required this.sourceId, required this.locations});
  @override
  State<_SendTransferDialog> createState() => _SendTransferDialogState();
}

class _SendTransferDialogState extends State<_SendTransferDialog> {
  List<TransferInventoryItem> inventory = [];
  TransferInventoryItem? product;
  Map<String, dynamic>? tracking;
  String? destinationId;
  String? batchId;
  final serialIds = <String>{};
  final qty = TextEditingController();
  bool loading = true, saving = false;
  String? error;
  String requestId = _requestId();
  StockTransferRepository get repository =>
      context.read<StockTransferRepository>();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      inventory = await repository.getInventory(widget.sourceId);
    } catch (e) {
      error = repository.message(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> selectProduct(TransferInventoryItem? value) async {
    setState(() {
      product = value;
      tracking = null;
      batchId = null;
      serialIds.clear();
      qty.clear();
    });
    if (value != null && value.trackingMode != 'quantity') {
      try {
        final result = await repository.getTracking(value, widget.sourceId);
        if (mounted) setState(() => tracking = result);
      } catch (e) {
        if (mounted) setState(() => error = repository.message(e));
      }
    }
  }

  Future<void> send() async {
    final amount = product?.trackingMode == 'serial'
        ? serialIds.length.toDouble()
        : double.tryParse(qty.text);
    if (destinationId == null ||
        product == null ||
        amount == null ||
        amount <= 0) {
      setState(() => error = 'Lengkapi tujuan, produk, dan qty.');
      return;
    }
    if (amount > product!.qty) {
      setState(() => error = 'Qty melebihi stok tersedia.');
      return;
    }
    if (product!.trackingMode == 'batch' && batchId == null) {
      setState(() => error = 'Pilih batch yang dikirim.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await repository.send({
        'requestId': requestId,
        'fromStockLocationId': widget.sourceId,
        'toStockLocationId': destinationId,
        'items': [
          {
            'productId': product!.productId,
            'productVariantId': product!.productVariantId,
            'qty': amount,
            'productBatchId': batchId,
            'productSerialIds': serialIds.isEmpty ? null : serialIds.toList(),
          },
        ],
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = repository.message(e);
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Kirim transfer stok'),
    content: SizedBox(
      width: 500,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    initialValue: destinationId,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi tujuan',
                    ),
                    items: widget.locations
                        .where((x) => x.id != widget.sourceId)
                        .map(
                          (x) => DropdownMenuItem(
                            value: x.id,
                            child: Text(x.name),
                          ),
                        )
                        .toList(),
                    onChanged: (x) => setState(() => destinationId = x),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TransferInventoryItem>(
                    initialValue: product,
                    decoration: const InputDecoration(labelText: 'Produk'),
                    items: inventory
                        .map(
                          (x) => DropdownMenuItem(
                            value: x,
                            child: Text('${x.name} (${x.sku}) · ${x.qty}'),
                          ),
                        )
                        .toList(),
                    onChanged: selectProduct,
                  ),
                  if (product?.trackingMode == 'batch') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: batchId,
                      decoration: const InputDecoration(labelText: 'Batch'),
                      items: ((tracking?['batches'] as List?) ?? const []).map((
                        x,
                      ) {
                        final j = x as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: j['id'].toString(),
                          child: Text(
                            '${j['batchNumber']} · ${j['qtyRemaining']}',
                          ),
                        );
                      }).toList(),
                      onChanged: (x) => setState(() => batchId = x),
                    ),
                  ],
                  if (product?.trackingMode == 'serial') ...[
                    const SizedBox(height: 12),
                    ...((tracking?['serials'] as List?) ?? const []).map((x) {
                      final j = x as Map<String, dynamic>;
                      final id = j['id'].toString();
                      return CheckboxListTile(
                        value: serialIds.contains(id),
                        title: Text(j['serialNumber'].toString()),
                        onChanged: (v) => setState(
                          () => v == true
                              ? serialIds.add(id)
                              : serialIds.remove(id),
                        ),
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: qty,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Qty'),
                    ),
                  ],
                ],
              ),
            ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: saving ? null : send,
        child: Text(saving ? 'Mengirim...' : 'Kirim'),
      ),
    ],
  );
}

class _ReceiveTransferDialog extends StatefulWidget {
  final StockTransferEntity transfer;
  const _ReceiveTransferDialog({required this.transfer});
  @override
  State<_ReceiveTransferDialog> createState() => _ReceiveTransferDialogState();
}

class _ReceiveTransferDialogState extends State<_ReceiveTransferDialog> {
  late final Map<String, TextEditingController> quantities;
  final reasons = <String, String>{};
  final notes = <String, TextEditingController>{};
  bool saving = false;
  String? error;
  final requestId = _requestId();
  @override
  void initState() {
    super.initState();
    quantities = {
      for (final x in widget.transfer.items)
        x.id: TextEditingController(text: x.sentQty.toString()),
    };
    notes.addAll({
      for (final x in widget.transfer.items) x.id: TextEditingController(),
    });
  }

  @override
  void dispose() {
    for (final x in quantities.values) {
      x.dispose();
    }
    for (final x in notes.values) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> receive() async {
    final payloadItems = <Map<String, dynamic>>[];
    for (final item in widget.transfer.items) {
      final received = double.tryParse(quantities[item.id]!.text);
      if (received == null ||
          received < 0 ||
          (item.productSerialId != null && received != 0 && received != 1)) {
        setState(() => error = 'Qty diterima tidak valid.');
        return;
      }
      final difference = received - item.sentQty;
      if (difference != 0 &&
          ((reasons[item.id] ?? '').isEmpty ||
              notes[item.id]!.text.trim().isEmpty)) {
        setState(() => error = 'Alasan dan catatan selisih wajib diisi.');
        return;
      }
      payloadItems.add({
        'transferItemId': item.id,
        'receivedQty': received,
        'varianceReasonCode': difference == 0 ? null : reasons[item.id],
        'varianceNote': difference == 0 ? null : notes[item.id]!.text.trim(),
      });
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await context.read<StockTransferRepository>().receive(
        widget.transfer.id,
        {'requestId': requestId, 'receiptNote': null, 'items': payloadItems},
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = context.read<StockTransferRepository>().message(e);
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Terima ${widget.transfer.transferNumber}'),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ...widget.transfer.items.map((item) {
              final received =
                  double.tryParse(quantities[item.id]!.text) ?? item.sentQty;
              final difference = received - item.sentQty;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.productName} (${item.sku})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Dikirim: ${item.sentQty}${item.serialNumber != null ? ' · ${item.serialNumber}' : ''}',
                      ),
                      TextField(
                        controller: quantities[item.id],
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Qty diterima',
                        ),
                      ),
                      if (difference != 0) ...[
                        DropdownButtonFormField<String>(
                          initialValue: reasons[item.id],
                          decoration: const InputDecoration(
                            labelText: 'Alasan selisih',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'short_shipped',
                              child: Text('Dikirim kurang'),
                            ),
                            DropdownMenuItem(
                              value: 'lost_in_transit',
                              child: Text('Hilang di perjalanan'),
                            ),
                            DropdownMenuItem(
                              value: 'damaged',
                              child: Text('Rusak'),
                            ),
                            DropdownMenuItem(
                              value: 'over_shipped',
                              child: Text('Dikirim lebih'),
                            ),
                            DropdownMenuItem(
                              value: 'counting_error',
                              child: Text('Perbedaan hitung'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('Lainnya'),
                            ),
                          ],
                          onChanged: (x) =>
                              setState(() => reasons[item.id] = x!),
                        ),
                        TextField(
                          controller: notes[item.id],
                          decoration: const InputDecoration(
                            labelText: 'Catatan selisih',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: saving ? null : receive,
        child: Text(saving ? 'Memproses...' : 'Selesaikan'),
      ),
    ],
  );
}
