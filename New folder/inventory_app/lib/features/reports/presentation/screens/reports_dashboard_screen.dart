import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inventory_app/features/reports/presentation/providers/reports_provider.dart';
import 'package:inventory_app/features/reports/presentation/services/export_service.dart';
import 'package:inventory_app/core/theme/app_theme.dart';

class ReportsDashboardScreen extends ConsumerWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(reportsDateRangeProvider);
    final summaryAsync = ref.watch(dailySalesSummaryProvider(dateRange.start));
    final productSalesAsync = ref.watch(productWiseSalesProvider(dateRange));
    final categorySalesAsync = ref.watch(categoryWiseSalesProvider(dateRange));
    final lowStockAsync = ref.watch(lowStockProductsProvider(5));
    final transactionsAsync = ref.watch(transactionHistoryProvider(dateRange));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailySalesSummaryProvider);
          ref.invalidate(productWiseSalesProvider);
          ref.invalidate(categoryWiseSalesProvider);
          ref.invalidate(lowStockProductsProvider);
          ref.invalidate(transactionHistoryProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummarySection(summaryAsync),
              const SizedBox(height: 24),
              _buildExportButtons(ref),
              const SizedBox(height: 24),
              _buildSectionTitle("Product-wise Sales"),
              _buildProductSalesTable(productSalesAsync),
              const SizedBox(height: 24),
              _buildSectionTitle("Category-wise Sales"),
              _buildCategorySalesCards(categorySalesAsync),
              const SizedBox(height: 24),
              _buildSectionTitle("Low Stock Alerts"),
              _buildLowStockList(lowStockAsync),
              const SizedBox(height: 24),
              _buildSectionTitle("Recent Transactions"),
              _buildTransactionList(transactionsAsync),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(AsyncValue summaryAsync) {
    return summaryAsync.when(
      data: (data) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
        children: [
          _SummaryCard(
            title: "Total Sales",
            value: "₹${data.totalSales.toStringAsFixed(0)}",
            icon: Icons.currency_rupee,
            color: Colors.blue,
          ),
          _SummaryCard(
            title: "Orders",
            value: data.totalOrders.toString(),
            icon: Icons.shopping_bag,
            color: Colors.orange,
          ),
          _SummaryCard(
            title: "Avg Order",
            value: "₹${data.averageOrderValue.toStringAsFixed(0)}",
            icon: Icons.analytics,
            color: Colors.green,
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text("Error: $err"),
    );
  }

  Widget _buildExportButtons(WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleExport(ref, 'PDF'),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Export PDF"),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleExport(ref, 'CSV'),
            icon: const Icon(Icons.table_chart),
            label: const Text("Export CSV"),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProductSalesTable(AsyncValue productSalesAsync) {
    return productSalesAsync.when(
      data: (data) => data.isEmpty
          ? _buildEmptyState("No sales data available")
          : Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = data[index];
                  return ListTile(
                    title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("Qty: ${item.quantitySold}"),
                    trailing: Text(
                      "₹${item.revenue.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  );
                },
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text("Error: $err"),
    );
  }

  Widget _buildCategorySalesCards(AsyncValue categorySalesAsync) {
    return categorySalesAsync.when(
      data: (data) => data.isEmpty
          ? _buildEmptyState("No category data")
          : SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("₹${item.totalRevenue.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                },
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text("Error: $err"),
    );
  }

  Widget _buildLowStockList(AsyncValue lowStockAsync) {
    return lowStockAsync.when(
      data: (data) => data.isEmpty
          ? _buildEmptyState("All products in stock", icon: Icons.check_circle_outline)
          : Card(
              color: Colors.red.shade50,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  return ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(item.name),
                    trailing: Text("Stock: ${item.quantity}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text("Error: $err"),
    );
  }

  Widget _buildTransactionList(AsyncValue transactionsAsync) {
    final dateFormat = DateFormat('hh:mm a');
    return transactionsAsync.when(
      data: (data) => data.isEmpty
          ? _buildEmptyState("No transactions found")
          : Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = data[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text("#${item.id}"),
                    ),
                    title: Text(item.customerName ?? "Walk-in Customer"),
                    subtitle: Text(dateFormat.format(item.date)),
                    trailing: Text(
                      "₹${item.totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text("Error: $err"),
    );
  }

  Widget _buildEmptyState(String message, {IconData icon = Icons.info_outline}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 32),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final currentRange = ref.read(reportsDateRangeProvider);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: currentRange.start, end: currentRange.end),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      ref.read(reportsDateRangeProvider.notifier).state = (start: picked.start, end: picked.end);
    }
  }

  Future<void> _handleExport(WidgetRef ref, String format) async {
    final dateRange = ref.read(reportsDateRangeProvider);
    final transactions = await ref.read(reportsRepositoryProvider).getTransactionHistory(start: dateRange.start, end: dateRange.end);
    final productSales = await ref.read(reportsRepositoryProvider).getProductWiseSales(start: dateRange.start, end: dateRange.end);

    if (format == 'PDF') {
      await ExportService.exportTransactionHistoryToPDF(transactions);
    } else {
      List<List<dynamic>> csvRows = [
        ['Bill ID', 'Date', 'Customer', 'Total Amount']
      ];
      for (var t in transactions) {
        csvRows.add([t.id, t.date.toString(), t.customerName ?? 'Walk-in', t.totalAmount]);
      }
      await ExportService.exportToCSV(fileName: 'transaction_history', rows: csvRows);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
