import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../../core/constants/capability_codes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/domain/access_policy.dart';
import '../../../cashier_session/presentation/bloc/cashier_session_bloc.dart';
import '../../../cashier_session/presentation/bloc/cashier_session_state.dart';
import '../../../cashier_session/presentation/pages/cashier_session_screen.dart';
import '../bloc/products_bloc.dart';
import '../bloc/products_event.dart';
import '../bloc/products_state.dart';
import '../../../../core/network/realtime_service.dart';
import '../../../checkout/presentation/bloc/cart_bloc.dart';
import '../../../checkout/presentation/bloc/cart_event.dart';
import '../../../checkout/presentation/bloc/cart_state.dart';
import '../../../checkout/presentation/pages/checkout_screen.dart';
import '../../../checkout/presentation/pages/transaction_history_screen.dart';
import '../../../checkout/presentation/pages/settings_screen.dart';
import '../../../capabilities/presentation/bloc/capability_bloc.dart';
import '../../../capabilities/presentation/widgets/capability_gate.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';
import '../../../inventory_transfer/presentation/pages/stock_transfer_screen.dart';

class PosScreen extends StatefulWidget {
  final StorageService storageService;

  const PosScreen({super.key, required this.storageService});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initRealtimeConnection();
  }

  void _initRealtimeConnection() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final outletId = authState.selectedOutletId ?? '';
      if (outletId.isNotEmpty) {
        final realtimeService = RepositoryProvider.of<RealtimeService>(context);
        realtimeService.onStockUpdate = (eventOutletId, updates) {
          if (eventOutletId == outletId) {
            context.read<ProductsBloc>().add(ReloadProductsSilently(outletId));
          }
        };
        // After automatic SignalR reconnect, reload products to catch any missed updates
        realtimeService.onReconnected = () {
          context.read<ProductsBloc>().add(ReloadProductsSilently(outletId));
        };
        realtimeService.connect(outletId).catchError((e) {
          debugPrint('RealtimeService connection error: $e');
        });
      }
    }
  }

  void _loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final outletId = authState.selectedOutletId ?? '';
      if (outletId.isNotEmpty) {
        context.read<ProductsBloc>().add(LoadProducts(outletId));
        context.read<CashierSessionBloc>().add(CheckActiveSession(outletId));
      }
    }
  }

  Future<Map<String, double>?> _selectBatchAllocations(
    ProductEntity product,
    ProductTrackingOptions options,
  ) async {
    final controller = TextEditingController(text: '1');
    final existing = context
        .read<CartBloc>()
        .state
        .items
        .where((item) => item.productId == product.id)
        .fold<Map<String, double>>({}, (value, item) => item.batchAllocations);
    String? validationError;
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah batch (FEFO)'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    errorText: validationError,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dialokasikan otomatis dari kedaluwarsa terdekat:',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 6),
                ...options.batches
                    .take(5)
                    .map(
                      (batch) => Text(
                        '${batch.batchNumber} • tersedia ${(batch.qtyRemaining - (existing[batch.id] ?? 0)).clamp(0, double.infinity)}${batch.expiryDate == null ? '' : ' • exp ${batch.expiryDate!.split('T').first}'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final wanted =
                    double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
                if (wanted <= 0) {
                  setDialogState(
                    () => validationError = 'Qty harus lebih besar dari 0.',
                  );
                  return;
                }
                var remaining = wanted;
                final allocations = <String, double>{};
                for (final batch in options.batches) {
                  final available =
                      batch.qtyRemaining - (existing[batch.id] ?? 0);
                  if (available <= 0) continue;
                  final qty = remaining < available ? remaining : available;
                  allocations[batch.id] = qty;
                  remaining -= qty;
                  if (remaining <= 0.000001) break;
                }
                if (remaining > 0.000001) {
                  setDialogState(
                    () => validationError = 'Stok batch aktif tidak mencukupi.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, allocations);
              },
              child: const Text('Tambahkan'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<List<String>?> _selectSerials(
    ProductEntity product,
    String outletId,
    ProductTrackingOptions options,
  ) async {
    final searchController = TextEditingController();
    final alreadyInCart = context
        .read<CartBloc>()
        .state
        .items
        .where((item) => item.productId == product.id)
        .expand((item) => item.serialIds)
        .toSet();
    final selected = <String>{};
    final serials = <String, ProductSerialOption>{
      for (final serial in options.serials)
        if (!alreadyInCart.contains(serial.id)) serial.id: serial,
    };
    String? validationError;
    var loading = false;

    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pilih serial / IMEI'),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Ketik atau scan serial / IMEI',
                        ),
                        onSubmitted: (_) async {
                          setDialogState(() => loading = true);
                          try {
                            final found = await context
                                .read<ProductsRepository>()
                                .getTrackingOptions(
                                  product.id,
                                  outletId,
                                  search: searchController.text,
                                );
                            setDialogState(() {
                              for (final serial in found.serials) {
                                if (!alreadyInCart.contains(serial.id))
                                  serials[serial.id] = serial;
                              }
                              loading = false;
                            });
                          } catch (_) {
                            setDialogState(() {
                              loading = false;
                              validationError = 'Serial tidak dapat dimuat.';
                            });
                          }
                        },
                      ),
                    ),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
                if (validationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      validationError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${selected.length} serial dipilih'),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: serials.isEmpty
                      ? const Center(
                          child: Text('Serial tersedia tidak ditemukan.'),
                        )
                      : ListView(
                          children: serials.values
                              .map(
                                (serial) => CheckboxListTile(
                                  value: selected.contains(serial.id),
                                  title: Text(serial.serialNumber),
                                  onChanged: (checked) => setDialogState(() {
                                    checked == true
                                        ? selected.add(serial.id)
                                        : selected.remove(serial.id);
                                  }),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, selected.toList()),
              child: const Text('Tambahkan'),
            ),
          ],
        ),
      ),
    );
    searchController.dispose();
    return result;
  }

  Future<void> _addProduct(ProductEntity product) async {
    if (!ProductEntity.validTrackingModes.contains(product.trackingMode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mode tracking produk tidak dikenali. Produk tidak dapat dijual.',
          ),
        ),
      );
      return;
    }
    if (product.trackingMode == 'none' || product.trackingMode == 'quantity') {
      context.read<CartBloc>().add(AddToCart(product));
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated ||
        (authState.selectedOutletId ?? '').isEmpty)
      return;

    try {
      final options = await context
          .read<ProductsRepository>()
          .getTrackingOptions(product.id, authState.selectedOutletId!);
      if (!mounted) return;
      if (options.trackingMode != product.trackingMode) {
        throw Exception('Mode tracking produk berubah. Muat ulang katalog.');
      }

      if (product.trackingMode == 'batch') {
        final allocations = await _selectBatchAllocations(product, options);
        if (allocations != null && mounted) {
          context.read<CartBloc>().add(
            AddToCart(
              product,
              qty: allocations.values.fold(0, (sum, qty) => sum + qty),
              batchAllocations: allocations,
            ),
          );
        }
        return;
      }

      final selected = await _selectSerials(
        product,
        authState.selectedOutletId!,
        options,
      );
      if (selected != null && mounted) {
        context.read<CartBloc>().add(
          AddToCart(
            product,
            qty: selected.length.toDouble(),
            serialIds: selected,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('ServerFailure: ', '')),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    try {
      final realtimeService = RepositoryProvider.of<RealtimeService>(context);
      realtimeService.onStockUpdate = null;
      realtimeService.onReconnected = null;
      realtimeService.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting realtime service: $e');
    }
    super.dispose();
  }

  void _showCartBottomSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: Colors.white10),
              ),
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  if (state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Keranjang belanja kosong',
                            style: TextStyle(color: Colors.white30),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Detail Keranjang',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.read<CartBloc>().add(ClearCart()),
                              child: const Text(
                                'Kosongkan',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: state.items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(color: Colors.white10, height: 24),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${CurrencyFormatter.format(item.unitPrice)} ${item.discountAmount > 0 ? "(-${CurrencyFormatter.format(item.discountAmount)})" : ""}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                      if (item.trackingMode == 'batch' ||
                                          item.trackingMode == 'serial')
                                        Text(
                                          item.trackingMode == 'batch'
                                              ? '${item.batchAllocations.length} batch dipilih'
                                              : '${item.serialIds.length} serial dipilih',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 22,
                                      ),
                                      onPressed:
                                          item.trackingMode == 'batch' ||
                                              item.trackingMode == 'serial'
                                          ? null
                                          : () {
                                              context.read<CartBloc>().add(
                                                UpdateQty(
                                                  item.productId,
                                                  item.qty - 1,
                                                ),
                                              );
                                            },
                                    ),
                                    Text(
                                      '${item.qty.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 22,
                                      ),
                                      onPressed:
                                          item.trackingMode == 'batch' ||
                                              item.trackingMode == 'serial'
                                          ? null
                                          : () {
                                              context.read<CartBloc>().add(
                                                UpdateQty(
                                                  item.productId,
                                                  item.qty + 1,
                                                ),
                                              );
                                            },
                                    ),
                                    const SizedBox(width: 8),
                                    // Discount Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.discount_outlined,
                                        size: 20,
                                        color: Colors.amber,
                                      ),
                                      onPressed: () =>
                                          _showItemDiscountDialog(item),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      CurrencyFormatter.format(item.lineTotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: const Border(
                            top: BorderSide(color: Colors.white10),
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal'),
                                  Text(
                                    CurrencyFormatter.format(state.subtotal),
                                  ),
                                ],
                              ),
                              if (state.discountTotal > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Diskon',
                                      style: TextStyle(color: Colors.amber),
                                    ),
                                    Text(
                                      '- ${CurrencyFormatter.format(state.discountTotal)}',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Bayar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(state.grandTotal),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CapabilityGate(
                                            requiredCapabilities: [
                                              CapabilityCodes.salesPos,
                                              CapabilityCodes.catalogProducts,
                                            ],
                                            child: CheckoutScreen(),
                                          ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Lanjut Pembayaran',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showItemDiscountDialog(item) {
    final controller = TextEditingController(
      text: item.discountAmount.toInt().toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Diskon Item: ${item.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nominal diskon (Rupiah) per unit:',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                labelText: 'Nominal Diskon',
              ),
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
              final double discount = double.tryParse(controller.text) ?? 0.0;
              context.read<CartBloc>().add(
                UpdateDiscount(item.productId, discount),
              );
              Navigator.pop(context);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final capabilityState = context.watch<CapabilityBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final canViewTransactions =
        user != null &&
        canReadTransactions(user) &&
        capabilityState is CapabilityLoaded &&
        capabilityState.has(CapabilityCodes.salesTransactions);
    final canUsePos =
        user != null &&
        canCreateTransactions(user) &&
        capabilityState is CapabilityLoaded &&
        capabilityState.has(CapabilityCodes.salesPos);
    final canManageTransfers =
        user != null &&
        canManageStock(user) &&
        capabilityState is CapabilityLoaded &&
        capabilityState.has(CapabilityCodes.inventoryTransfer);
    String name = 'Kasir';
    String role = 'Kasir';
    if (authState is Authenticated) {
      name = authState.user.name;
      role = authState.user.role;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('MorrusPOS POS', style: TextStyle(fontSize: 16)),
            Text(
              '$name ($role)',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SettingsScreen(storageService: widget.storageService),
              ),
            );
            if (context.mounted) {
              context.read<CapabilityBloc>().add(const CapabilitiesStale());
            }
          },
        ),
        actions: [
          if (canManageTransfers)
            IconButton(
              tooltip: 'Transfer stok',
              icon: const Icon(Icons.local_shipping_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CapabilityGate(
                    requiredCapabilities: const [
                      CapabilityCodes.inventoryTransfer,
                    ],
                    child: StockTransferScreen(
                      initialLocationId: authState is Authenticated
                          ? authState.selectedOutletId
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          if (canViewTransactions)
            IconButton(
              tooltip: 'Riwayat transaksi',
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CapabilityGate(
                      requiredCapabilities: [CapabilityCodes.salesTransactions],
                      child: TransactionHistoryScreen(),
                    ),
                  ),
                );
              },
            ),
          if (canUsePos)
            IconButton(
              tooltip: 'Sesi kasir',
              icon: const Icon(Icons.point_of_sale_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CapabilityGate(
                      requiredCapabilities: [CapabilityCodes.salesPos],
                      child: CashierSessionScreen(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: BlocBuilder<CashierSessionBloc, CashierSessionState>(
        builder: (context, sessionState) {
          if (sessionState is! ActiveSessionOpen) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 72,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sesi Kasir Belum Dibuka',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Anda harus membuka sesi kasir dan mengatur modal awal terlebih dahulu untuk melakukan penjualan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CapabilityGate(
                              requiredCapabilities: [CapabilityCodes.salesPos],
                              child: CashierSessionScreen(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 52),
                      ),
                      child: const Text('Buka Sesi Sekarang'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Search and Category Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari produk berdasarkan Nama / SKU...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ProductsBloc>().add(
                                const SearchProducts(''),
                              );
                            },
                          )
                        : null,
                  ),
                  onChanged: (query) {
                    context.read<ProductsBloc>().add(SearchProducts(query));
                  },
                ),
              ),
              // Category Badges
              BlocBuilder<ProductsBloc, ProductsState>(
                builder: (context, state) {
                  if (state.categories.isEmpty) return const SizedBox.shrink();
                  return Container(
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.categories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final categoryId = isAll
                            ? null
                            : state.categories[index - 1];
                        final categoryName = isAll
                            ? 'Semua'
                            : (state.categoryIdToName[categoryId] ??
                                  'Kategori');
                        final isSelected = isAll
                            ? state.selectedCategoryId == null
                            : state.selectedCategoryId == categoryId;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(categoryName),
                            selected: isSelected,
                            onSelected: (selected) {
                              context.read<ProductsBloc>().add(
                                FilterCategorySelected(categoryId),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              Expanded(
                child: BlocBuilder<ProductsBloc, ProductsState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.errorMessage != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.errorMessage!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadInitialData,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state.filteredProducts.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada produk ditemukan.'),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: state.filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = state.filteredProducts[index];
                        final validTracking = ProductEntity.validTrackingModes
                            .contains(product.trackingMode);
                        final hasStock =
                            validTracking &&
                            (product.trackingMode == 'none' ||
                                product.qtyOnHand > 0);

                        return Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product network image loader with gradient fallback placeholder
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child:
                                      product.imageUrl != null &&
                                          product.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          '${widget.storageService.baseUrl}${product.imageUrl}',
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  decoration:
                                                      const BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFF3F4C6B,
                                                                ),
                                                                Color(
                                                                  0xFF606C88,
                                                                ),
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ),
                                                      ),
                                                  child: Center(
                                                    child: Text(
                                                      product.name.isNotEmpty
                                                          ? product.name
                                                                .substring(0, 1)
                                                                .toUpperCase()
                                                          : 'P',
                                                      style: const TextStyle(
                                                        fontSize: 32,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white30,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return const Center(
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                );
                                              },
                                        )
                                      : Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF3F4C6B),
                                                Color(0xFF606C88),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              product.name.isNotEmpty
                                                  ? product.name
                                                        .substring(0, 1)
                                                        .toUpperCase()
                                                  : 'P',
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white30,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SKU: ${product.sku}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white30,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            CurrencyFormatter.format(
                                              product.basePrice,
                                            ),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.secondary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: hasStock
                                                ? Colors.white10
                                                : Colors.red.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            !validTracking
                                                ? 'Mode invalid'
                                                : product.trackingMode == 'none'
                                                ? 'Tanpa stok'
                                                : hasStock
                                                ? 'Stok: ${product.qtyOnHand.toInt()}'
                                                : 'Habis',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: hasStock
                                                  ? Colors.white70
                                                  : Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: hasStock
                                          ? () => _addProduct(product)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          36,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Tambah',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Cart Summary Bar
              BlocBuilder<CartBloc, CartState>(
                builder: (context, cartState) {
                  if (cartState.items.isEmpty) return const SizedBox.shrink();
                  return InkWell(
                    onTap: () => _showCartBottomSheet(theme),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${cartState.totalItemsCount} Item',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      'Lihat Keranjang',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  CurrencyFormatter.format(
                                    cartState.grandTotal,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.keyboard_arrow_up,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
