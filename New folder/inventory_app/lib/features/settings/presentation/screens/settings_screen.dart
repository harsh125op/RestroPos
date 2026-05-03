import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/utils/logger.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../billing/presentation/providers/billing_providers.dart';
import '../../../reports/presentation/services/export_service.dart';
import 'store_details_screen.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(context, "Business Profile"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.store_rounded, color: Colors.indigo),
                  title: const Text("Restaurant & Cashier"),
                  subtitle: const Text("Name, Address, Phone, GSTIN"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoreDetailsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, "Appearance"),
          const SizedBox(height: 24),
          _buildSectionTitle(context, "Hardware"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.print_rounded, color: Colors.indigo),
                  title: const Text("Printer Configuration"),
                  subtitle: const Text("Manage Bluetooth printers"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to printer selection screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Printer settings coming soon")),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, "Data Management"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_rounded, color: Colors.green),
                  title: const Text("Export Database"),
                  subtitle: const Text("Backup your sales and menu"),
                  onTap: () async {
                    try {
                      final products = await ref.read(productListProvider.future);
                      final invoices = await ref.read(invoiceHistoryProvider.future);
                      
                      final List<List<dynamic>> rows = [
                        ["Type", "ID", "Name/Customer", "Category/Date", "Qty/Total", "Price"],
                        ...products.map((p) => ["PRODUCT", p.id, p.name, p.category, p.quantity, p.price]),
                        ...invoices.map((i) => ["INVOICE", i.id, i.customerName ?? "Walk-in", i.date.toIso8601String(), i.totalAmount, ""]),
                      ];

                      await ExportService.exportToCSV(
                        fileName: "quickpos_backup_${DateTime.now().millisecondsSinceEpoch}",
                        rows: rows,
                      );
                    } catch (e) {
                      AppLogger.e("Export failed", e);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Export failed: $e"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: const Text("Clear All Data", style: TextStyle(color: Colors.red)),
                  subtitle: const Text("Delete all products and history"),
                  onTap: () => _showClearDataDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              "QuickPOS v1.0.0",
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Data?"),
        content: const Text("This action cannot be undone. All your products, invoices, and reports will be permanently deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(databaseProvider).clearDatabase();
                ref.invalidate(productListProvider);
                ref.invalidate(invoiceHistoryProvider);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("All data has been cleared"),
                      backgroundColor: Colors.black87,
                    ),
                  );
                }
              } catch (e) {
                AppLogger.e("Failed to clear database", e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Clear Everything", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
