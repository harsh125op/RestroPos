import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:inventory_app/features/reports/domain/entities/product_sales_entity.dart';
import 'package:inventory_app/features/billing/domain/entities/invoice_entity.dart';

class ExportService {
  static Future<void> exportToCSV({
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/$fileName.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(path)], text: 'Exporting $fileName');
  }

  static Future<void> exportTransactionHistoryToPDF(List<InvoiceEntity> invoices) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("Transaction History Report")),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Bill #', 'Date', 'Customer', 'Total'],
            data: invoices.map((inv) => [
              inv.id.toString(),
              dateFormat.format(inv.date),
              inv.customerName ?? 'Walk-in',
              inv.totalAmount.toStringAsFixed(2),
            ]).toList(),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/transaction_history_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(path)], text: 'Exporting Transaction History');
  }

  static Future<void> exportProductSalesReportToPDF(List<ProductSalesEntity> sales) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("Product-wise Sales Report")),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Product Name', 'Qty Sold', 'Revenue'],
            data: sales.map((s) => [
              s.productName,
              s.quantitySold.toString(),
              s.revenue.toStringAsFixed(2),
            ]).toList(),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/product_sales_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(path)], text: 'Exporting Product Sales');
  }
}
