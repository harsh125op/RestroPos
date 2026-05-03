import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_providers.dart';
import 'invoice_preview_screen.dart';
import '../../../../core/widgets/common_widgets.dart';

import 'package:intl/intl.dart';

class InvoiceHistoryScreen extends ConsumerStatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  ConsumerState<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends ConsumerState<InvoiceHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final currentRange = ref.read(invoiceDateRangeProvider);
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          child: child!,
        );
      },
    );
    if (newRange != null) {
      ref.read(invoiceDateRangeProvider.notifier).state = newRange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(filteredInvoiceHistoryProvider);
    final currentSort = ref.watch(invoiceSortProvider);
    final dateRange = ref.watch(invoiceDateRangeProvider);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales History"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by ID or Customer...",
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(invoiceSearchQueryProvider.notifier).state = '';
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
                  onChanged: (val) => ref.read(invoiceSearchQueryProvider.notifier).state = val,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range_rounded, size: 18),
                        label: Text(
                          dateRange == null 
                            ? "Filter by Date" 
                            : "${DateFormat('dd/MM').format(dateRange.start)} - ${DateFormat('dd/MM').format(dateRange.end)}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () => _selectDateRange(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: dateRange != null ? Colors.indigo : Colors.grey[700],
                          side: BorderSide(color: dateRange != null ? Colors.indigo : Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (dateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => ref.read(invoiceDateRangeProvider.notifier).state = null,
                        color: Colors.red,
                      ),
                    ],
                    const SizedBox(width: 8),
                    PopupMenuButton<InvoiceSortType>(
                      icon: const Icon(Icons.sort_rounded),
                      onSelected: (sort) => ref.read(invoiceSortProvider.notifier).state = sort,
                      itemBuilder: (context) => [
                        _buildSortItem(InvoiceSortType.dateNewest, "Date: Newest First", currentSort),
                        _buildSortItem(InvoiceSortType.dateOldest, "Date: Oldest First", currentSort),
                        _buildSortItem(InvoiceSortType.amountHighLow, "Amount: High to Low", currentSort),
                        _buildSortItem(InvoiceSortType.amountLowHigh, "Amount: Low to High", currentSort),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: historyAsync.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            final hasFilter = ref.read(invoiceSearchQueryProvider).isNotEmpty || 
                             ref.read(invoiceDateRangeProvider) != null;
            return EmptyStateView(
              title: hasFilter ? "No matches found" : "No sales yet",
              message: hasFilter 
                ? "Try adjusting your filters or search terms."
                : "Record your first sale to see it here!",
              icon: hasFilter ? Icons.filter_list_off_rounded : Icons.history_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final inv = invoices[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: ExpansionTile(
                  shape: const RoundedRectangleBorder(side: BorderSide.none),
                  collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.indigo, size: 24),
                  ),
                  title: Text(
                    "Invoice #${inv.id}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  subtitle: Text(
                    "${dateFormat.format(inv.date)}\n${inv.customerName ?? 'Walk-in'}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  trailing: Text(
                    "₹${inv.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.indigo),
                  ),
                  children: [
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ...inv.items.map((item) => ListTile(
                      dense: true,
                      title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${item.quantity} x ₹${item.priceAtBilling}"),
                      trailing: Text("₹${(item.quantity * item.priceAtBilling).toStringAsFixed(2)}"),
                    )),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text("View & Print Receipt"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvoicePreviewScreen(invoice: inv),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(message: "Fetching history..."),
        error: (err, _) => ErrorView(
          message: err.toString(), 
          onRetry: () => ref.invalidate(invoiceHistoryProvider)
        ),
      ),
    );
  }

  PopupMenuItem<InvoiceSortType> _buildSortItem(InvoiceSortType value, String label, InvoiceSortType current) {
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
}
