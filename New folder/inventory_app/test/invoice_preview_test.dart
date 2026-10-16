import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_app/features/billing/domain/entities/invoice_entity.dart';
import 'package:inventory_app/features/billing/presentation/screens/invoice_preview_screen.dart';

void main() {
  testWidgets('InvoicePreviewScreen builds and renders receipt cleanly', (tester) async {
    final invoice = InvoiceEntity(
      id: 12,
      date: DateTime.now(),
      totalAmount: 147.0,
      customerName: 'Admin',
      items: [
        InvoiceItemEntity(
          productId: 1,
          productName: 'Tea (Milk)',
          quantity: 3,
          priceAtBilling: 39.0,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InvoicePreviewScreen(
            invoice: invoice,
            discount: 20.0,
            serviceCharge: 50.0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bill Preview'), findsOneWidget);
    expect(find.text('Edit Order'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
    // Receipt text should be present in a Text widget
    expect(find.byType(Text), findsWidgets);
  });
}
