import 'package:drift/drift.dart';
import 'package:inventory_app/data/database/app_database.dart';
import 'package:inventory_app/features/billing/domain/entities/invoice_entity.dart';
import 'package:inventory_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventory_app/features/reports/domain/entities/sales_summary_entity.dart';
import 'package:inventory_app/features/reports/domain/entities/product_sales_entity.dart';
import 'package:inventory_app/features/reports/domain/entities/category_sales_entity.dart';
import 'package:inventory_app/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final AppDatabase _db;

  ReportsRepositoryImpl(this._db);

  @override
  Future<SalesSummaryEntity> getDailySalesSummary(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _db.select(_db.invoices)
      ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay));

    final results = await query.get();

    if (results.isEmpty) {
      return SalesSummaryEntity.empty();
    }

    double totalSales = 0;
    for (var row in results) {
      totalSales += row.totalAmount;
    }

    return SalesSummaryEntity(
      totalSales: totalSales,
      totalOrders: results.length,
      averageOrderValue: results.isNotEmpty ? totalSales / results.length : 0,
    );
  }

  @override
  Future<List<ProductSalesEntity>> getProductWiseSales({DateTime? start, DateTime? end}) async {
    final query = _db.select(_db.invoiceItems).join([
      innerJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
      innerJoin(_db.invoices, _db.invoices.id.equalsExp(_db.invoiceItems.invoiceId)),
    ]);

    if (start != null && end != null) {
      query.where(_db.invoices.date.isBetweenValues(start, end));
    }

    final quantitySum = _db.invoiceItems.quantity.sum();
    final revenueSum = (_db.invoiceItems.quantity.cast<double>() * _db.invoiceItems.priceAtBilling).sum();

    query.addColumns([_db.products.name, quantitySum, revenueSum]);
    query.groupBy([_db.products.id]);
    query.orderBy([OrderingTerm.desc(quantitySum)]);

    final results = await query.get();

    return results.map((row) {
      return ProductSalesEntity(
        productName: row.read(_db.products.name)!,
        quantitySold: row.read(quantitySum) ?? 0,
        revenue: row.read(revenueSum) ?? 0.0,
      );
    }).toList();
  }

  @override
  Future<List<CategorySalesEntity>> getCategoryWiseSales({DateTime? start, DateTime? end}) async {
    final query = _db.select(_db.invoiceItems).join([
      innerJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
      innerJoin(_db.invoices, _db.invoices.id.equalsExp(_db.invoiceItems.invoiceId)),
    ]);

    if (start != null && end != null) {
      query.where(_db.invoices.date.isBetweenValues(start, end));
    }

    final quantitySum = _db.invoiceItems.quantity.sum();
    final revenueSum = (_db.invoiceItems.quantity.cast<double>() * _db.invoiceItems.priceAtBilling).sum();

    query.addColumns([_db.products.category, quantitySum, revenueSum]);
    query.groupBy([_db.products.category]);

    final results = await query.get();

    return results.map((row) {
      return CategorySalesEntity(
        categoryName: row.read(_db.products.category)!,
        totalRevenue: row.read(revenueSum) ?? 0.0,
        totalQuantity: row.read(quantitySum) ?? 0,
      );
    }).toList();
  }

  @override
  Future<List<ProductEntity>> getLowStockProducts(int threshold) async {
    final query = _db.select(_db.products)..where((t) => t.quantity.isSmallerOrEqualValue(threshold));
    final results = await query.get();

    return results.map((p) => ProductEntity(
      id: p.id,
      name: p.name,
      category: p.category,
      quantity: p.quantity,
      price: p.price,
    )).toList();
  }

  @override
  Future<List<InvoiceEntity>> getTransactionHistory({DateTime? start, DateTime? end}) async {
    final query = _db.select(_db.invoices);
    
    if (start != null && end != null) {
      query.where((t) => t.date.isBetweenValues(start, end));
    }
    
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);

    final results = await query.get();
    
    List<InvoiceEntity> entities = [];
    for (final inv in results) {
      final itemsQuery = _db.select(_db.invoiceItems).join([
        innerJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
      ])..where(_db.invoiceItems.invoiceId.equals(inv.id));
      
      final itemRows = await itemsQuery.get();
      
      final itemEntities = itemRows.map((row) {
        final item = row.readTable(_db.invoiceItems);
        final product = row.readTable(_db.products);
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
