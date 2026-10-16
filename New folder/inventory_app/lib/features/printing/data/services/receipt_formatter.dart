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
    String? customerName,
    required String cashierName,
    required List<ReceiptItem> items,
    required double grandTotal,
    double discount = 0.0,
    double serviceCharge = 0.0,
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
    if (customerName != null && customerName.trim().isNotEmpty) {
      buffer.writeln('Customer: $customerName');
    }
    buffer.writeln('Cashier: $cashierName');
    
    buffer.writeln('================================');

    // Table Header
    // 32 chars width for 58mm printer
    // ITEM (12) | PRICE (7) | QTY (5) | TOTAL (8)
    buffer.writeln('ITEM          PRICE  QTY   TOTAL');
    buffer.writeln('================================');

    // Items
    double itemsTotal = 0.0;
    for (final item in items) {
      itemsTotal += item.total;
      final String name = item.name;
      final String price = item.price.toStringAsFixed(2).padLeft(7);
      final String qty = item.quantity.toString().padLeft(5);
      final String total = item.total.toStringAsFixed(2).padLeft(8);

      if (name.length <= 12) {
        buffer.writeln('${name.padRight(12)}$price$qty$total');
      } else {
        final lines = _wrapText(name, 32);
        for (final line in lines) {
          buffer.writeln(line);
        }
        buffer.writeln('${"".padRight(12)}$price$qty$total');
      }
    }
    buffer.writeln('================================');

    // Service Charge
    if (serviceCharge > 0) {
      buffer.writeln('Service Charge:'.padRight(20) + serviceCharge.toStringAsFixed(2).padLeft(12));
      buffer.writeln('================================');
    }

    // Totals
    final double subTotal = itemsTotal + serviceCharge;
    final double computedGrandTotal = (subTotal - discount).clamp(0.0, double.infinity);

    buffer.writeln('Sub Total:'.padRight(20) + subTotal.toStringAsFixed(2).padLeft(12));
    if (discount > 0) {
      final discountStr = '-${discount.toStringAsFixed(2)}';
      buffer.writeln('Discount:'.padRight(20) + discountStr.padLeft(12));
    }
    buffer.writeln('GRAND TOTAL:'.padRight(20) + computedGrandTotal.toStringAsFixed(2).padLeft(12));
    buffer.writeln('================================');

    // Footer
    buffer.writeln('<100>Thank you for visiting!;');
    buffer.writeln('<100>Visit us again!;');
    buffer.writeln('----- GOOD FOOD, GOOD MOOD -----');
    
    return buffer.toString();
  }

  static List<String> _wrapText(String text, int width) {
    if (text.length <= width) return [text];
    final words = text.split(' ');
    final List<String> lines = [];
    String currentLine = '';

    for (final word in words) {
      if (word.length > width) {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = '';
        }
        for (int i = 0; i < word.length; i += width) {
          final end = (i + width < word.length) ? i + width : word.length;
          lines.add(word.substring(i, end));
        }
        continue;
      }

      if (currentLine.isEmpty) {
        currentLine = word;
      } else if (currentLine.length + 1 + word.length <= width) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }
}
