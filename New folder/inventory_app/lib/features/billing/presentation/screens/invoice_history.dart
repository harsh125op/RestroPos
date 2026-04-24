import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/billing_providers.dart';
import 'invoice_preview_screen.dart';
import '../../../../core/widgets/common_widgets.dart';

class InvoiceHistoryScreen extends ConsumerWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(invoiceHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Sales History")),
      body: historyAsync.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return const Center(child: Text("No sales recorded yet."));
          }
          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final inv = invoices[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text("Invoice #${inv.id} - ₹${inv.totalAmount}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${inv.date.day}/${inv.date.month}/${inv.date.year} | ${inv.customerName ?? 'Walk-in'}"),
                  children: [
                    ...inv.items.map((item) => ListTile(
                      title: Text(item.productName),
                      subtitle: Text("${item.quantity} x ₹${item.priceAtBilling}"),
                      trailing: Text("₹${(item.quantity * item.priceAtBilling).toStringAsFixed(2)}"),
                    )),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.receipt),
                        label: const Text("View Receipt"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InvoicePreviewScreen(invoice: inv),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString(), onRetry: () => ref.invalidate(invoiceHistoryProvider)),
      ),
    );
  }
}
