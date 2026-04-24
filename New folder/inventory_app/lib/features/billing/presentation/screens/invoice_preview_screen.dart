import 'package:flutter/material.dart';
import '../../domain/entities/invoice_entity.dart';
import '../utils/invoice_formatter.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final InvoiceEntity invoice;
  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final formattedText = InvoiceFormatter.formatForThermalPrinter(invoice);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Bluetooth printing not configured. Copying to clipboard...")),
              );
              // Implementation for actual printing would go here
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      formattedText,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.done_all),
          label: const Text("Close"),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
        ),
      ),
    );
  }
}
