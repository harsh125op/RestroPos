import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';

class BluetoothPrintService {
  /// Sends receipt text to the "Bluetooth Print" app via Android Intent.
  /// Returns true if successful, false if the app is not installed or failure.
  Future<bool> printReceipt(String receiptText) async {
    try {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.SEND',
        type: 'text/plain',
        package: 'mate.bluetoothprint',
        arguments: {
          'android.intent.extra.TEXT': receiptText,
        },
      );
      await intent.launch();
      return true;
    } on PlatformException catch (e) {
      // ActivityNotFoundException usually translates to PlatformException
      print("Failed to launch Bluetooth Print app: $e");
      return false;
    } catch (e) {
      print("Error launching intent: $e");
      return false;
    }
  }

  /// Opens the Play Store page for the "Bluetooth Print" app.
  Future<void> openPlayStore() async {
    final AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: 'market://details?id=mate.bluetoothprint',
    );
    await intent.launch();
  }
}
