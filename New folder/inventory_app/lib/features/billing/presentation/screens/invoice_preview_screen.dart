import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/invoice_entity.dart';
import '../utils/invoice_formatter.dart';
import '../../../settings/presentation/providers/store_details_provider.dart';
import '../../../printing/presentation/providers/printing_providers.dart';
import '../../../printing/presentation/screens/printer_settings_screen.dart';
import '../../../printing/data/services/receipt_formatter.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  final InvoiceEntity invoice;
  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeDetails = ref.watch(storeDetailsProvider);
    final formattedText = InvoiceFormatter.formatForThermalPrinter(invoice, storeDetails);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            final service = ref.read(bluetoothPrintServiceProvider);
            final formatter = ref.read(receiptFormatterProvider);
            
            final receiptText = formatter.generateReceipt(
              restaurantName: storeDetails.restaurantName,
              phoneNumber: storeDetails.phone,
              address: storeDetails.address,
              invoiceNumber: invoice.id.toString(),
              dateTime: invoice.date,
              cashierName: storeDetails.cashierName,
              items: invoice.items.map((item) => ReceiptItem(
                name: item.productName,
                quantity: item.quantity,
                price: item.priceAtBilling,
                total: item.priceAtBilling * item.quantity,
              )).toList(),
              grandTotal: invoice.totalAmount,
            );
            
            final success = await service.printReceipt(receiptText);
            
            if (context.mounted) {
              if (!success) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("App Not Installed"),
                    content: const Text("The 'Bluetooth Print' app is required for printing. Would you like to install it from the Play Store?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(bluetoothPrintServiceProvider).openPlayStore();
                        },
                        child: const Text("Install"),
                      ),
                    ],
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Print", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
