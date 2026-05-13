import 'package:drift/drift.dart';
import 'package:inventory_app/data/database/app_database.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/billing_repository.dart';

class BillingRepositoryImpl implements BillingRepository {
  final AppDatabase _db;

  BillingRepositoryImpl(this._db);

  @override
  Future<int> createInvoice(InvoiceEntity invoice) async {
    try {
      final invoiceCompanion = InvoicesCompanion.insert(
        date: invoice.date,
        totalAmount: invoice.totalAmount,
        customerName: invoice.customerName != null ? Value(invoice.customerName) : const Value.absent(),
      );

      final itemCompanions = invoice.items.map((item) => InvoiceItemsCompanion(
        invoiceId: const Value.absent(), // Will be set in transaction
        productId: Value(item.productId),
        quantity: Value(item.quantity),
        priceAtBilling: Value(item.priceAtBilling),
      )).toList();

      return await _db.createInvoiceTransaction(
        invoice: invoiceCompanion,
        items: itemCompanions,
      );
    } catch (e) {
      throw Exception("Failed to create invoice: $e");
    }
  }

  @override
  Future<List<InvoiceEntity>> getInvoices() async {
    try {
      final query = _db.select(_db.invoices).join([
        leftOuterJoin(_db.invoiceItems, _db.invoiceItems.invoiceId.equalsExp(_db.invoices.id)),
        leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
      ]);
      
      query.orderBy([OrderingTerm.desc(_db.invoices.date)]);

      final rows = await query.get();
      
      final Map<int, InvoiceEntity> invoiceMap = {};
      
      for (final row in rows) {
        final inv = row.readTable(_db.invoices);
        final item = row.readTableOrNull(_db.invoiceItems);
        final product = row.readTableOrNull(_db.products);
        
        if (!invoiceMap.containsKey(inv.id)) {
          invoiceMap[inv.id] = InvoiceEntity(
            id: inv.id,
            date: inv.date,
            totalAmount: inv.totalAmount,
            customerName: inv.customerName,
            items: [],
          );
        }
        
        if (item != null && product != null) {
          invoiceMap[inv.id]!.items.add(InvoiceItemEntity(
            id: item.id,
            invoiceId: item.invoiceId,
            productId: item.productId,
            productName: product.name,
            quantity: item.quantity,
            priceAtBilling: item.priceAtBilling,
          ));
        }
      }
      
      return invoiceMap.values.toList();
    } catch (e) {
      throw Exception("Failed to fetch invoices: $e");
    }
  }
}
