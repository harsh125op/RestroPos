

class InvoiceEntity {
  final int? id;
  final DateTime date;
  final double totalAmount;
  final String? customerName;
  final List<InvoiceItemEntity> items;

  InvoiceEntity({
    this.id,
    required this.date,
    required this.totalAmount,
    this.customerName,
    required this.items,
  });
}

class InvoiceItemEntity {
  final int? id;
  final int? invoiceId;
  final int productId;
  final String productName; // For easier display
  final int quantity;
  final double priceAtBilling;

  InvoiceItemEntity({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtBilling,
  });
}
