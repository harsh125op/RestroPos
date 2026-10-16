import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_providers.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';

import 'invoice_preview_screen.dart';
import '../../../../core/widgets/common_widgets.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final String? initialCustomerName;
  const CreateInvoiceScreen({super.key, this.initialCustomerName});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  late final TextEditingController _customerNameController;

  @override
  void initState() {
    super.initState();
    _customerNameController =
        TextEditingController(text: widget.initialCustomerName ?? '');
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }



  void _confirmClearCart() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Order?"),
        content: const Text(
            "Are you sure you want to remove all items from this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All items removed from cart"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              "Clear All",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  double _discount = 0.0;
  bool _hasServiceCharge = false;
  double _serviceCharge = 50.0;

  void _showDiscountDialog(double currentSubTotal) {
    final controller = TextEditingController(
      text: _discount > 0 ? _discount.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.discount_outlined, color: Colors.indigo),
            SizedBox(width: 8),
            Text("Enter Discount", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sub Total: ₹${currentSubTotal.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: false,
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  labelText: "Discount Amount",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text("₹10"),
                    onPressed: () => controller.text = "10",
                  ),
                  ActionChip(
                    label: const Text("₹20"),
                    onPressed: () => controller.text = "20",
                  ),
                  ActionChip(
                    label: const Text("₹50"),
                    onPressed: () => controller.text = "50",
                  ),
                  ActionChip(
                    label: const Text("10%"),
                    onPressed: () {
                      final tenPct = (currentSubTotal * 0.10).roundToDouble();
                      controller.text = tenPct.toStringAsFixed(0);
                    },
                  ),
                  ActionChip(
                    label: const Text("20%"),
                    onPressed: () {
                      final twentyPct = (currentSubTotal * 0.20).roundToDouble();
                      controller.text = twentyPct.toStringAsFixed(0);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (_discount > 0)
            TextButton(
              onPressed: () {
                setState(() => _discount = 0.0);
                Navigator.pop(ctx);
              },
              child: const Text("Remove", style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              setState(() {
                _discount = val.clamp(0.0, currentSubTotal);
              });
              Navigator.pop(ctx);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  void _showServiceChargeDialog(double itemsTotal) {
    final controller = TextEditingController(
      text: _serviceCharge.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.room_service_outlined, color: Colors.indigo),
            SizedBox(width: 8),
            Text("Service Charge", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Set service charge amount for this order:",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: false,
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  labelText: "Service Charge",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text("₹30"),
                    onPressed: () => controller.text = "30",
                  ),
                  ActionChip(
                    label: const Text("₹50"),
                    onPressed: () => controller.text = "50",
                  ),
                  ActionChip(
                    label: const Text("₹100"),
                    onPressed: () => controller.text = "100",
                  ),
                  ActionChip(
                    label: const Text("5%"),
                    onPressed: () {
                      final fivePct = (itemsTotal * 0.05).roundToDouble();
                      controller.text = fivePct.toStringAsFixed(0);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 50.0;
              setState(() {
                _serviceCharge = val > 0 ? val : 0.0;
                _hasServiceCharge = true;
              });
              Navigator.pop(ctx);
            },
            child: const Text("Set"),
          ),
        ],
      ),
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProductPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final itemsTotal = ref.watch(cartProvider.notifier).totalAmount;
    final effectiveServiceCharge = _hasServiceCharge ? _serviceCharge : 0.0;
    final subTotal = itemsTotal + effectiveServiceCharge;
    final finalGrandTotal = (subTotal - _discount).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Order"),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmClearCart,
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Colors.redAccent),
              label: const Text(
                "Clear All",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: "Table / Customer Name (Optional)",
                prefixIcon: Icon(Icons.table_restaurant),
              ),
            ),
          ),
          if (cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order Items (${cartItems.length})",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: _confirmClearCart,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text("Clear All"),
                  ),
                ],
              ),
            ),
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("No items added yet", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("₹${item.product.price} x ${item.quantity}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id!, -1),
                            ),
                            Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id!, 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              children: [
                // Service Charge Toggle & Discount Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Service Charge Switch + Chip
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.room_service_outlined,
                            size: 18,
                            color: _hasServiceCharge ? Colors.indigo : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          const Text("Service Chg", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (_hasServiceCharge) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _showServiceChargeDialog(itemsTotal),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.indigo.shade200),
                                ),
                                child: Text(
                                  "₹${_serviceCharge.toStringAsFixed(0)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo),
                                ),
                              ),
                            ),
                          ],
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: _hasServiceCharge,
                              activeTrackColor: Colors.indigo.shade200,
                              thumbColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.selected) ? Colors.indigo : null,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _hasServiceCharge = val;
                                });
                                if (val && _serviceCharge <= 0) {
                                  _showServiceChargeDialog(itemsTotal);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Discount Button
                    if (_discount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _showDiscountDialog(subTotal),
                              child: Text(
                                "Disc: -₹${_discount.toStringAsFixed(0)}",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade800),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(() => _discount = 0.0),
                              child: const Icon(Icons.close, size: 14, color: Colors.red),
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        icon: const Icon(Icons.discount_outlined, size: 15),
                        label: const Text("Discount", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: Colors.indigo.shade300),
                        ),
                        onPressed: () => _showDiscountDialog(subTotal),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Total Amount Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Total Amount", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          if (_hasServiceCharge || _discount > 0)
                            Text(
                              "Items: ₹${itemsTotal.toStringAsFixed(0)}" +
                              (_hasServiceCharge ? " + S.Chg: ₹${_serviceCharge.toStringAsFixed(0)}" : "") +
                              (_discount > 0 ? " - Disc: ₹${_discount.toStringAsFixed(0)}" : ""),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "₹${finalGrandTotal.toStringAsFixed(2)}", 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showProductPicker,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Food"),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        label: "Generate Bill",
                        onPressed: cartItems.isEmpty ? () {} : () async {
                          try {
                            final invoice = await ref.read(invoiceHistoryProvider.notifier).createInvoice(
                              _customerNameController.text,
                              customTotal: finalGrandTotal,
                            );
                            if (mounted && invoice != null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bill Generated Successfully!")));
                              
                              if (mounted) {
                                await Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InvoicePreviewScreen(
                                      invoice: invoice,
                                      discount: _discount,
                                      serviceCharge: effectiveServiceCharge,
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: Colors.red[700],
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductPickerSheet extends ConsumerStatefulWidget {
  const ProductPickerSheet({super.key});

  @override
  ConsumerState<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<ProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: productsAsync.when(
          data: (products) {
            final rawCategories = products
                .map((p) => p.category.trim())
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            final categories = ['All', ...rawCategories];

            return DefaultTabController(
              length: categories.length,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Food Items",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search food items...",
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    isScrollable: true,
                    labelColor: Colors.indigo,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.indigo,
                    tabs: categories.map((c) => Tab(text: c)).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: categories.map((category) {
                        final categoryProducts = (category == 'All'
                                ? products
                                : products.where((p) => p.category == category).toList())
                            .where((p) {
                              if (_searchQuery.isEmpty) return true;
                              return p.name.toLowerCase().contains(_searchQuery) ||
                                  p.category.toLowerCase().contains(_searchQuery);
                            })
                            .toList();

                        if (categoryProducts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.restaurant_menu
                                      : Icons.search_off_rounded,
                                  size: 48,
                                  color: Colors.grey[350],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? "No items in this category"
                                      : "No food items match '$_searchQuery'",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: categoryProducts.length,
                          itemBuilder: (context, index) {
                            final p = categoryProducts[index];
                            final cartItem = ref
                                .watch(cartProvider)
                                .where((item) => item.product.id == p.id)
                                .firstOrNull;
                            final currentQty = cartItem?.quantity ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Colors.grey.withOpacity(0.15)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                title: Text(p.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text("₹${p.price}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.black87)),
                                ),
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (currentQty > 0) ...[
                                        IconButton(
                                          padding: const EdgeInsets.all(4),
                                          constraints:
                                              const BoxConstraints(),
                                          icon: const Icon(Icons.remove,
                                              size: 20, color: Colors.red),
                                          onPressed: () => ref
                                              .read(cartProvider.notifier)
                                              .updateQuantity(p.id!, -1),
                                        ),
                                        Text("$currentQty",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ],
                                      IconButton(
                                        padding: const EdgeInsets.all(4),
                                        constraints:
                                            const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.add,
                                          size: 20,
                                          color: Colors.indigo,
                                        ),
                                        onPressed: () {
                                          if (currentQty == 0) {
                                            ref
                                                .read(cartProvider.notifier)
                                                .addToCart(p);
                                          } else {
                                            ref
                                                .read(cartProvider.notifier)
                                                .updateQuantity(p.id!, 1);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: CustomButton(
                      label: "Done",
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text("Error: $err")),
        ),
      ),
    );
  }
}
