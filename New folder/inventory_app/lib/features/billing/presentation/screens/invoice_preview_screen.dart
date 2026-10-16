import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/invoice_entity.dart';
import '../utils/invoice_formatter.dart';
import '../../../settings/presentation/providers/store_details_provider.dart';
import '../../../printing/presentation/screens/printer_settings_screen.dart';
import '../../../printing/presentation/providers/printing_providers.dart';
import '../providers/billing_providers.dart';
import 'create_invoice_screen.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  final InvoiceEntity invoice;
  final double discount;
  final double serviceCharge;

  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
    this.discount = 0.0,
    this.serviceCharge = 0.0,
  });

  Future<void> _handleEdit(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Loading items to edit...",
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ref
          .read(invoiceHistoryProvider.notifier)
          .prepareInvoiceForEditing(invoice);

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CreateInvoiceScreen(
              initialCustomerName: invoice.customerName,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load order for editing: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeDetails = ref.watch(storeDetailsProvider);
    final formattedText = InvoiceFormatter.formatForThermalPrinter(
      invoice,
      storeDetails,
      discount: discount,
      serviceCharge: serviceCharge,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: "Edit Order",
            onPressed: () => _handleEdit(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Printer Settings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrinterSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/billlogo.png',
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    formattedText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () => _handleEdit(context, ref),
                  icon: const Icon(Icons.edit_rounded,
                      size: 20, color: Colors.indigo),
                  label: const Text(
                    "Edit Order",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    side: const BorderSide(color: Colors.indigo, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final service = ref.read(bluetoothPrintServiceProvider);

                    final success = await service.printReceipt(
                        formattedText, 'assets/billlogo.png');

                    if (context.mounted) {
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Failed to print. Is printer connected?"),
                              backgroundColor: Colors.red),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Printing..."),
                              backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.print_rounded, size: 20),
                  label: const Text(
                    "Print",
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
