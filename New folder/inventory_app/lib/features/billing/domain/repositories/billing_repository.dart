import '../entities/invoice_entity.dart';

abstract class BillingRepository {
  Future<void> createInvoice(InvoiceEntity invoice);
  Future<List<InvoiceEntity>> getInvoices();
}
