import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/printing_providers.dart';
import '../../data/services/receipt_formatter.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  Future<void> _printTestReceipt() async {
    final service = ref.read(bluetoothPrintServiceProvider);
    final formatter = ref.read(receiptFormatterProvider);

    // Generate receipt text with test data
    final receiptText = formatter.generateReceipt(
      restaurantName: "QuickPos Restaurant",
      phoneNumber: "+91 9876543210",
      address: "123 Foodie Street, City",
      invoiceNumber: "INV-TEST-001",
      dateTime: DateTime.now(),
      cashierName: "Test Cashier",
      items: [
        ReceiptItem(name: "Gulab Jamun", quantity: 1, price: 20, total: 20),
        ReceiptItem(name: "Orange Juice", quantity: 1, price: 50, total: 50),
      ],
      grandTotal: 70,
    );

    final success = await service.printReceipt(receiptText);
    
    if (mounted) {
      if (!success) {
        // If failed, assume app is not installed or error
        _showAppNotInstalledDialog();
      }
    }
  }

  void _showAppNotInstalledDialog() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Printer Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.print, color: Colors.teal, size: 28),
                        SizedBox(width: 12),
                        Text("Printing Integration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "This app uses the external 'Bluetooth Print' app to handle thermal printing via Intents. This ensures maximum stability and compatibility.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text("Intent Communication Active"),
                      subtitle: Text("Ready to send print jobs"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Actions
            const Text("Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _printTestReceipt,
                icon: const Icon(Icons.text_fields),
                label: const Text("Print Test Receipt"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ref.read(bluetoothPrintServiceProvider).openPlayStore(),
                icon: const Icon(Icons.get_app),
                label: const Text("Install Bluetooth Print App"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
