class SalesSummaryEntity {
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;

  SalesSummaryEntity({
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
  });

  factory SalesSummaryEntity.empty() {
    return SalesSummaryEntity(
      totalSales: 0.0,
      totalOrders: 0,
      averageOrderValue: 0.0,
    );
  }
}
