import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_app/data/database/app_database.dart';
import 'package:inventory_app/features/reports/domain/entities/sales_summary_entity.dart';
import 'package:inventory_app/features/reports/domain/entities/product_sales_entity.dart';
import 'package:inventory_app/features/reports/domain/entities/category_sales_entity.dart';
import 'package:inventory_app/features/reports/domain/repositories/reports_repository.dart';
import 'package:inventory_app/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:inventory_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventory_app/features/billing/domain/entities/invoice_entity.dart';
import 'package:inventory_app/features/inventory/presentation/providers/inventory_providers.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(ref.watch(databaseProvider));
});

// Daily Sales Summary Provider
final dailySalesSummaryProvider = FutureProvider.family<SalesSummaryEntity, DateTime>((ref, date) {
  return ref.watch(reportsRepositoryProvider).getDailySalesSummary(date);
});

// Sales Summary Provider
final salesSummaryProvider = FutureProvider.family<SalesSummaryEntity, ({DateTime start, DateTime end})>((ref, range) {
  return ref.watch(reportsRepositoryProvider).getSalesSummary(start: range.start, end: range.end);
});

// Product Wise Sales Provider
final productWiseSalesProvider = FutureProvider.family<List<ProductSalesEntity>, ({DateTime start, DateTime end})>((ref, range) {
  return ref.watch(reportsRepositoryProvider).getProductWiseSales(start: range.start, end: range.end);
});

// Category Wise Sales Provider
final categoryWiseSalesProvider = FutureProvider.family<List<CategorySalesEntity>, ({DateTime start, DateTime end})>((ref, range) {
  return ref.watch(reportsRepositoryProvider).getCategoryWiseSales(start: range.start, end: range.end);
});

// Low Stock Provider
final lowStockProductsProvider = FutureProvider.family<List<ProductEntity>, int>((ref, threshold) {
  return ref.watch(reportsRepositoryProvider).getLowStockProducts(threshold);
});

// Transaction History Provider
final transactionHistoryProvider = FutureProvider.family<List<InvoiceEntity>, ({DateTime start, DateTime end})>((ref, range) {
  return ref.watch(reportsRepositoryProvider).getTransactionHistory(start: range.start, end: range.end);
});

// Date Range Provider for filtering
final reportsDateRangeProvider = StateProvider<({DateTime start, DateTime end})>((ref) {
  final now = DateTime.now();
  return (
    start: DateTime(now.year, now.month, now.day),
    end: DateTime(now.year, now.month, now.day),
  );
});
