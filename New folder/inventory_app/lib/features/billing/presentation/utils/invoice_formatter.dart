import 'package:intl/intl.dart';
import '../../domain/entities/invoice_entity.dart';

class InvoiceFormatter {
  static String formatForThermalPrinter(InvoiceEntity invoice) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

    // Header
    buffer.writeln('      TABLETAP RESTAURANT      ');
    buffer.writeln('    123 Food Street, City    ');
    buffer.writeln('      Phone: +91 9876543210    ');
    buffer.writeln('--------------------------------');
    buffer.writeln('Bill No: #${invoice.id ?? 'TEMP'}');
    buffer.writeln('Date: ${dateFormat.format(invoice.date)}');
    buffer.writeln('Cashier: Admin');
    if (invoice.customerName != null && invoice.customerName!.isNotEmpty) {
      buffer.writeln('Table/Cust: ${invoice.customerName}');
    }
    buffer.writeln('--------------------------------');

    // Table Header
    // 32 chars width (typical 58mm printer)
    // ITEM (14) | PRICE (6) | QTY (3) | TOTAL (7)
    buffer.writeln('ITEM          PRICE  QTY  TOTAL');
    buffer.writeln('--------------------------------');

    // Items
    for (final item in invoice.items) {
      final name = item.productName.length > 13 
          ? item.productName.substring(0, 11) + '..' 
          : item.productName.padRight(13);
      
      final price = currencyFormat.format(item.priceAtBilling).padLeft(6);
      final qty = item.quantity.toString().padLeft(3);
      final total = currencyFormat.format(item.priceAtBilling * item.quantity).padLeft(7);

      buffer.writeln('$name $price $qty $total');
    }

    buffer.writeln('--------------------------------');
    
    // Totals
    final subtotal = currencyFormat.format(invoice.totalAmount).padLeft(20);
    buffer.writeln('Sub Total:      $subtotal');
    
    final grandTotal = currencyFormat.format(invoice.totalAmount).padLeft(20);
    buffer.writeln('GRAND TOTAL:    $grandTotal');
    
    buffer.writeln('--------------------------------');
    buffer.writeln('    Thank you for visiting!    ');
    buffer.writeln('       Visit us again!         ');
    buffer.writeln('\n\n');

    return buffer.toString();
  }
}
