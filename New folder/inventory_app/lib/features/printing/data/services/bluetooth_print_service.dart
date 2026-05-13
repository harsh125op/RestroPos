import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import '../../../../core/utils/logger.dart';

class BluetoothPrintService {
  /// Gets list of paired devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      AppLogger.e("Failed to get paired devices", e);
      return [];
    }
  }

  /// Connects to a device using MAC address
  Future<bool> connect(String macAddress) async {
    try {
      return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    } catch (e) {
      AppLogger.e("Failed to connect to device", e);
      return false;
    }
  }

  /// Disconnects from device
  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
  }

  /// Checks if connected
  Future<bool> isConnected() async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  /// Prints receipt with logo and text
  Future<bool> printReceipt(String text, [String? logoPath]) async {
    try {
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (!isConnected) {
        AppLogger.e("Printer not connected");
        return false;
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      if (logoPath != null) {
        try {
          // Load asset
          final ByteData data = await rootBundle.load(logoPath);
          final Uint8List imgBytes = data.buffer.asUint8List();
          
          // Decode image
          final img.Image? image = img.decodeImage(imgBytes);
          
          if (image != null) {
            // Resize image to fit 58mm printer
            final img.Image resized = img.copyResize(image, width: 150);
            
            // Generate image bytes
            bytes += generator.image(resized);
          }
        } catch (e) {
          AppLogger.e("Failed to generate logo bytes", e);
        }
      }

      // Print text line by line using generator
      final lines = text.split('\n');
      for (final line in lines) {
        bytes += generator.text(line);
      }
      
      // Feed paper at the end (removed to avoid extra space)

      // Send all bytes at once
      final success = await PrintBluetoothThermal.writeBytes(bytes);

      return success;
    } catch (e) {
      AppLogger.e("Failed to print receipt", e);
      return false;
    }
  }
}
