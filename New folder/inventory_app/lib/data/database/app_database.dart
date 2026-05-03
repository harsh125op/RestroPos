import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
            await _preloadData();
          }
        },
      );

  Future<void> _preloadData() async {
    final defaultItems = [
      // Sweets
      ProductsCompanion.insert(name: 'Gulab Jamun', category: 'Sweets', quantity: 100, price: 20),
      ProductsCompanion.insert(name: 'Rasgulla', category: 'Sweets', quantity: 100, price: 25),
      // Chaat
      ProductsCompanion.insert(name: 'Pani Puri', category: 'Chaat', quantity: 100, price: 30),
      ProductsCompanion.insert(name: 'Bhel Puri', category: 'Chaat', quantity: 100, price: 40),
      // Juice
      ProductsCompanion.insert(name: 'Orange Juice', category: 'Juice', quantity: 100, price: 50),
      ProductsCompanion.insert(name: 'Mango Juice', category: 'Juice', quantity: 100, price: 60),
      // Coffee
      ProductsCompanion.insert(name: 'Cold Coffee', category: 'Coffee', quantity: 100, price: 80),
      ProductsCompanion.insert(name: 'Espresso', category: 'Coffee', quantity: 100, price: 70),
    ];

    for (final item in defaultItems) {
      await into(products).insert(item);
    }
  }

  // Billing Transaction
  Future<void> createInvoiceTransaction({
    required InvoicesCompanion invoice,
    required List<InvoiceItemsCompanion> items,
  }) async {
    await transaction(() async {
      final invoiceId = await into(invoices).insert(invoice);

      for (final item in items) {
        final itemToInsert = item.copyWith(invoiceId: Value(invoiceId));
        await into(invoiceItems).insert(itemToInsert);

        // Update product stock
        final product = await (select(products)
              ..where((t) => t.id.equals(item.productId.value)))
            .getSingle();

        if (product.quantity < item.quantity.value) {
          throw Exception('Insufficient stock for ${product.name}');
        }

        await (update(products)..where((t) => t.id.equals(item.productId.value)))
            .write(ProductsCompanion(
          quantity: Value(product.quantity - item.quantity.value),
        ));
      }
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