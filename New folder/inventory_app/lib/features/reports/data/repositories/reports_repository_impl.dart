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
  Future<SalesSummaryEntity> getSalesSummary({DateTime? start, DateTime? end}) async {
    final query = _db.select(_db.invoices);
    
    if (start != null && end != null) {
      query.where((t) => t.date.isBetweenValues(start, end.add(const Duration(days: 1))));
    }
    
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
      query.where(_db.invoices.date.isBetweenValues(start, end.add(const Duration(days: 1))));
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
      query.where(_db.invoices.date.isBetweenValues(start, end.add(const Duration(days: 1))));
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
    final query = _db.select(_db.invoices).join([
      leftOuterJoin(_db.invoiceItems, _db.invoiceItems.invoiceId.equalsExp(_db.invoices.id)),
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
    ]);
    
    if (start != null && end != null) {
      query.where(_db.invoices.date.isBetweenValues(start, end.add(const Duration(days: 1))));
    }
    
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
  }
}
