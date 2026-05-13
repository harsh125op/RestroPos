import 'package:inventory_app/features/billing/domain/entities/invoice_entity.dart';
import 'package:inventory_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventory_app/features/reports/domain/entities/sales_summary_entity.dart';
import 'package:inventory_app/features/reports/domain/entities/product_sales_entity.dart';
import 'package:inventory_app/features/reports/domain/entities/category_sales_entity.dart';

abstract class ReportsRepository {
  Future<SalesSummaryEntity> getDailySalesSummary(DateTime date);
  Future<SalesSummaryEntity> getSalesSummary({DateTime? start, DateTime? end});
  Future<List<ProductSalesEntity>> getProductWiseSales({DateTime? start, DateTime? end});
  Future<List<CategorySalesEntity>> getCategoryWiseSales({DateTime? start, DateTime? end});
  Future<List<ProductEntity>> getLowStockProducts(int threshold);
  Future<List<InvoiceEntity>> getTransactionHistory({DateTime? start, DateTime? end});
}
