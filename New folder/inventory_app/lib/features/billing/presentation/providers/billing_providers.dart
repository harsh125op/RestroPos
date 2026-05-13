import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../inventory/domain/entities/product_entity.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../data/repositories/billing_repository_impl.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepositoryImpl(ref.watch(databaseProvider));
});

// Cart state management
class CartItem {
  final ProductEntity product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(ProductEntity product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      if (state[existingIndex].quantity < product.quantity) {
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == existingIndex)
              CartItem(product: state[i].product, quantity: state[i].quantity + 1)
            else
              state[i]
        ];
      }
    } else {
      if (product.quantity > 0) {
        state = [...state, CartItem(product: product)];
      }
    }
  }

  void removeFromCart(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(int productId, int delta) {
    final List<CartItem> newState = [];
    for (final item in state) {
      if (item.product.id == productId) {
        final newQuantity = item.quantity + delta;
        if (newQuantity >= 1) {
          newState.add(CartItem(
            product: item.product,
            quantity: newQuantity.clamp(1, item.product.quantity),
          ));
        }
        // If < 1, we don't add it to newState (effectively removing it)
      } else {
        newState.add(item);
      }
    }
    state = newState;
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount => state.fold(0, (sum, item) => sum + item.total);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

enum InvoiceSortType { dateNewest, dateOldest, amountHighLow, amountLowHigh }

final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');
final invoiceSortProvider = StateProvider<InvoiceSortType>((ref) => InvoiceSortType.dateNewest);
final invoiceDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final filteredInvoiceHistoryProvider = Provider<AsyncValue<List<InvoiceEntity>>>((ref) {
  final historyAsync = ref.watch(invoiceHistoryProvider);
  final searchQuery = ref.watch(invoiceSearchQueryProvider).toLowerCase();
  final sortType = ref.watch(invoiceSortProvider);
  final dateRange = ref.watch(invoiceDateRangeProvider);

  return historyAsync.whenData((invoices) {
    var filtered = invoices.where((inv) {
      final matchesSearch = inv.customerName?.toLowerCase().contains(searchQuery) ?? false || 
                          inv.id.toString().contains(searchQuery);
      
      bool matchesDate = true;
      if (dateRange != null) {
        matchesDate = inv.date.isAfter(dateRange.start) && 
                      inv.date.isBefore(dateRange.end.add(const Duration(days: 1)));
      }
      
      return matchesSearch && matchesDate;
    }).toList();

    switch (sortType) {
      case InvoiceSortType.dateNewest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
      case InvoiceSortType.dateOldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
      case InvoiceSortType.amountHighLow:
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      case InvoiceSortType.amountLowHigh:
        filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
    }
    return filtered;
  });
});

final invoiceHistoryProvider = AsyncNotifierProvider<InvoiceHistoryNotifier, List<InvoiceEntity>>(() {
  return InvoiceHistoryNotifier();
});

class InvoiceHistoryNotifier extends AsyncNotifier<List<InvoiceEntity>> {
  @override
  Future<List<InvoiceEntity>> build() async {
    return ref.read(billingRepositoryProvider).getInvoices();
  }

  Future<InvoiceEntity?> createInvoice(String? customerName) async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return null;

    final invoice = InvoiceEntity(
      date: DateTime.now(),
      totalAmount: ref.read(cartProvider.notifier).totalAmount,
      customerName: customerName,
      items: cartItems.map((item) => InvoiceItemEntity(
        productId: item.product.id!,
        productName: item.product.name,
        quantity: item.quantity,
        priceAtBilling: item.product.price,
      )).toList(),
    );

    state = const AsyncLoading();
    try {
      final invoiceId = await ref.read(billingRepositoryProvider).createInvoice(invoice);
      ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(productListProvider); // Refresh stock in inventory
      state = AsyncValue.data(await ref.read(billingRepositoryProvider).getInvoices());
      
      return InvoiceEntity(
        id: invoiceId,
        date: invoice.date,
        totalAmount: invoice.totalAmount,
        customerName: invoice.customerName,
        items: invoice.items,
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }
}
