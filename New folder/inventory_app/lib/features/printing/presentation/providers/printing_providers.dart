import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/bluetooth_print_service.dart';
import '../../data/services/receipt_formatter.dart';

final bluetoothPrintServiceProvider = Provider((ref) => BluetoothPrintService());
final receiptFormatterProvider = Provider((ref) => ReceiptFormatter());
