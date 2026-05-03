import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_providers.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../../../../core/widgets/common_widgets.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productListAsync = ref.watch(filteredProductListProvider);
    final currentSort = ref.watch(productSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Items"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search products or categories...",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(productSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => ref.read(productSearchQueryProvider.notifier).state = val,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<ProductSortType>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (sort) => ref.read(productSortProvider.notifier).state = sort,
            itemBuilder: (context) => [
              _buildSortItem(ProductSortType.name, "Name (A-Z)", currentSort),
              _buildSortItem(ProductSortType.priceLowHigh, "Price: Low to High", currentSort),
              _buildSortItem(ProductSortType.priceHighLow, "Price: High to Low", currentSort),
              _buildSortItem(ProductSortType.stockLowHigh, "Stock: Low to High", currentSort),
              _buildSortItem(ProductSortType.stockHighLow, "Stock: High to Low", currentSort),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: productListAsync.when(
        data: (products) {
          if (products.isEmpty) {
            final isSearching = ref.read(productSearchQueryProvider).isNotEmpty;
            return EmptyStateView(
              title: isSearching ? "No results found" : "No Menu Items",
              message: isSearching 
                ? "Try searching for something else or clear the filter."
                : "Your restaurant's menu is currently empty.\nStart by adding your first food item!",
              icon: isSearching ? Icons.search_off_rounded : Icons.restaurant_menu_rounded,
              action: isSearching ? null : SizedBox(
                width: 200,
                child: CustomButton(
                  label: "Add First Item",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddProductScreen()),
                    );
                  },
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(productListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                final bool isLowStock = product.quantity < 10 && product.quantity > 0;
                final bool isOutOfStock = product.quantity == 0;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProductScreen(product: product),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(product.category),
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      product.category,
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "₹${product.price}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : isLowStock
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isOutOfStock
                                      ? "OUT"
                                      : isLowStock
                                          ? "LOW: ${product.quantity}"
                                          : "STOCK: ${product.quantity}",
                                  style: TextStyle(
                                    color: isOutOfStock
                                        ? Colors.red[700]
                                        : isLowStock
                                            ? Colors.orange[800]
                                            : Colors.green[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingView(message: "Searching menu..."),
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
        label: const Text("New Item"),
        icon: const Icon(Icons.add),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  PopupMenuItem<ProductSortType> _buildSortItem(ProductSortType value, String label, ProductSortType current) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            current == value ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: current == value ? Colors.indigo : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            color: current == value ? Colors.indigo : Colors.black87,
            fontWeight: current == value ? FontWeight.bold : FontWeight.normal,
          )),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sweets':
        return Icons.icecream_rounded;
      case 'chaat':
        return Icons.fastfood_rounded;
      case 'juice':
        return Icons.local_drink_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }
}
