import 'package:intl/intl.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../../settings/presentation/providers/store_details_provider.dart';

class InvoiceFormatter {
  static String formatForThermalPrinter(InvoiceEntity invoice, StoreDetails details) {
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
    buffer.writeln('Cashier: ${details.cashierName}');
    
    buffer.writeln('================================');

    // Table Header
    // 32 chars width
    // ITEM (12) | PRICE (7) | QTY (5) | TOTAL (8)
    // Total = 32
    buffer.writeln('ITEM        PRICE    QTY   TOTAL');
    buffer.writeln('================================');

    // Items
    for (final item in invoice.items) {
      String name = item.productName;
      if (name.length > 12) {
        name = name.substring(0, 9) + '...';
      } else {
        name = name.padRight(12);
      }
      
      final price = currencyFormat.format(item.priceAtBilling).padLeft(7);
      final qty = item.quantity.toString().padLeft(5);
      final total = currencyFormat.format(item.priceAtBilling * item.quantity).padLeft(8);

      buffer.writeln('$name$price$qty$total');
    }

    buffer.writeln('================================');
    
    // Totals
    final totalStr = currencyFormat.format(invoice.totalAmount);
    buffer.writeln('Sub Total:'.padRight(20) + totalStr.padLeft(12));
    buffer.writeln('GRAND TOTAL:'.padRight(20) + totalStr.padLeft(12));
    
    buffer.writeln('================================');
    buffer.writeln('    Thank you for visiting!    ');
    buffer.writeln('       Visit us again!         ');
    buffer.writeln('------- GOOD FOOD, GOOD MOOD -------');
    buffer.writeln('\n\n');

    return buffer.toString();
  }
}
