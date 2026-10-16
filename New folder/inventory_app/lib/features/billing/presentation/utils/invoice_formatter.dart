import 'package:intl/intl.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../../settings/presentation/providers/store_details_provider.dart';

class InvoiceFormatter {
  static String formatForThermalPrinter(
    InvoiceEntity invoice,
    StoreDetails details, {
    double discount = 0.0,
    double serviceCharge = 0.0,
  }) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

    // Header
    buffer.writeln(details.restaurantName.toUpperCase().padLeft((32 + details.restaurantName.length) ~/ 2).padRight(32));
    buffer.writeln(details.address.padLeft((32 + details.address.length) ~/ 2).padRight(32));
    buffer.writeln('Phone: ${details.phone}'.padLeft((32 + 7 + details.phone.length) ~/ 2).padRight(32));
    
    buffer.writeln('================================'); // 32 chars
    
    // Bill Details
    buffer.writeln('Bill No: #${invoice.id ?? 'TEMP'}');
    buffer.writeln('Date: ${dateFormat.format(invoice.date)}');
    if (invoice.customerName != null && invoice.customerName!.trim().isNotEmpty) {
      buffer.writeln('Customer: ${invoice.customerName}');
    }
    buffer.writeln('Cashier: ${details.cashierName}');
    
    buffer.writeln('================================');

    // Table Header
    // 32 chars width: ITEM (12) | PRICE (7) | QTY (5) | TOTAL (8)
    buffer.writeln('ITEM          PRICE  QTY   TOTAL');
    buffer.writeln('================================');

    // Items
    double itemsTotal = 0.0;
    for (final item in invoice.items) {
      itemsTotal += item.priceAtBilling * item.quantity;
      final String name = item.productName;
      final price = currencyFormat.format(item.priceAtBilling).padLeft(7);
      final qty = item.quantity.toString().padLeft(5);
      final total = currencyFormat.format(item.priceAtBilling * item.quantity).padLeft(8);

      if (name.length <= 12) {
        buffer.writeln('${name.padRight(12)}$price$qty$total');
      } else {
        // Print full product name on its line(s), then price/qty/total on next line aligned
        final lines = _wrapText(name, 32);
        for (final line in lines) {
          buffer.writeln(line);
        }
        buffer.writeln('${"".padRight(12)}$price$qty$total');
      }
    }

    buffer.writeln('================================');

    // Service Charge (displayed after item list)
    if (serviceCharge > 0) {
      buffer.writeln('Service Charge:'.padRight(20) + currencyFormat.format(serviceCharge).padLeft(12));
      buffer.writeln('================================');
    }
    
    // Totals
    final double subTotal = itemsTotal + serviceCharge;
    final double grandTotal = (subTotal - discount).clamp(0.0, double.infinity);

    buffer.writeln('Sub Total:'.padRight(20) + currencyFormat.format(subTotal).padLeft(12));
    if (discount > 0) {
      final discountStr = '-${currencyFormat.format(discount)}';
      buffer.writeln('Discount:'.padRight(20) + discountStr.padLeft(12));
    }
    buffer.writeln('GRAND TOTAL:'.padRight(20) + currencyFormat.format(grandTotal).padLeft(12));
    
    buffer.writeln('================================');
    const thankYou = 'Thank you for visiting!';
    buffer.writeln(thankYou.padLeft((32 + thankYou.length) ~/ 2).padRight(32));
    const visitAgain = 'Visit us again!';
    buffer.writeln(visitAgain.padLeft((32 + visitAgain.length) ~/ 2).padRight(32));
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
