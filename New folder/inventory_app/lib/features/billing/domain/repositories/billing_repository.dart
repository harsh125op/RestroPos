import '../entities/invoice_entity.dart';

abstract class BillingRepository {
  Future<int> createInvoice(InvoiceEntity invoice);
  Future<List<InvoiceEntity>> getInvoices();
}
