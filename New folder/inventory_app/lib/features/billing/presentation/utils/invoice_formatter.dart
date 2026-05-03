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
    if (details.gstin != 'NOTSET') {
      buffer.writeln('GSTIN: ${details.gstin}'.padLeft((32 + 7 + details.gstin.length) ~/ 2).padRight(32));
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Bill No: #${invoice.id ?? 'TEMP'}');
    buffer.writeln('Date: ${dateFormat.format(invoice.date)}');
    buffer.writeln('Cashier: ${details.cashierName}');
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
