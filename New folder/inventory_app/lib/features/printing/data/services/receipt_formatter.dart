import 'package:intl/intl.dart';

class ReceiptItem {
  final String name;
  final int quantity;
  final double price;
  final double total;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });
}

class ReceiptFormatter {
  /// Generates receipt text with tags supported by the "Bluetooth Print" app.
  String generateReceipt({
    required String restaurantName,
    required String phoneNumber,
    required String address,
    required String invoiceNumber,
    required DateTime dateTime,
    required String cashierName,
    required List<ReceiptItem> items,
    required double grandTotal,
  }) {
    final StringBuffer buffer = StringBuffer();

    // Header
    // Using tags like <110> for bold/center as requested
    buffer.writeln('<110>${restaurantName.toUpperCase()};');
    buffer.writeln('<100>$address;');
    buffer.writeln('<100>Phone: $phoneNumber;');
    
    buffer.writeln('================================');
    
    // Invoice Info
    buffer.writeln('Bill No: #$invoiceNumber');
    buffer.writeln('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(dateTime)}');
    buffer.writeln('Cashier: $cashierName');
    
    buffer.writeln('================================');

    // Table Header
    // 32 chars width for 58mm printer
    // ITEM (12) | PRICE (6) | QTY (4) | TOTAL (10)
    buffer.writeln('ITEM        PRICE   QTY    TOTAL');
    buffer.writeln('================================');

    // Items
    for (final item in items) {
      String name = item.name;
      if (name.length > 12) {
        name = name.substring(0, 9) + '...';
      }
      final String price = item.price.toStringAsFixed(2);
      final String qty = item.quantity.toString();
      final String total = item.total.toStringAsFixed(2);
      
      buffer.writeln(
        name.padRight(12) +
        price.padLeft(6) +
        qty.padLeft(4) +
        total.padLeft(10)
      );
    }
    buffer.writeln('================================');

    // Totals
    buffer.writeln('Sub Total:'.padRight(22) + grandTotal.toStringAsFixed(2).padLeft(10));
    buffer.writeln('GRAND TOTAL:'.padRight(22) + grandTotal.toStringAsFixed(2).padLeft(10));
    buffer.writeln('================================');

    // Footer
    buffer.writeln('<100>Thank you for visiting!;');
    buffer.writeln('<100>Visit us again!;');
    
    return buffer.toString();
  }
}
