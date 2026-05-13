import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/utils/logger.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../billing/presentation/providers/billing_providers.dart';
import '../../../reports/presentation/services/export_service.dart';
import 'store_details_screen.dart';
import '../../../printing/presentation/screens/printer_settings_screen.dart';
import '../../../../data/database/app_database.dart';

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
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
                      ];

                      for (final i in invoices) {
                        rows.add(["INVOICE", i.id, i.customerName ?? "Walk-in", i.date.toIso8601String(), i.totalAmount, ""]);
                        for (final item in i.items) {
                          rows.add(["ITEM", i.id, item.productName, item.productId, item.quantity, item.priceAtBilling]);
                        }
                      }

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
                  leading: const Icon(Icons.file_upload_rounded, color: Colors.blue),
                  title: const Text("Import Database"),
                  subtitle: const Text("Restore sales and menu"),
                  onTap: () async {
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.any,
                      );

                      if (result == null || result.files.single.path == null) return;

                      final path = result.files.single.path!;
                      if (!path.toLowerCase().endsWith('.csv')) {
                        throw Exception("Please select a CSV file");
                      }

                      final file = File(path);
                      final csvString = await file.readAsString();
                      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

                      if (rows.isEmpty) {
                        throw Exception("CSV file is empty");
                      }

                      final header = rows.first;
                      if (header.isEmpty || header[0] != "Type") {
                        throw Exception("Invalid CSV format");
                      }

                      if (!context.mounted) return;

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Restore Backup?"),
                          content: const Text("This will replace your current data with the backup file. Continue?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Restore")),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      final db = ref.read(databaseProvider);
                      await db.clearDatabase();

                      Map<int, int> oldToNewInvoiceId = {};
                      Map<int, int> oldToNewProductId = {};

                      // Phase 1: Products
                      for (final row in rows.skip(1)) {
                        if (row[0] == "PRODUCT") {
                          final oldId = int.tryParse(row[1].toString()) ?? 0;
                          final newId = await db.into(db.products).insert(ProductsCompanion.insert(
                            name: row[2].toString(),
                            category: row[3].toString(),
                            quantity: int.tryParse(row[4].toString()) ?? 0,
                            price: double.tryParse(row[5].toString()) ?? 0.0,
                          ));
                          oldToNewProductId[oldId] = newId;
                        }
                      }

                      // Phase 2: Invoices
                      for (final row in rows.skip(1)) {
                        if (row[0] == "INVOICE") {
                          final oldId = int.tryParse(row[1].toString()) ?? 0;
                          final date = DateTime.tryParse(row[3].toString()) ?? DateTime.now();
                          final total = double.tryParse(row[4].toString()) ?? 0.0;
                          
                          final newId = await db.into(db.invoices).insert(InvoicesCompanion.insert(
                            date: date,
                            totalAmount: total,
                            customerName: Value(row[2].toString()),
                          ));
                          
                          oldToNewInvoiceId[oldId] = newId;
                        }
                      }

                      // Phase 3: Items
                      for (final row in rows.skip(1)) {
                        if (row[0] == "ITEM") {
                          final oldInvoiceId = int.tryParse(row[1].toString()) ?? 0;
                          final newInvoiceId = oldToNewInvoiceId[oldInvoiceId];
                          final oldProductId = int.tryParse(row[3].toString()) ?? 0;
                          final newProductId = oldToNewProductId[oldProductId];
                          
                          if (newInvoiceId != null && newProductId != null) {
                            await db.into(db.invoiceItems).insert(InvoiceItemsCompanion.insert(
                              invoiceId: newInvoiceId,
                              productId: newProductId,
                              quantity: int.tryParse(row[4].toString()) ?? 0,
                              priceAtBilling: double.tryParse(row[5].toString()) ?? 0.0,
                            ));
                          }
                        }
                      }

                      ref.invalidate(productListProvider);
                      ref.invalidate(invoiceHistoryProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Database restored successfully!"), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      AppLogger.e("Import failed", e);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Import failed: $e"), backgroundColor: Colors.red),
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
