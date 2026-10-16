import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get quantity => integer()();
  RealColumn get price => real()();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get totalAmount => real()();
  TextColumn get customerName => text().nullable()();
}

class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  RealColumn get priceAtBilling => real()();
}

@DriftDatabase(tables: [Products, Invoices, InvoiceItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(invoices);
            await m.createTable(invoiceItems);
          }
          if (from < 3) {
            await m.alterTable(TableMigration(products, columnTransformer: {
              products.category: const Constant('Uncategorized'),
            }, newColumns: [
              products.category
            ]));
          }
          if (from < 4) {
            // Add indexes for performance
            await m.createIndex(Index('idx_product_name', 'CREATE INDEX idx_product_name ON products (name)'));
            await m.createIndex(Index('idx_product_category', 'CREATE INDEX idx_product_category ON products (category)'));
            await m.createIndex(Index('idx_invoice_date', 'CREATE INDEX idx_invoice_date ON invoices (date)'));
          }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');

          final count = await select(products).get();
          if (count.isEmpty) {
            await preloadData();
          }
        },
      );

  Future<void> preloadData() async {
    try {
      String csvString = await rootBundle.loadString('assets/default_menu.csv');
      csvString = csvString.replaceAll('\r\n', '\n'); // Normalize line endings
      final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(csvString);
      
      for (final row in rows.skip(1)) {
        if (row.isEmpty) continue;
        final type = row[0].toString().trim().toUpperCase();
        if (type == 'PRODUCT' && row.length >= 6) {
          final priceStr = row[5].toString().trim();
          final price = priceStr == 'MRP' ? 0.0 : (double.tryParse(priceStr) ?? 0.0);
          
          await into(products).insert(ProductsCompanion.insert(
            name: row[2].toString(),
            category: row[3].toString(),
            quantity: 100, // Default starting stock
            price: price,
          ));
        }
      }
    } catch (e) {
      // Fallback if asset loading fails
      await into(products).insert(ProductsCompanion.insert(name: 'Bottled Water', category: 'Beverages', quantity: 100, price: 20));
    }
  }

  // Billing Transaction (Stock is not reduced; items remain constantly available)
  Future<int> createInvoiceTransaction({
    required InvoicesCompanion invoice,
    required List<InvoiceItemsCompanion> items,
  }) async {
    return await transaction(() async {
      final invoiceId = await into(invoices).insert(invoice);

      for (final item in items) {
        final itemToInsert = item.copyWith(invoiceId: Value(invoiceId));
        await into(invoiceItems).insert(itemToInsert);
      }
      return invoiceId;
    });
  }

  // Delete Invoice
  Future<void> deleteInvoiceTransaction(int invoiceId) async {
    await transaction(() async {
      // 1. Delete invoice items
      await (delete(invoiceItems)..where((t) => t.invoiceId.equals(invoiceId))).go();

      // 2. Delete invoice
      await (delete(invoices)..where((t) => t.id.equals(invoiceId))).go();
    });
  }

  // Clear All Data
  Future<void> clearDatabase() async {
    await transaction(() async {
      await delete(invoiceItems).go();
      await delete(invoices).go();
      await delete(products).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}