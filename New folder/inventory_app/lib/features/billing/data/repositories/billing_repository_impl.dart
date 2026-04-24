import 'package:drift/drift.dart';
import 'package:inventory_app/data/database/app_database.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/billing_repository.dart';

class BillingRepositoryImpl implements BillingRepository {
  final AppDatabase _db;

  BillingRepositoryImpl(this._db);

  @override
  Future<void> createInvoice(InvoiceEntity invoice) async {
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

    await _db.createInvoiceTransaction(
      invoice: invoiceCompanion,
      items: itemCompanions,
    );
  }

  @override
  Future<List<InvoiceEntity>> getInvoices() async {
    final invoices = await _db.select(_db.invoices).get();
    
    List<InvoiceEntity> entities = [];
    for (final inv in invoices) {
      final items = await (_db.select(_db.invoiceItems)
            ..where((t) => t.invoiceId.equals(inv.id)))
          .get();
      
      final productIds = items.map((e) => e.productId).toList();
      final products = await (_db.select(_db.products)..where((t) => t.id.isIn(productIds))).get();
      
      final itemEntities = items.map((item) {
        final product = products.firstWhere((p) => p.id == item.productId);
        return InvoiceItemEntity(
          id: item.id,
          invoiceId: item.invoiceId,
          productId: item.productId,
          productName: product.name,
          quantity: item.quantity,
          priceAtBilling: item.priceAtBilling,
        );
      }).toList();

      entities.add(InvoiceEntity(
        id: inv.id,
        date: inv.date,
        totalAmount: inv.totalAmount,
        customerName: inv.customerName,
        items: itemEntities,
      ));
    }
    return entities;
  }
}
