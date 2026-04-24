import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_providers.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';

import 'invoice_preview_screen.dart';
import '../../../../core/widgets/common_widgets.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _customerNameController = TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
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
    final totalAmount = ref.watch(cartProvider.notifier).totalAmount;

    return Scaffold(
      appBar: AppBar(title: const Text("New Order")),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("₹${totalAmount.toStringAsFixed(2)}", 
                         style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showProductPicker,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Food"),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        label: "Generate Bill",
                        onPressed: cartItems.isEmpty ? () {} : () async {
                          try {
                            final invoice = await ref.read(invoiceHistoryProvider.notifier).createInvoice(_customerNameController.text);
                            if (mounted && invoice != null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bill Generated Successfully!")));
                              
                              await Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvoicePreviewScreen(invoice: invoice),
                                ),
                              );
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

class ProductPickerSheet extends ConsumerWidget {
  const ProductPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final categories = ['Sweets', 'Chaat', 'Juice', 'Coffee'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DefaultTabController(
        length: categories.length,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("Select Food Items", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            TabBar(
              isScrollable: true,
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              tabs: categories.map((c) => Tab(text: c)).toList(),
            ),
            Expanded(
              child: productsAsync.when(
                data: (products) => TabBarView(
                  children: categories.map((category) {
                    final categoryProducts = products.where((p) => p.category == category).toList();
                    if (categoryProducts.isEmpty) {
                      return const Center(child: Text("No items in this category"));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: categoryProducts.length,
                      itemBuilder: (context, index) {
                        final p = categoryProducts[index];
                        final cartItem = ref.watch(cartProvider).where((item) => item.product.id == p.id).firstOrNull;
                        final currentQty = cartItem?.quantity ?? 0;
                        
                        final bool isOutOfStock = p.quantity == 0;
                        final bool isLowStock = p.quantity > 0 && p.quantity < 10;
                        
                        Color cardColor = Colors.white;
                        Color statusColor = Colors.grey;
                        String statusText = "In Stock: ${p.quantity}";

                        if (isOutOfStock) {
                          cardColor = Colors.red.shade50;
                          statusColor = Colors.red;
                          statusText = "OUT OF STOCK";
                        } else if (isLowStock) {
                          cardColor = Colors.orange.shade50;
                          statusColor = Colors.orange.shade800;
                          statusText = "LOW STOCK: ${p.quantity}";
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: statusColor.withOpacity(0.2)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text("₹${p.price}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                              ],
                            ),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (currentQty > 0) ...[
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20, color: Colors.red),
                                      onPressed: () => ref.read(cartProvider.notifier).updateQuantity(p.id!, -1),
                                    ),
                                    Text("$currentQty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                  IconButton(
                                    icon: Icon(
                                      currentQty == 0 ? Icons.add : Icons.add, 
                                      size: 20, 
                                      color: isOutOfStock ? Colors.grey : Colors.indigo
                                    ),
                                    onPressed: (isOutOfStock || currentQty >= p.quantity) ? null : () {
                                       if (currentQty == 0) {
                                         ref.read(cartProvider.notifier).addToCart(p);
                                       } else {
                                         ref.read(cartProvider.notifier).updateQuantity(p.id!, 1);
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
                loading: () => const LoadingView(),
                error: (err, _) => Center(child: Text("Error: $err")),
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
      ),
    );
  }
}
