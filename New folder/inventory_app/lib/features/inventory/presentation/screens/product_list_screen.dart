import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_providers.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../../../../core/widgets/common_widgets.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productListAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Items"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productListProvider),
          ),
        ],
      ),
      body: productListAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("No menu items found. Start by adding one!",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                child: ListTile(
                  title: Text(product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(product.category, style: TextStyle(fontSize: 12, color: Colors.indigo[700], fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text("₹${product.price}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Stock: ${product.quantity}", 
                            style: TextStyle(
                              color: product.quantity > 10 ? Colors.green[700] : Colors.red[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit, size: 20, color: Colors.indigo),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProductScreen(product: product),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Item"),
                        content: Text("Are you sure you want to delete ${product.name}?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(productListProvider.notifier).deleteProduct(product.id!);
                              Navigator.pop(context);
                            },
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(productListProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        label: const Text("Add Item"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
